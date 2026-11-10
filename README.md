# Path of the Sahabah

A Roblox historical learning game built in Luau that helps players ages 9-17 explore Islamic history through story-driven quests, respectful battle scenarios, and interactive companion biographies.

## Project Vision

The goal is not just to copy a Kaaba-style Roblox map. The goal is to build a stronger full experience:

- a beautiful hub world inspired by early Islamic settings
- clickable stories about the sahabah and major historical events
- battle experiences like Badr and Uhud with narration, objectives, and reflection moments
- progression, cosmetics, and Robux monetization that fit Roblox without turning the game into pay-to-win

## Core Pillars

- Learn through play: story quests, dialogue, collectibles, and simple mission objectives should teach history naturally.
- Respect the subject: sacred themes, worship, and major figures should be handled carefully and never treated as a joke.
- Make battles meaningful: battle content should feel like guided historical scenarios, not just random PvP.
- Build for replayability: players should always have something to unlock, revisit, or improve.

## Better Than The Reference

To make this experience better than the Roblox reference the project should aim for:

- stronger art direction and higher-quality building detail
- clearer onboarding and cleaner UI
- a central hub that connects stories, battles, and rewards
- companion stories with real progression instead of just wandering a map
- narrated battle phases so players understand what is happening historically
- cosmetic-first monetization using `Robux`, not `V-Bucks`

## Content Principles

- Keep the tone educational, respectful, and age-appropriate.
- Do not depict Prophets as playable characters.
- Treat sacred locations and acts of worship carefully.
- Avoid gore and overly harsh combat presentation.
- Reward learning and teamwork, not only fighting skill.

## Tech Foundation

This repo now uses a simple Rojo-friendly layout so we can organize Roblox Luau code cleanly in version control:

- shared config and content data live in `ReplicatedStorage`
- server boot logic lives in `ServerScriptService`
- client boot logic lives in `StarterPlayerScripts`

See [docs/game-foundation.md](docs/game-foundation.md) for the full design foundation.

## First MVP

The best first playable version is:

- one walkable hub route from the Kaaba area toward Medina
- one sahabi story path
- one battle scenario
- one simple shop with cosmetic support items
- one progression loop with rewards for learning and completing objectives
- one teleport menu so players can jump to major landmarks if they do not want to walk the full route

## Repo Layout

- [default.project.json](default.project.json)
- [docs/game-foundation.md](docs/game-foundation.md)
- [docs/monetization-setup.md](docs/monetization-setup.md)
- [src/ReplicatedStorage/Shared/Config/GameConfig.lua](src/ReplicatedStorage/Shared/Config/GameConfig.lua)
- [src/ReplicatedStorage/Shared/Data/CompanionStories.lua](src/ReplicatedStorage/Shared/Data/CompanionStories.lua)
- [src/ReplicatedStorage/Shared/Data/BattleScenarios.lua](src/ReplicatedStorage/Shared/Data/BattleScenarios.lua)
- [src/ReplicatedStorage/Shared/Data/ShopCatalog.lua](src/ReplicatedStorage/Shared/Data/ShopCatalog.lua)
- [src/ReplicatedStorage/Shared/Modules/ContentIndex.lua](src/ReplicatedStorage/Shared/Modules/ContentIndex.lua)
- [src/ServerScriptService/GameBootstrap.server.lua](src/ServerScriptService/GameBootstrap.server.lua)
- [src/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua](src/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua)

## Progression And Islamic Studies

- `src/ReplicatedStorage/Shared/Data/IslamicStudies.lua` holds the Islamic Studies units: the Five Pillars, how to pray (wudu and the steps of salah), daily duas, the six articles of iman, stories of the Prophets and the Seerah told through narration only, and the Eids and special days. Every lesson ends with a checkpoint quiz that the server grades.
- `src/ReplicatedStorage/Shared/Modules/Progression.lua` holds the rules: XP per activity, the level curve, rank titles, and badges.
- `src/ServerScriptService/Modules/PlayerProgress.lua` saves each player's XP, completions, badges, and stats to the `PlayerProgress_v1` DataStore. Other server scripts call `PlayerProgress.RecordCompletion(player, category, id, name)` when a player finishes a story, battle, lesson, learning walk, or manners lesson.
- Players open the hall from the `Learn` button or the Islamic Studies podium in the Trivia Court. The `My Journal` tab shows level, stats, and badges.
- The Islamic Studies podium in the Trivia Court also starts a study circle: everyone standing nearby answers one lesson's quiz together and passes or fails as a group (`StudyCircleService.server.lua`).
- The Battle of Uhud unlocks after the Battle of Badr or at level 3 (`Unlock` in `BattleScenarios.lua`).
- Daily return loop (`Shared/Modules/Daily.lua`, `Shared/Data/DailyReflections.lua`): each UTC day brings one cited reflection and one review question in the hall's **Today** tab, and a visit streak that grows the daily visit XP for up to a week.
- A suggested path (`Progression.Path`) powers the "Next" hint under the level bar and the checklist in **My Journal**.
- Finishing a path step is a quest: it pays a small XP bonus once. Three guide teachers (`Data/Guides.lua`, built by `GuideService`) stand at the Kaaba spawn, the Trivia Court, and the Story Court. Talking to one shows the next quest and a button that teleports the player there or opens the right lesson. The guides are present-day teachers, never historical figures.
- Level and XP show in the Roblox player list (leaderstats), and the **Top Learners** board beside spawn ranks the top 10 by XP across all servers (`LeaderboardService`, OrderedDataStore `TopLearnersXP_v1`). Profiles that failed to load never post a score.
- Some lessons end with an **order puzzle** (`Order` in `IslamicStudies.lua`): put the steps of wudu or salah, the Prophets, or Seerah events back in order. The server grades it (`SubmitOrder`) and pays XP once per puzzle; solving all of them earns the "In The Right Order" badge.
- Each player's level and rank title float above their head in the hub (`RankTagService`).
- Three battle outfits unlock for free at levels 3, 6, and 10 (`UnlockType = "Level"` in `ShopCatalog.lua`); equip them from the Shop.
- `ResponsiveUi.client.lua` shrinks fixed-size menus so they fit on phone screens.
- To also award real Roblox badges, create them in Creator Hub and set `RobloxBadgeId` on the matching badge in `Progression.lua`.

