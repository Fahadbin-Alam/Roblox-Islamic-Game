#!/usr/bin/env python3
"""Preview renderer for the generated hub, for checking builds without Roblox Studio.

    tests/hub/run.sh <luau> --dump > parts.txt
    python3 tests/hub/render.py parts.txt out.png --eye 0,60,260 --at 0,30,0 [--night]

It reads the PART| lines from tests/hub/dump.luau and draws every block, cylinder, ball and
wedge with a z-buffer, sun shading with cast shadows, simple procedural material patterns
(brick courses, planks, sand grain, stone) and fog. It is a preview of shapes, scale and colour;
Roblox's own lighting, real material textures, SurfaceGui text and avatars are not drawn.
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
                "material": f[23] if len(f) > 23 else "Plastic",
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


MATERIAL_KIND = {
    "Brick": "brick", "Sandstone": "brick", "Limestone": "block", "Cobblestone": "block",
    "Pavement": "block", "Marble": "marble", "Granite": "stone", "Slate": "stone", "Rock": "stone",
    "Basalt": "stone", "Concrete": "grain", "Sand": "grain", "Ground": "grain", "Mud": "grain",
    "Fabric": "cloth", "Wood": "wood", "WoodPlanks": "planks", "Grass": "leaf", "LeafyGrass": "leaf",
    "Metal": "metal", "DiamondPlate": "metal", "CorrodedMetal": "metal",
}


def hash3(ix, iy, iz):
    h = (ix * 73856093) ^ (iy * 19349663) ^ (iz * 83492791)
    h = (h ^ (h >> 13)) * 1274126177
    return ((h ^ (h >> 16)) & 0xFFFF) / 65535.0


def material_shade(kind, pos, normal):
    """Brightness multipliers (n,) for world positions (n,3) of one material kind."""
    x, y, z = pos[:, 0], pos[:, 1], pos[:, 2]
    horizontal = np.abs(normal[:, 1]) > 0.7
    along = np.where(np.abs(normal[:, 0]) > np.abs(normal[:, 2]), z, x)
    ones = np.ones(len(pos))

    def noise(scale):
        ix = np.floor(x * scale).astype(np.int64)
        iy = np.floor(y * scale).astype(np.int64)
        iz = np.floor(z * scale).astype(np.int64)
        h = (ix * 73856093) ^ (iy * 19349663) ^ (iz * 83492791)
        h = (h ^ (h >> 13)) * 1274126177
        return ((h ^ (h >> 16)) & 0xFFFF) / 65535.0

    if kind == "brick":
        row = np.floor(y / 1.1)
        offset = (row % 2) * 1.1
        mortar_y = (y % 1.1) < 0.12
        mortar_x = ((along + offset) % 2.2) < 0.12
        m = np.where(horizontal, ones * (0.95 + 0.08 * noise(0.5)), np.where(mortar_y | mortar_x, 0.8, 0.94 + 0.1 * noise(0.45)))
        return m
    if kind == "block":
        row = np.floor(y / 2.0)
        offset = (row % 2) * 2.0
        joint = ((y % 2.0) < 0.1) | (((along + offset) % 4.0) < 0.1)
        return np.where(horizontal, 0.95 + 0.08 * noise(0.25), np.where(joint, 0.85, 0.95 + 0.07 * noise(0.5)))
    if kind == "planks":
        coord = np.where(horizontal, x, y)
        return np.where((coord % 1.0) < 0.08, 0.78, 0.92 + 0.12 * noise(0.7))
    if kind == "wood":
        return 0.9 + 0.12 * noise(1.5)
    if kind == "grain":
        return 0.93 + 0.09 * noise(1.3) + 0.04 * noise(0.11)
    if kind == "stone":
        return 0.82 + 0.16 * noise(0.35) + 0.06 * noise(1.6)
    if kind == "marble":
        return 0.96 + 0.05 * noise(0.2) + 0.03 * noise(1.0)
    if kind == "cloth":
        return 0.93 + 0.07 * noise(2.5)
    if kind == "leaf":
        return 0.82 + 0.25 * noise(1.1)
    if kind == "metal":
        return 0.95 + 0.06 * noise(0.8)
    return ones


def raster(poly2, depth_vals, width, height, callback):
    """Rasterizes a convex polygon given in pixel space; calls callback(y0, x0, mask, depth, w)."""
    for k in range(1, len(poly2) - 1):
        tri = [0, k, k + 1]
        x, y = poly2[tri, 0], poly2[tri, 1]
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
        d = depth_vals[tri]
        callback(y0, x0, inside, w0 * d[0] + w1 * d[1] + w2 * d[2])


def render(parts, eye, at, width, height, fov, night, out):
    eye, at = np.array(eye, float), np.array(at, float)
    forward = at - eye
    forward /= np.linalg.norm(forward)
    right = np.cross(forward, [0, 1, 0])
    right /= np.linalg.norm(right)
    up = np.cross(right, forward)
    focal = (height / 2) / math.tan(math.radians(fov) / 2)
    near = 0.5

    sky_top = np.array([0.05, 0.07, 0.16] if night else [0.38, 0.58, 0.86])
    sky_low = np.array([0.16, 0.18, 0.3] if night else [0.86, 0.85, 0.8])
    rows = np.linspace(0, 1, height)[:, None, None]
    image = sky_top * (1 - rows) + sky_low * rows
    image = np.repeat(image, width, axis=1)
    zbuf = np.full((height, width), np.inf)
    ids = np.full((height, width), -1)
    base_buf = np.zeros((height, width, 3))
    normal_buf = np.zeros((height, width, 3))
    flags = np.zeros((height, width), dtype=np.int16)  # material kind index; -1 glow
    kinds = ["plain"] + sorted(set(MATERIAL_KIND.values()))
    kind_index = {k: i for i, k in enumerate(kinds)}
    sun = np.array([0.42, 0.78, 0.46])
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

    def project(poly_view):
        pts = clip(list(poly_view))
        if len(pts) < 3:
            return None, None
        pts = np.array(pts)
        sx = width / 2 + focal * pts[:, 0] / pts[:, 2]
        sy = height / 2 - focal * pts[:, 1] / pts[:, 2]
        return np.stack([sx, sy], axis=1), 1.0 / pts[:, 2]

    opaque_faces = []
    transparent = []

    for pid, part in enumerate(parts):
        if part["alpha"] < 0.02:
            continue
        kind = -1 if part["glow"] else kind_index[MATERIAL_KIND.get(part["material"], "plain")]
        for face in faces_for(part):
            normal = np.cross(face[1] - face[0], face[2] - face[0])
            norm = np.linalg.norm(normal)
            if norm < 1e-9:
                continue
            normal /= norm
            if part["alpha"] >= 0.999:
                opaque_faces.append(face)
            if np.dot(normal, face[0] - eye) >= 0:
                continue  # back face
            if part["alpha"] < 0.999:
                transparent.append((face, normal, part["color"], part["alpha"]))
                continue
            poly2, invz = project(to_view(face))
            if poly2 is None:
                continue

            def write(y0, x0, inside, iz, pid=pid, normal=normal, color=part["color"], kind=kind):
                depth = 1.0 / iz
                h, w = inside.shape
                region = zbuf[y0:y0 + h, x0:x0 + w]
                mask = inside & (depth < region)
                if not mask.any():
                    return
                region[mask] = depth[mask]
                ids[y0:y0 + h, x0:x0 + w][mask] = pid
                base_buf[y0:y0 + h, x0:x0 + w][mask] = color
                normal_buf[y0:y0 + h, x0:x0 + w][mask] = normal
                flags[y0:y0 + h, x0:x0 + w][mask] = kind

            raster(poly2, invz, width, height, write)

    hit = np.isfinite(zbuf)
    py, px = np.nonzero(hit)
    z = zbuf[py, px]
    vx = (px + 0.5 - width / 2) * z / focal
    vy = -(py + 0.5 - height / 2) * z / focal
    world = eye + np.outer(vx, right) + np.outer(vy, up) + np.outer(z, forward)
    normals = normal_buf[py, px]
    base = base_buf[py, px]
    kind_of = flags[py, px]

    # Shadow map: orthographic depth along the sun direction, covering the visible pixels.
    lr = np.cross(sun, [0, 0, 1.0])
    lr /= np.linalg.norm(lr)
    lu = np.cross(lr, sun)
    shadow = np.ones(len(world))
    if len(world) and not night:
        su, sv = world @ lr, world @ lu
        margin = 40.0
        u0, u1, v0, v1 = su.min() - margin, su.max() + margin, sv.min() - margin, sv.max() + margin
        res = 2048
        scale = res / max(u1 - u0, v1 - v0, 1.0)
        smap = np.full((res, res), -np.inf)
        for face in opaque_faces:
            fu, fv = (face @ lr - u0) * scale, (face @ lu - v0) * scale
            if fu.max() < 0 or fv.max() < 0 or fu.min() >= res or fv.min() >= res:
                continue
            fd = face @ sun

            def write_shadow(y0, x0, inside, d):
                h, w = inside.shape
                region = smap[y0:y0 + h, x0:x0 + w]
                mask = inside & (d > region)
                region[mask] = d[mask]

            raster(np.stack([fu, fv], axis=1), fd, res, res, write_shadow)
        iu = np.clip(((su - u0) * scale).astype(int), 0, res - 1)
        iv = np.clip(((sv - v0) * scale).astype(int), 0, res - 1)
        bias = 0.35 + 1.2 / scale
        lit_depth = world @ sun
        shadow = np.where(lit_depth < smap[iv, iu] - bias, 0.0, 1.0)

    ndl = np.clip(normals @ sun, 0, 1)
    sky = 0.5 + 0.5 * np.clip(normals[:, 1], -1, 1)
    if night:
        light = 0.3 + 0.15 * ndl
        tint = np.array([0.02, 0.025, 0.05])
    else:
        light = 0.34 + 0.2 * sky + 0.62 * ndl * shadow
        tint = np.zeros(3)
    pattern = np.ones(len(world))
    for name, index in kind_index.items():
        sel = kind_of == index
        if sel.any() and name != "plain":
            pattern[sel] = material_shade(name, world[sel], normals[sel])
    color = base * (light * pattern)[:, None] + tint
    glow = kind_of == -1
    color[glow] = np.clip(base[glow] * 1.25 + 0.15, 0, 1)
    fog = (np.clip(z / fog_far, 0, 1) ** 1.3)[:, None]
    color = np.clip(color, 0, 1) * (1 - fog) + fog_color * fog
    image[py, px] = color

    transparent.sort(key=lambda item: -np.linalg.norm(item[0].mean(axis=0) - eye))
    for face, normal, base_color, alpha in transparent:
        poly2, invz = project(to_view(face))
        if poly2 is None:
            continue
        lit = np.clip(base_color * (0.55 + 0.5 * max(np.dot(normal, sun), 0)), 0, 1)

        def blend(y0, x0, inside, iz, lit=lit, alpha=alpha):
            depth = 1.0 / iz
            h, w = inside.shape
            mask = inside & (depth < zbuf[y0:y0 + h, x0:x0 + w])
            target = image[y0:y0 + h, x0:x0 + w]
            target[mask] = target[mask] * (1 - alpha) + lit * alpha

        raster(poly2, invz, width, height, blend)

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
