#!/usr/bin/env python3
"""Preview renderer for the generated hub, for checking builds without Roblox Studio.

    tests/hub/run.sh <luau> --dump > parts.txt
    python3 tests/hub/render.py parts.txt out.png --eye 0,60,260 --at 0,30,0 [--night]

It reads the PART| lines from tests/hub/dump.luau and draws every block, cylinder, ball and
wedge with a z-buffer, flat sun shading and fog. It is a rough preview of shapes, scale and
colour, not a match for Roblox lighting or materials.
"""
import argparse
import math

import numpy as np
from PIL import Image


def parse(path):
    parts = []
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            if not line.startswith("PART|"):
                continue
            f = line.rstrip("\n").split("|")
            nums = list(map(float, f[2:21]))
            parts.append({
                "name": f[1],
                "size": np.array(nums[0:3]),
                "pos": np.array(nums[3:6]),
                "rot": np.array(nums[6:15]).reshape(3, 3),
                "color": np.array(nums[15:18]),
                "alpha": 1.0 - nums[18],
                "shape": f[21],
                "glow": f[22] == "1",
            })
    return parts


def unit_faces(shape):
    """Polygons in unit local space (-0.5..0.5) for each Roblox part shape."""
    if shape == "Cylinder":  # axis along local X
        n = 16
        ring = [(math.cos(2 * math.pi * i / n) * 0.5, math.sin(2 * math.pi * i / n) * 0.5) for i in range(n)]
        faces = [[(-0.5, y, z) for (y, z) in reversed(ring)], [(0.5, y, z) for (y, z) in ring]]
        for i in range(n):
            (y0, z0), (y1, z1) = ring[i], ring[(i + 1) % n]
            faces.append([(-0.5, y0, z0), (0.5, y0, z0), (0.5, y1, z1), (-0.5, y1, z1)][::-1])
        return faces
    if shape == "Ball":
        faces = []
        lat, lon = 8, 14
        for i in range(lat):
            a0, a1 = math.pi * i / lat - math.pi / 2, math.pi * (i + 1) / lat - math.pi / 2
            for j in range(lon):
                b0, b1 = 2 * math.pi * j / lon, 2 * math.pi * (j + 1) / lon
                def p(a, b):
                    return (math.cos(a) * math.cos(b) * 0.5, math.sin(a) * 0.5, math.cos(a) * math.sin(b) * 0.5)
                faces.append([p(a0, b0), p(a1, b0), p(a1, b1), p(a0, b1)])
        return faces
    if shape == "Wedge":
        # Roblox wedge: full bottom and back (+Z), slope from top-back to bottom-front.
        A, B = (-0.5, -0.5, -0.5), (0.5, -0.5, -0.5)
        C, D = (0.5, -0.5, 0.5), (-0.5, -0.5, 0.5)
        E, F = (0.5, 0.5, 0.5), (-0.5, 0.5, 0.5)
        return [[A, B, C, D][::-1], [D, C, E, F][::-1], [A, F, E, B][::-1], [A, D, F], [B, E, C]]
    v = [(x, y, z) for x in (-0.5, 0.5) for y in (-0.5, 0.5) for z in (-0.5, 0.5)]
    idx = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    return [[v[i] for i in face] for face in idx]


FACE_CACHE = {}


def faces_for(part):
    shape = part["shape"]
    if shape not in FACE_CACHE:
        FACE_CACHE[shape] = [np.array(face) for face in unit_faces(shape)]
    size = part["size"].copy()
    if shape == "Ball":
        size[:] = size.min()
    if shape == "Cylinder":
        size[1] = size[2] = min(size[1], size[2])
    for face in FACE_CACHE[shape]:
        yield (face * size) @ part["rot"].T + part["pos"]


