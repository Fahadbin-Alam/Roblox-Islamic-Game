# Playtest and performance report

Date: 2026-11-11. Environment: a Linux cloud container with Luau 0.6, luau-lsp 1.70.1 and
Rojo 7.4.4. **Roblox Studio and the Roblox Player cannot run here**, so nothing in this report
was played by a person or on a real Roblox server. Everything marked "verified" was verified by
the automated checks below. Everything that needs a live server is listed under "Not verified".

## Automated results

| Check | Command | Result |
|---|---|---|
| Unit tests (rules and data) | `tests/luau/run.sh <luau>` | 46 passed, 0 failed |
| Hub and activity zones in a mock engine | `tests/hub/run.sh <luau>` | 96 checks passed (about 2 minutes) |
| Battle arenas in a mock engine | `tests/world/run.sh <luau>` | 181 passed, 0 failed |
| Multiplayer simulation (real server scripts, simulated players) | `tests/sim/run.sh <luau>` | 44 passed, 0 failed |
| Client scripts against the real server | `tests/client/run.sh <luau>` | 9 passed: all 22 client scripts load, 160+ button presses and real campaign/PvP/mystery state raise no errors, and buttons fit and can be tapped on a 667 x 375 phone screen |
| Static analysis against the Roblox API | `tests/analyze.sh ...` | no syntax errors, unknown globals or broken requires |
| Place file builds | `rojo build default.project.json -o build.rbxlx` | builds |

All six test commands run in CI on every pull request (`.github/workflows/checks.yml`).
luau-lsp still reports non-fatal strict-mode type warnings (mostly `x and y` narrowing); they do
not change behaviour.

## The multiplayer simulation

`tests/sim/run.sh` runs the game's real server scripts (GameBootstrap, ProgressionService,
PvpArenaService, SocialService, CoopTrialsService, ParkourService, HistoricalWorldBuilder,
SeerahCampaignService, MysteryService) on top of the mock engine, with simulated players who
have characters and humanoids, a virtual clock, and a DataStore that serializes like Roblox's.
The players send the same remote events the clients send, use the same sword tool, and
trigger the same prompts. It checks:

- **PvP (2 players):** join, countdown, both armed on different teams, every sword hit does
  32 damage on the server, knockout ends the round, out-of-range swings miss, a ring-out is a
  knockout, first to 3 wins the match, both players receive the same results, the win is saved,
  both vote to play again, and a player who leaves hands the round to the other.
- **Saves:** progress (XP, Seerah and mystery completions, co-op count, parkour best) is saved
  on leave and comes back the next day; a next-day return counts as D1 retention; during a
  DataStore outage the player can still play, is warned, and the saved data is not overwritten.
- **Social:** mute hides chat only for the player who muted, also denies voice from the muted
  player's microphone, resets when a player leaves; jump-to only works for friends and has a
  cooldown; friends get a join notice; the voice list reports only eligible players.
- **Co-op (2 players):** one player alone cannot keep the gate open; the plates, lift and
  stairway work as a pair; one player on both pads does not count; two players finish together
  and both get credit once.
- **Parkour:** start pad, skipping ahead rejected, climbing every platform in order hits each
  checkpoint, a fall returns to the last checkpoint, the summit saves the best time.
- **Seerah campaign:** a locked chapter cannot start; **all 30 chapters were played in order**
  (travel, walk to the site, story, items from close range only, battle result, wrong then right
  answer, explanation, saved); the checklist shows 30/30; replaying does not pay out twice.
- **Mystery (2 players):** all five rooms solved start to finish by simulated pairs; in Bilal's room also a shared room, clues found by either player count for both, shared
  hint, wrong lock answer, episode locked until the door opens, steps in order, both credited
  with stars, room resets for the next group.

Bugs the simulation found and fixed:

1. The chat mute filter gave up if the chat channels took more than 30 seconds to appear, so
   mute could silently stop working. It now waits for them.
2. Co-op finishes could be farmed by standing on the finish pads (one extra finish every 8
   seconds), and a finish in the first 8 seconds after a server started was ignored. A finish now
   counts once per arrival.

Bugs the visual pass (docs/visual-benchmark.md) found with new checks and fixed:

3. Nine Seerah chapter items and arrival rings were inside walls, hills or vine rows.
4. Present-day Madinah: the travel point dropped players inside a solid block, and the
   Rawdah and visitation route were sealed inside the solid prayer hall.
5. A tent cushion was built without a colour, which errors on a real server.
6. Most arrival points and Seerah sites had no light at all, so night arrivals were dark.
7. The Badr and Uhud gates and the Journey road sat inside decorative rock ridges, so a player arriving there saw only rock.
8. Walking routes: a ring post stood on the path in from the Training Grounds gate, a palm trunk in front of the mystery landing, and every mystery room sign directly in front of its doorway.
9. Every Seerah site sign stood across the walk from the travel point to the chapter ring, and a stall blocked the way into both markets.
10. The battle arenas share the Workspace with the hub, and the hub had built into them: the Uhud gate, a hotel tower and the edge of the Haram deck stood inside the Badr battlefield, and a backdrop mountain and a ridge inside Uhud. The Uhud gate now stands south of the Badr gate, and a check keeps hub scenery out of both arenas.
11. Walking the hub promenades on the floor found a hotel podium across the Badr gate promenade, and a drop to the sand followed by a 4 to 8 stud ledge at the end of the story, manners and parkour promenades (too high to step, and the parkour one higher than a jump). The promenades now run onto the floors and the hotel stands clear.
12. On a small phone screen (667 x 375) the Journeys book ran off the top and right of the screen, so its close button could not be reached. Large panels (Journeys, main menu, shop, trivia, manners, mission results, story dialogue, battle summary) now shrink to fit the screen, and their close buttons are bigger so they stay tappable when shrunk.

