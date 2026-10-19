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

- `src/ReplicatedStorage/Shared/Data/IslamicStudies.lua` holds the Islamic Studies units: the Five Pillars, how to pray (wudu and the steps of salah), daily duas, the six articles of iman, and stories of the Prophets told through narration only. Every lesson ends with a checkpoint quiz that the server grades.
- `src/ReplicatedStorage/Shared/Modules/Progression.lua` holds the rules: XP per activity, the level curve, rank titles, and badges.
- `src/ServerScriptService/Modules/PlayerProgress.lua` saves each player's XP, completions, badges, and stats to the `PlayerProgress_v1` DataStore. Other server scripts call `PlayerProgress.RecordCompletion(player, category, id, name)` when a player finishes a story, battle, lesson, learning walk, or manners lesson.
- Players open the hall from the `Learn` button or the Islamic Studies podium in the Trivia Court. The `My Journal` tab shows level, stats, and badges.
- The Islamic Studies podium in the Trivia Court also starts a study circle: everyone standing nearby answers one lesson's quiz together and passes or fails as a group (`StudyCircleService.server.lua`).
- The Battle of Uhud unlocks after the Battle of Badr or at level 3 (`Unlock` in `BattleScenarios.lua`).
- To also award real Roblox badges, create them in Creator Hub and set `RobloxBadgeId` on the matching badge in `Progression.lua`.

Content added to `IslamicStudies.lua` should cite its Qur'an or hadith source, stay general where schools of thought differ, and never depict a Prophet.

## Automated Checks

`.github/workflows/checks.yml` runs on every pull request:

- `tests/luau/run.sh <luau>` runs unit tests for the shared data and progression rules outside Studio.
- `tests/analyze.sh <luau-lsp> <rojo> <globalTypes.d.luau>` type-checks every script against the Roblox API and fails on syntax errors, unknown globals, and broken requires.

## Next Build Steps

1. Open `build.rbxlx` in Roblox Studio and playtest the generated hub, story prompts, battle gates, manners court, shop, and teleport menu.
2. Replace placeholder product and ad placement IDs in `ShopCatalog.lua` with real Creator Hub IDs.
3. Publish the experience from Studio and enable the Roblox monetization settings described in `docs/monetization-setup.md`.
4. Add a longer Studio QA pass for mobile UI, battle pacing, and sacred-location review before public release.