def render(parts, eye, at, width, height, fov, night, out):
    eye, at = np.array(eye, float), np.array(at, float)
    forward = at - eye
    forward /= np.linalg.norm(forward)
    right = np.cross(forward, [0, 1, 0])
    right /= np.linalg.norm(right)
    up = np.cross(right, forward)
    focal = (height / 2) / math.tan(math.radians(fov) / 2)
    near = 0.5

    sky_top = np.array([0.05, 0.07, 0.16] if night else [0.45, 0.62, 0.86])
    sky_low = np.array([0.16, 0.18, 0.3] if night else [0.86, 0.84, 0.78])
    rows = np.linspace(0, 1, height)[:, None, None]
    image = sky_top * (1 - rows) + sky_low * rows
    image = np.repeat(image, width, axis=1)
    zbuf = np.full((height, width), np.inf)
    ids = np.full((height, width), -1)
    sun = np.array([0.35, 0.8, 0.45])
    sun /= np.linalg.norm(sun)
    fog_color = sky_low
    fog_far = 2600.0 if night else 4200.0

    def to_view(points):
        rel = points - eye
        return np.stack([rel @ right, rel @ up, rel @ forward], axis=1)

    def clip(poly):
        out_poly = []
        for i in range(len(poly)):
            a, b = poly[i], poly[(i + 1) % len(poly)]
            ina, inb = a[2] >= near, b[2] >= near
            if ina:
                out_poly.append(a)
            if ina != inb:
                t = (near - a[2]) / (b[2] - a[2])
                out_poly.append(a + (b - a) * t)
        return out_poly

    transparent = []

    def draw(poly_view, color, alpha, pid=-1):
        pts = clip(list(poly_view))
        if len(pts) < 3:
            return
        pts = np.array(pts)
        sx = width / 2 + focal * pts[:, 0] / pts[:, 2]
        sy = height / 2 - focal * pts[:, 1] / pts[:, 2]
        invz = 1.0 / pts[:, 2]
        for k in range(1, len(pts) - 1):
            tri = [0, k, k + 1]
            x, y, iz = sx[tri], sy[tri], invz[tri]
            x0, x1 = max(int(math.floor(x.min())), 0), min(int(math.ceil(x.max())), width - 1)
            y0, y1 = max(int(math.floor(y.min())), 0), min(int(math.ceil(y.max())), height - 1)
            if x0 > x1 or y0 > y1:
                continue
            area = (x[1] - x[0]) * (y[2] - y[0]) - (x[2] - x[0]) * (y[1] - y[0])
            if abs(area) < 1e-9:
                continue
            gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
            w0 = ((x[1] - gx) * (y[2] - gy) - (x[2] - gx) * (y[1] - gy)) / area
            w1 = ((x[2] - gx) * (y[0] - gy) - (x[0] - gx) * (y[2] - gy)) / area
            w2 = 1 - w0 - w1
            inside = (w0 >= -1e-6) & (w1 >= -1e-6) & (w2 >= -1e-6)
            if not inside.any():
                continue
            depth = 1.0 / (w0 * iz[0] + w1 * iz[1] + w2 * iz[2])
            region = zbuf[y0:y1 + 1, x0:x1 + 1]
            mask = inside & (depth < region)
            if not mask.any():
                continue
            fog = np.clip(depth / fog_far, 0, 1)[..., None] ** 1.3
            shaded = color[None, None, :] * (1 - fog) + fog_color[None, None, :] * fog
            target = image[y0:y1 + 1, x0:x1 + 1]
            if alpha >= 0.999:
                target[mask] = shaded[mask]
                region[mask] = depth[mask]
                ids[y0:y1 + 1, x0:x1 + 1][mask] = pid
            else:
                target[mask] = target[mask] * (1 - alpha) + shaded[mask] * alpha

    for pid, part in enumerate(parts):
        if part["alpha"] < 0.02:
            continue
        for face in faces_for(part):
            normal = np.cross(face[1] - face[0], face[2] - face[0])
            norm = np.linalg.norm(normal)
            if norm < 1e-9:
                continue
            normal /= norm
            if np.dot(normal, face[0] - eye) >= 0:
                continue  # back face
            base = part["color"]
            if part["glow"]:
                lit = np.clip(base * 1.25 + 0.15, 0, 1)
            elif night:
                lit = base * (0.32 + 0.18 * max(np.dot(normal, sun), 0)) + np.array([0.02, 0.025, 0.05])
            else:
                lit = base * (0.5 + 0.55 * max(np.dot(normal, sun), 0))
            lit = np.clip(lit, 0, 1)
            view = to_view(face)
            if part["alpha"] < 0.999:
                transparent.append((view, lit, part["alpha"]))
            else:
                draw(view, lit, 1.0, pid)

    transparent.sort(key=lambda item: -item[0][:, 2].mean())
    for view, lit, alpha in transparent:
        draw(view, lit, alpha)

    Image.fromarray((np.clip(image, 0, 1) * 255).astype(np.uint8)).save(out)
    return ids


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("parts")
    parser.add_argument("out")
    parser.add_argument("--eye", default="0,80,330")
    parser.add_argument("--at", default="0,30,0")
    parser.add_argument("--size", default="1280x720")
    parser.add_argument("--fov", type=float, default=70)
    parser.add_argument("--night", action="store_true")
    parser.add_argument("--pick", default="", help="x,y;x,y pixels to name the visible part at")
    parser.add_argument("--radius", type=float, default=0, help="only draw parts within this distance of --at")
    args = parser.parse_args()
    parts = parse(args.parts)
    at = list(map(float, args.at.split(",")))
    if args.radius > 0:
        parts = [p for p in parts if np.linalg.norm(p["pos"] - at) - p["size"].max() / 2 < args.radius]
    width, height = map(int, args.size.split("x"))
    ids = render(parts, list(map(float, args.eye.split(","))), at, width, height, args.fov, args.night, args.out)
    for pick in filter(None, args.pick.split(";")):
        x, y = map(int, pick.split(","))
        pid = ids[y, x]
        print(pick, parts[pid]["name"] if pid >= 0 else "sky", parts[pid]["pos"] if pid >= 0 else "")


if __name__ == "__main__":
    main()