What the simulation does **not** prove: real network replication between two Roblox clients,
physics (walking, jumping, collisions), animation, and how the controls feel. Those still need
a Studio or live test.

## What each requirement was tested with

| # | Requirement | Verified by tests | Not verified (needs Studio or a live server) |
|---|---|---|---|
| 1 | Badr and Uhud battles | Arena ground, lanes and spawns (world tests); stars, steadfast goal, reflection grading and replay rules (missions.spec); story summary now says how each battle ended | Control feel, combat pacing and fun |
| 2 | Multiplayer PvP | Match rules with 2 and 3 players (activities.spec); two simulated players play a full match and rematch through the real server scripts and sword tool (sim/pvp.spec) | **Two real Roblox clients over the network** |
| 3 | Seerah campaign | 30 chapters in order, all sourced, unlock order; all 30 played end to end through the real service (sim/campaign.spec) | Reading and walking it as a person |
| 4 | Sahabi mysteries | Rules (mysteries.spec); simulated pairs solve all five rooms through the real service (sim/mystery.spec) | All five rooms played by people |
| 5 | Parkour and co-op | Every jump possible with default movement; simulated climb and two-player co-op run through the real services (sim/parkour, sim/coop) | Control feel and physics |
| 6 | Respectful storytelling | Every mention of the Prophet carries ﷺ and no model or voice exists for him; faces stripped from guides and townspeople; each chapter separates gameplay from history | Scholar review of the content (see `docs/sources.md`) |
| 7 | Present-day vs historical | Every activity zone is more than 2,600 studs from the hub and no two zones overlap | Visual review in Studio |
| 8 | Social | Mute (chat and voice), friends-only join, friend notices, voice status through the real service (sim/social.spec) | Invite prompts, blocking and voice on real accounts |
| 9 | Ads and tracking | Retention rules (new, returning, D1/D7/D30) unit tested; hidden ad product cannot be bought from the shop | **Real ads, revenue and retention numbers** |
| 10 | Saves and proof | Save on leave, load next day, outage safety, serialization rules (sim/saves.spec) | DataStore saves on a published place |

## Performance (part counts from the mock build)

| Area | Parts |
|---|---|
| Whole hub (present-day Makkah, Madinah, districts) | 8,905 (154 lights) |
| Masjid al-Haram alone | 5,325 (2,332 SurfaceGui frames) |
| Historical Makkah and Madinah | 14,633 |
| Mystery wing (5 rooms) | 2,113 |
| Training grounds | 526 |
| Co-op trials | 256 |

About 26,000 parts and 270 point lights in total after the visual passes, mostly anchored, and the decoration does
not collide. Server loops poll every 0.1 to 0.5 seconds and only read character positions.
Frame rate, memory and network use could not be measured without a Roblox client. Check them
in Studio with the MicroProfiler and the Developer Console before release, especially on
phones. Consider StreamingEnabled (see docs/visual-benchmark.md).

## Blockers

These stay **incomplete** until someone with the Roblox account does them:

1. **Two-client PvP test.** The match runs correctly with two simulated players through the real
   server code, but real network play still needs Roblox Studio (Test > Clients and Servers, 2 players) or two
   accounts on a published place. Steps: both players open Journeys > Activities > Training
   Grounds > Join match, fight three rounds, check both screens show the same health, then press
   Play again.
2. **Rewarded ads and revenue.** Needs a published experience, the ad reward developer product ID
   in `MonetizationConfig.lua`, Rewarded Video Ads turned on in Creator Hub, and an eligible
   account. Roblox does not show ads to players under 13.
3. **Voice chat.** Needs voice turned on in Creator Hub > Experience settings > Communication,
   and voice-verified accounts. The code turns on default voice and offers mute.
4. **Real retention and revenue numbers.** Exist only after real players join the published game.
5. **Product IDs.** All shop product IDs are 0 until created in Creator Hub.
6. **Scholar review** of dates, hadith numbers and casualty figures.

## How to run a Studio playtest

1. `rojo build default.project.json -o build.rbxlx` and open the file in Studio.
2. Test > Start with 2 players. In each window press **Journeys**.
3. Seerah: start chapter 1, use Travel, read the story, answer the decision. Check the tick.
4. Mysteries: Go to Bilal, find the 5 clues, take a hint, open the lock, visit the stations.
5. Activities: climb the parkour tower; do the co-op course with both players; join a PvP match
   with both players and play to 3 round wins, then press Play again.
6. Friends: on a published place, invite and join a friend; mute them and check chat stops.
7. Write down the frame rate (Shift+F5) at the Haram, in historical Makkah and in the ring.
