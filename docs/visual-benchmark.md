# Visual benchmark: other Islamic Roblox games compared with ours

Date: 2026-11-11. Written after the feedback "that looks bad, compare it to other Roblox Muslim games".

## What the other games are

| Game | What it is | Numbers (where shown) |
|---|---|---|
| [Big Ummah Mosque](https://www.roblox.com/games/128916320779381/Big-Ummah-Mosque) | A social hangout: a large mosque to walk around, pray and explore. Tags: Prayer, Salah, Quran, Mecca, Medina, Hajj, Umrah. No quests or game modes listed. | About 8.7M visits, 716K favourites, about 400 playing at the time checked, peak 5K ([RoWatcher](https://rowatcher.com/games/9856135084/big-ummah-mosque), third-party estimate) |
| [islamic makkah mecca kaaba mosque](https://www.roblox.com/games/7186809797/islamic-makkah-mecca-kaaba-mosque) | A Kaaba and mosque map. The description is a list of keywords, with no gameplay described. | Not shown |
| [Masjid Al-Husain](https://www.roblox.com/games/100737279792723) | A small-town roleplay hangout around a mosque. | Not shown |
| [islamic praying simulator](https://www.roblox.com/games/16752020812) | Spawn in a bedroom, walk to a Kaaba, pick up cash and buy items. The developer says it is unfinished. | Not shown |
| [Hajj in mecca eid masjid pray simulator](https://medal.tv/games/roblox/experiences/10OLwYs0FUk9/islamic-hajj-in-mecca-eid-masjid-pray-simulator) | A Hajj-themed map with outfits. | Not shown |
| [Arab Prayer](https://www.roblox.com/games/18814106235/prayer-islam-2025) | A prayer map with keywords and a group link. | Not shown |

Ramadan 2026 also brought group lectures (kajian) held in Roblox over voice chat, with avatars seated in rows ([Good News From Indonesia](https://www.goodnewsfromindonesia.id/2026/02/27/tren-kajian-di-roblox-bagaimana-makna-spiritualitasnya)).

## Honest comparison

- **Gameplay:** ours does much more. None of the games above lists battles, a story campaign, puzzles, PvP, parkour or co-op. The most popular one, Big Ummah Mosque, is a calm place to hang out and pray.
- **Visuals:** this is where we were behind. The successful games are built around one big, detailed, recognisable mosque that looks good from the moment you arrive. Our hub's Masjid al-Haram already has that kind of detail (5,300 parts). But the other places were plain boxes: present-day Madinah was one white slab, the historical towns had a few scattered huts, the PvP ring was a disc on bare ground, and the activity zones were bare walls.
- **What we could not check:** we could not open the other games, so their visuals are judged from their store pages and descriptions only. The top one probably uses meshes and imported models. Ours is built from parts in code, which keeps it testable but limits how smooth the shapes can be.

## What changed in this pass

The before and after previews are in `game-previews/v2/before-after.png` in the project files.

| Area | Before | After |
|---|---|---|
| Present-day Madinah | Solid white block. The Rawdah and the visitation route were sealed inside it, and arriving players were dropped inside the solid portico. | A prayer hall you can walk into: arched facades with doors on every side, red carpets, rows of columns, mihrab and minbar, the green Rawdah carpet and the chamber marker. Outside: a roof of small domes, the Green Dome, 6 minarets and 72 piazza umbrellas. |
| Historical Makkah | About 30 huts | 196 mud-brick houses in packed blocks along streets, with parapets, roof beams, wooden bay windows, awnings and jars. Ridge mountains ring the valley. Added: the Hijr wall, the raised Kaaba door and the Zamzam well. |
| Historical Madinah | Sparse huts and a few palms | 74 houses and about 60 palm groves on green watered ground (the oasis), plus a market with stalls and camels, camps with goat-hair tents, wells and banners. |
| PvP training grounds | A disc with 16 posts | A walled arena: roped ring (the ropes do not block ring-outs), stepped stands with cushions and shade sails, braziers, corner towers, arched gates and palms. |
| Mystery rooms | Plain boxes | Stone house fronts with arched doors and lamps. Inside: beams, shelves, niches and cushions, all kept clear of the clues. The lobby has a palm and lamp colonnade, wells and camels. |
| Co-op course | Bare walls floating in the air | Desert ground around it, buttresses, battlements, wall lamps, banners and braziers |
| Parkour tower | A plain pillar | Stone bands, arched windows, summit finials, palm planters and a mosaic ring. None of it collides, so the jumps the unit tests measured are unchanged. |

## Second pass

| Area | Before | After |
|---|---|---|
| Historical early mosque (Madinah) | Mud walls, one flat green roof strip | Stone footing under the walls, doors on three sides with palm-trunk frames, three rows of ringed palm-trunk pillars, an uneven frond roof with mats beneath, pebbles in the courtyard, the household chambers along the east wall, and bricks and spare trunks from the building work |
| Night | Only Masjid al-Haram had lights. Present-day Madinah, the courts, the battle gates, the Seerah towns and the mystery wing were dark. | Brass chandeliers in the Madinah hall, lamps under the piazza umbrellas and on the walkway, lantern posts at every arrival point, a pair of fire bowls at every Seerah site, and lanterns at street crossings in the historical towns |
| Hub palms | Straight sticks with a few leaves | Curved trunks with seven fronds |

The preview renderer now draws point lights at night, so the night previews show what is lit and what is not (`game-previews/v2/night-before-after.png`).

New tests found and fixed real bugs during this pass:

- **Seerah items you could not reach.** Nine chapter items and arrival rings sat inside walls, hills or vine rows: Shi'b Abi Talib, Ta'if, Safa, al-Aqabah, Jabal Thawr and the House of Fatimah. A new zone check now confirms every arrival point, travel point and item is clear.
- **Tent build would fail.** A tent cushion was built with no colour. On a real server that raises an error and stops the site from building. A new check now confirms every part has a colour.
- **Players arriving in the dark.** A new check found that 11 of the 15 travel destinations had no light within 70 studs, and most Seerah sites had none within 30. All are now lit, and both checks run in CI.
- **Battle gates buried in rock.** A new check found that the Badr and Uhud gates and the Journey road sat inside the hub's decorative rock ridges, which do not collide, so players walked through them and saw only rock. Those ridges are removed or moved, and the gates are dressed with battlements, banners, fire bowls and palms.
- **Hub scenery inside the battlefields.** The Uhud gate, a hotel tower and the Haram deck edge stood inside the Badr arena, and a backdrop mountain inside Uhud. The Uhud gate moved south of the Badr gate and a check now keeps the arenas clear.
- **Present-day Madinah arrival and route.** Arriving players landed inside the solid portico, and the visitation route was blocked. New checks: every travel destination lands in open space, players can walk from the Madinah arrival into the hall, and the route from Bab as-Salam is open.

## Cost

| Zone | Parts |
|---|---|
| Hub, including Masjid al-Haram and present-day Madinah | 8,905 (budget 9,000) |
| Historical Makkah and Madinah | 14,633 (budget 15,000) |
| Mystery wing | 2,113 (budget 2,500) |
| Training grounds | 526 (budget 1,000) |
| Co-op trials | 256 (budget 400) |

The whole place is now about 26,000 parts, most of them anchored, and the decoration does not collide. The zones are about 4,000 studs apart, so turning on `Workspace.StreamingEnabled` would mean a phone only loads the zone the player is in. It is not turned on yet: client scripts that wait for world parts first need to be checked in Studio. Measure frame rate and memory on a phone before release.

## Still not done

- Smooth shapes (meshes) and textures need Studio or Blender and uploaded assets. Only the account owner can upload them.
- Lighting and the look at night have only been checked in our software renderer, not in Roblox. The place now has about 270 point lights; check frame rate on a phone at night.
