# Playtest and performance report

Date: 2026-11-11. Environment: a Linux cloud container with Luau 0.6, luau-lsp 1.70.1 and
Rojo 7.4.4. **Roblox Studio and the Roblox Player cannot run here**, so nothing in this report
was played by a person or on a real Roblox server. Everything marked "verified" was verified by
the automated checks below. Everything that needs a live server is listed under "Not verified".

## Automated results

| Check | Command | Result |
|---|---|---|
| Unit tests (rules and data) | `tests/luau/run.sh <luau>` | 46 passed, 0 failed |
| Hub and activity zones in a mock engine | `tests/hub/run.sh <luau>` | 55 checks passed (about 80 s) |
| Battle arenas in a mock engine | `tests/world/run.sh <luau>` | 181 passed, 0 failed |
| Static analysis against the Roblox API | `tests/analyze.sh ...` | no syntax errors, unknown globals or broken requires |
| Place file builds | `rojo build default.project.json -o build.rbxlx` | builds |

All four test commands run in CI on every pull request (`.github/workflows/checks.yml`).
luau-lsp still reports non-fatal strict-mode type warnings (mostly `x and y` narrowing); they do
not change behaviour.

## What each requirement was tested with

| # | Requirement | Verified by tests | Not verified (needs Studio or a live server) |
|---|---|---|---|
| 1 | Badr and Uhud battles | Arena ground, lanes and spawns (world tests); stars, steadfast goal, reflection grading and replay rules (missions.spec); story summary now says how each battle ended | Control feel, combat pacing and fun |
| 2 | Multiplayer PvP | Full match with 2 and 3 players: rounds, knockouts, timeouts, draws, leavers, rematch (activities.spec) | **Two separate clients joining, fighting and seeing the same damage** |
| 3 | Seerah campaign | 30 chapters in order, all sourced, unlock order, every stage of the run, sites inside their zone, items and markers built | Walking through every chapter in game |
| 4 | Sahabi mysteries | Clues, hints, lock, ordered and unordered episodes, star rating (mysteries.spec); every room built with its clues and door | Playing a room with friends |
| 5 | Parkour and co-op | Every parkour jump possible with default movement, checkpoints in order, too-fast runs rejected; co-op course built | Control feel; two players solving the co-op course |
| 6 | Respectful storytelling | Every mention of the Prophet carries ﷺ and no model or voice exists for him; faces stripped from guides and townspeople; each chapter separates gameplay from history | Scholar review of the content (see `docs/sources.md`) |
| 7 | Present-day vs historical | Every activity zone is more than 2,600 studs from the hub and no two zones overlap | Visual review in Studio |
| 8 | Social | Static checks only (the services use `SocialService`, `TextChatService`, `VoiceChatService`) | Invites, join, mute and voice on real accounts |
| 9 | Ads and tracking | Retention rules (new, returning, D1/D7/D30) unit tested; hidden ad product cannot be bought from the shop | **Real ads, revenue and retention numbers** |
| 10 | Saves and proof | New progress categories survive the save sanitizer (progression and activities specs) | DataStore saves on a published place |

## Performance (part counts from the mock build)

| Area | Parts |
|---|---|
| Whole hub (present-day Makkah, Madinah, districts) | 6,629 (70 lights) |
| Masjid al-Haram alone | 5,325 (2,332 SurfaceGui frames) |
| Historical Makkah and Madinah | 977 |
| Mystery wing (5 rooms) | 228 |
| Co-op trials | 25 |
| Training grounds | 24 |

The new zones add about 1,250 parts, most of them anchored. Server loops poll every 0.1 to
0.5 seconds and only read character positions. Frame rate, memory and network use could not be
measured without a Roblox client; check them in Studio with the MicroProfiler and the
Developer Console before release, especially on phones.

## Blockers

These stay **incomplete** until someone with the Roblox account does them:

1. **Two-client PvP test.** Needs Roblox Studio (Test > Clients and Servers, 2 players) or two
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