## Battle Story Missions

The battle gates offer two modes: **Story Mission** (co-op, 1 to 8 players) and **Team Skirmish** (the original PvP mode).

- `Shared/Data/BattleMissions.lua` defines each mission as a list of objectives (reach, hold, defend, defeat, discipline, narration), the enemy waves and lanes, the allied soldiers, and cited narration cards between steps.
- **Badr**: march to the wells, hold them, the rain falls (Qur'an 8:11), defend the banner through three waves, face the Makkan captain, then show mercy to the captives.
- **Uhud**: take position on the Archers' Hill, cover the army, then hold your post while the spoils tempt you. Allied archers leave their post as the historical archers did, and if players leave too, the cavalry flank arrives in force. The mission ends with the climb to the mountain and the regrouping.
- `ServerScriptService/Modules/BattleNpc.lua` runs the soldiers: R6 rigs with walk and attack animations, telegraphed sword swings, arrows with gravity, formations, and pathfinding when they get stuck. `MissionDirector.lua` runs the objectives, waves, respawns, and the HUD state.
- Missions earn up to 3 stars (complete, keep the steadfast goal, few falls) and end with a reflection quiz graded on the server. New badges: three stars at Badr and at Uhud, "Kept the Post", "Lessons of the Battles", and "Battle Veteran".
- Soldiers are generic and unnamed. The Prophet ﷺ and the Companions are never shown, and named historical figures appear only in narration.

Content added to `IslamicStudies.lua` should cite its Qur'an or hadith source, stay general where schools of thought differ, and never depict a Prophet.

## Automated Checks

`.github/workflows/checks.yml` runs on every pull request:

- `tests/luau/run.sh <luau>` runs unit tests for the shared data and progression rules outside Studio.
- `tests/analyze.sh <luau-lsp> <rojo> <globalTypes.d.luau>` type-checks every script against the Roblox API and fails on syntax errors, unknown globals, and broken requires.
- `tests/hub/run.sh <luau>` builds the whole hub in a mock Roblox engine and checks it: part and light budgets, the 2048-stud part limit, clear spawn and tawaf areas, walkable gates and ramps, the 13 minarets, the clock and night lighting, tawaf pilgrims that never walk through a landmark, and that no other district leaks into Masjid al-Haram.

To preview the hub without Studio, dump the parts and render a rough picture (shapes and colours only, no SurfaceGui detail):

```
tests/hub/run.sh <luau> --dump > parts.txt
python3 tests/hub/render.py parts.txt view.png --eye=0,40,170 --at=0,30,0
```

## Masjid al-Haram Hub

`src/ServerScriptService/Modules/MasjidAlHaram.lua` builds the sanctuary after today's mosque: the Kaaba (kiswa, gold hizam, sitara, Black Stone, Rukn al-Yamani, Mizab, Shadharwan), Hijr Ismail, Maqam Ibrahim, the white marble mataf, the multi-level mataf expansion with ramps, the Ottoman riwaq, the Saudi galleries, the Safa-Marwa mas'a, the King Fahd and King Abdullah expansions with named gates, 13 minarets and the Abraj Al-Bait clock tower. In this world +Z is north, so the clock tower stands to the south and the road to Madinah leaves to the north. `HaramTimeService.server.lua` sets the clock to Makkah time and turns the night lighting on after dark. Pilgrims in ihram are placed on the mataf by the server, and `TawafAmbience.client.lua` walks them anticlockwise around the Kaaba on each client while the player is nearby.
- `tests/world/run.sh <luau>` builds the battle arenas against a mock Roblox engine and checks that every mission point has ground, every enemy lane and player route can be walked, and no spawn is inside rock.

## Next Build Steps

1. Open `build.rbxlx` in Roblox Studio and playtest the generated hub, story prompts, battle gates, manners court, shop, and teleport menu.
2. Replace placeholder product and ad placement IDs in `ShopCatalog.lua` with real Creator Hub IDs.
3. Publish the experience from Studio and enable the Roblox monetization settings described in `docs/monetization-setup.md`.
4. Add a longer Studio QA pass for mobile UI, battle pacing, and sacred-location review before public release.
