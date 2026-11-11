# Interview notes: Path of the Sahabah

Short answers to the questions an interviewer is likely to ask about this project, each tied to the code. Paths are relative to the repo root.

## The 30-second pitch

An educational Roblox game in Luau for ages 9 to 17. Players learn Islamic history and the basics of the faith through a hub world, Companion story quests, 30 lessons with server-graded quizzes, and co-op story missions of Badr and Uhud. The server owns every reward and every save. Player data is saved through a session-locked DataStore layer I can explain end to end, and CI runs unit tests, layout tests against a mock engine, type checking and linting on every PR.

## Questions and answers

### 1. How is the code organised?

Rojo maps `src/` onto the Roblox data model (`default.project.json`). `src/ReplicatedStorage/Shared` holds content tables (`Data/`) and pure rule modules (`Modules/Progression.lua`, `Daily.lua`, `MissionRules.lua`) that both sides can require. `src/ServerScriptService` has one `*.server.lua` service per feature plus server modules (`Modules/PlayerProgress.lua`, `Modules/SessionStore.lua`, `Modules/Receipts.lua`, `Modules/MissionDirector.lua`) and the answer keys (`Modules/LessonAnswers.lua`, `ReflectionAnswers.lua`, `TriviaQuestions.lua`), which Roblox never replicates to clients. `src/StarterPlayer/StarterPlayerScripts` only draws UI and sends requests. Content is data, not code: adding a lesson means adding a table entry to `Shared/Data/IslamicStudies.lua` and its answers to `LessonAnswers.lua`.

### 2. How do the client and server talk, and how do you stop cheating?

`src/ServerScriptService/GameBootstrap.server.lua` creates every RemoteEvent under `ReplicatedStorage.Remotes`, grouped by feature. Every handler treats its arguments as untrusted: it checks `typeof`, looks the id up in a server table, and ignores anything else. For example `submitQuiz.OnServerEvent` in `src/ServerScriptService/ProgressionService.server.lua` checks types, applies a 1-second cooldown, finds the lesson server-side, and grades with `LessonGrading.Quiz`; the client never says "I passed".

The client also never has the answers. Anything in ReplicatedStorage can be read by an exploiter, so `Shared/Data/IslamicStudies.lua` and `BattleMissions.lua` carry only prompts and choices (puzzle steps are listed alphabetically). The keys are in `ServerScriptService/Modules` (`LessonAnswers.lua` per lesson, `ReflectionAnswers.lua` per reflection question, `TriviaQuestions.lua` whole). The client sends the index it picked; `Modules/LessonGrading.lua` rejects anything that is not a whole number within the options (strings, 2.5, NaN), grades against the key, and only then returns the right answer and explanation, so the hall still shows feedback after answering. Trivia shuffles its options every round, because in the data the answer was always the first option. Keeping keys in a second file risks drift, so `LessonGrading.BuildIndex` errors at server start and `tests/luau/answers.spec.luau` fails if a question has no key, a key points past the options, or a puzzle step does not match. Battle reflections are only accepted once per finished mission (`pendingReflections` in `BattleService.server.lua`). Combat damage comes from server-side Tool activation in `Modules/BattleLoadout.lua` (`applyDamage`), not from client-reported hits. Story steps advance only through ProximityPrompts, which Roblox range-checks.

### 3. Walk me through how player data is saved.

`src/ServerScriptService/Modules/SessionStore.lua`, used by `PlayerProgress.lua` and `ShopService.server.lua`:

- `Open` reads with `UpdateAsync` and stamps a `SessionLock` (JobId, a GUID session id, timestamp). If another server holds a fresh lock, it waits for that server's final save, then takes over; a lock older than 30 minutes means a crashed server and is taken at once.
- `Session.Save` uses `UpdateAsync` and cancels the write unless the record still carries this session's id, so a server that lost the lock cannot overwrite newer data. Saves for one player are queued so an older snapshot cannot land last.
- Every call is in `pcall` with exponential backoff (`SessionStore.Retry`: 1 s, 2 s, 4 s).
- Autosave every 2 minutes when dirty, a lock refresh every 10 minutes, a final save plus release on `PlayerRemoving`, and `BindToClose` waits for every final save in flight (`PlayerProgress.SaveAll`).

### 4. Why UpdateAsync instead of SetAsync?

`SetAsync` writes blindly, so it cannot check anything about the current value. `UpdateAsync` gives me the current record inside a transform function, so I can refuse the write when another server owns the key, and Roblox retries the transform if the key changed underneath me. The leaderboard uses the same idea: `postScore` in `LeaderboardService.server.lua` returns nil (cancels) unless the new XP is higher, so a stale server can never lower a score.

### 5. What happens if the DataStore is down when a player joins?

`SessionStore.Open` returns no session after its retries. `PlayerProgress.Load` gives the player a fresh profile so they can still play, shows a "progress could not load" toast, and never saves that profile (`IsSaveable` is false), because saving it would overwrite their real data with a blank one. The leaderboard also skips players whose profile is not saveable.

### 6. How do you handle Robux purchases safely?

`MarketplaceService.ProcessReceipt` in `ShopService.server.lua` hands the receipt to `Modules/Receipts.lua`. It returns `NotProcessedYet` unless the player is in this server with a loaded, saveable profile. It adds the grant and the receipt's `PurchaseId` to the same record and saves synchronously; only if that save succeeds does it return `PurchaseGranted`. If the save fails (or throws), the grant is undone and Roblox retries later. If the PurchaseId is already in the record, it acknowledges without granting again. If Roblox calls again for a receipt whose save is still in flight, that call returns `NotProcessedYet` rather than acknowledging a grant that might still fail. Because the grant and the "processed" mark are one write, there is no window where one exists without the other. The module takes its profile lookup and save function as arguments, so `tests/luau/receipts.spec.luau` tests every branch with a fake save.

### 7. How is progression designed?

`src/ReplicatedStorage/Shared/Modules/Progression.lua`. XP per activity (`Progression.Rewards`), a level curve where level n to n+1 costs `100 + (n - 1) * 60` XP (`XPForNextLevel`), rank titles, 23 badges defined as predicates over the profile (`FindNewBadges`), and a 9-step suggested path. First completion pays full XP, replays pay 25%, and `PlayerProgress.RecordCompletion` pays replay XP for the same activity at most once every 2 minutes. `Progression.Sanitize` validates whatever comes back from the DataStore field by field, so a corrupted or old record cannot crash the server.

### 8. How do you test a Roblox game outside Studio?

Three CI steps in `.github/workflows/checks.yml`:

- `tests/luau/run.sh` bundles the pure modules into one file with a tiny `require` shim (`tests/luau/prelude.luau`) and runs specs with the standalone `luau` binary. `tests/luau/sessionstore.spec.luau` runs `SessionStore` against an in-memory DataStore: server hop, lock takeover, stale lock, retry backoff, outage. `receipts.spec.luau` covers the purchase flow (save fails, retry, duplicate PurchaseId) and `answers.spec.luau` the answer keys and grading.
- `tests/world/run.sh` builds the battle arenas against a mock engine (`tests/world/mock.luau`) and checks geometry: ground under every point, walkable lanes, no spawn inside rock.
- `tests/analyze.sh` type-checks every script with luau-lsp against the Roblox API and fails on syntax errors, unknown globals and broken requires; selene lints with the Roblox standard library.

The trick that makes this possible: rules modules take no Roblox services, and `SessionStore` and `Receipts` take their store, save function, clock and wait function as arguments (dependency injection).

### 9. How do the battle missions work?

`Shared/Data/BattleMissions.lua` describes each mission as data: objectives (reach, hold, defend, defeat, discipline, narration), enemy waves and lanes, allies, and narration cards with references. `Modules/MissionDirector.lua` runs the objectives, waves and respawns and streams state to `MissionHud.client.lua`. `Modules/BattleNpc.lua` drives the soldiers with `Humanoid:MoveTo`, telegraphed swings, arrows with gravity, and pathfinding when stuck. At Uhud, allied archers leave their post as the historical archers did, and if players also leave, the cavalry flank arrives: the lesson is the gameplay.

### 10. How did you keep the religious content accurate and respectful?

Rules are written into the data files and `GameConfig.ContentRules`: no Prophet is shown, voiced or playable (narration only); soldiers are generic and unnamed; guide NPCs are present-day teachers, not historical figures (`Shared/Data/Guides.lua`); rulings that differ between madhhabs stay general and point to a teacher; daily reflections and battle narration cards carry a Qur'an or hadith reference (for example the rain at Badr cites Qur'an 8:11). Monetization screens are placed away from the Kaaba (`docs/monetization-setup.md`).

## Weak spots, and how to talk about them honestly

| Weak spot | What to say |
| --- | --- |
| Fixed: the client used to have the quiz answers (`IslamicStudies.lua`, `BattleMissions.lua` and `TriviaQuestions.lua` are or were in ReplicatedStorage, and every trivia and reflection answer was option 1). | "The keys now live in ServerScriptService and the client only gets prompts and choices. The trade-off is a second file per content type, so a startup check and a unit test fail on any drift." |
| A failed quiz shows the right answers, so a player can fail once and pass on the next try. | "That is on purpose in a learning game: the feedback is the lesson. First-time XP still pays once, replays pay 25% at most every 2 minutes, and submissions have a 1-second cooldown." |
| Some files are very large: `BattleService.server.lua` (~2,100 lines), `HubWorldBuilder.server.lua` (~1,700). | "It grew feature by feature. The next refactor is splitting the battle session, queue and reward logic into modules, the way `MissionDirector` was split out." |
| Strict mode, but not clean: luau-lsp reports ~170 type diagnostics; CI only fails on the crash-class ones (`tests/analyze.sh`). | "I made CI block on errors that crash at runtime first and left the rest visible. Driving the count down and then failing on any new warning is the plan." |
| Ultimate charges are bought with Robux and deal damage in battles, including Team Skirmish. | "That is a pay-to-win risk against the project's cosmetic-first goal. I would restrict ultimates to co-op missions or make them cosmetic." |
| `build.rbxlx` is committed and drifts from `src/` (a fresh `rojo build` differs, and the old file still has the answer keys in ReplicatedStorage). | "The source of truth is `src/`; the place file should be a CI artifact, not committed. Until then, build with `rojo build` before opening or publishing." |
| No formatter is enforced (StyLua would change ~4,000 lines). | "I deferred it to avoid conflicts with open branches; it is a one-time commit plus a CI check." |
| A server that loses its session lock stops saving but does not kick the player. | "That only happens if the same account is in two servers. ProfileService-style libraries kick the old session; that is a small follow-up." |
| No DataStore budget checks (`GetRequestBudgetForRequestType`). | "Autosave is every 2 minutes per player and only when dirty, which is well inside the per-server budget, but under heavy load I would check the budget before non-critical writes." |

If you used AI tools while building this, be ready to say so plainly and to explain any file in your own words; interviewers care most that you understand the trade-offs above.
