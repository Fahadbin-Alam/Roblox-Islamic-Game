# Game Foundation

## One-Sentence Pitch

`Path of the Sahabah` is a Roblox educational adventure where players explore a polished Islamic history hub, choose companion stories to learn from, and enter guided battle scenarios such as Badr and Uhud that mix gameplay with narration and historical context.

## What The Game Should Feel Like

The experience should feel respectful, cinematic, and easy to understand. A player should log in and quickly understand three things:

- where to go
- what they can learn
- what they can unlock next

The best version of this game is not just a map. It is a full loop of exploration, learning, challenge, and reward.

## Target Audience

- Primary: ages 9-17
- Secondary: families, teachers, and players interested in Islamic history

Because the audience includes younger players, the design should prefer clear narration, guided objectives, readable UI, and age-appropriate battle presentation.

## Core Experience Pillars

### 1. Story Hub

The hub should be the center of the whole game. It should include:

- a main courtyard for navigation
- a companion library where players click a figure to begin a story
- a battle gate where players queue for Badr or Uhud
- a museum or archive area with unlockable facts, artifacts, and lore
- a market area for cosmetic-only or mostly cosmetic purchases

### 2. Companion Stories

Players should be able to walk up to a character display, click it, and choose a story. Each story should use:

- narrated dialogue scenes
- short quests
- collectibles or investigation objectives
- reflection or quiz moments
- rewards such as titles, badges, or knowledge tokens

This is stronger than a plain history wall because the player is doing something while learning.

### 3. Guided Battle Scenarios

The battle content should feel like an educational reenactment, not a generic arena fight. A good structure is:

- opening narrator briefing
- role selection
- objective phase
- story checkpoint scene
- final push
- post-battle reflection and rewards

This keeps the historical context attached to the gameplay. It also gives us a better tone than a simple free-for-all PvP mode.

### 4. Progression

Players should always have a reason to return. Good progression options:

- unlock new companion stories
- earn titles
- unlock cosmetics
- complete history collections
- level up a knowledge rank

## Recommended First Content Wave

For the first version, the scope should stay small and polished.

### Hub

- one high-quality central hub
- clear portals or doors for `Stories`, `Battles`, `Museum`, and `Shop`

### Stories

Start with 2-4 companion stories with strong contrast in themes. Suggested examples:

- Bilal ibn Rabah (RA): perseverance and faith
- Mus'ab ibn Umayr (RA): sacrifice and leadership
- Nusaybah bint Ka'b (RA): courage and protection
- Umar ibn al-Khattab (RA): justice and strength

### Battles

Start with only two battle scenarios:

- Battle of Badr
- Battle of Uhud

Each scenario should teach a few clear lessons rather than trying to cover every detail.

## Battle Design Direction

If players are going to "fight each other," it will work better if the combat is objective-based and phase-based instead of pure elimination.

### Badr Example

- players spawn in teams
- the narrator explains the importance of preparation and unity
- players complete setup objectives before the main clash
- the match pauses briefly at key story moments for narration
- end-of-round rewards include both battle score and history score

### Uhud Example

- a defense or archer-hill phase teaches discipline and positioning
- the scenario reacts if players leave important positions too early
- the narrator explains the consequence as part of the lesson

This approach makes the battle itself part of the teaching.

## Respect And Content Guardrails

- Do not make Prophets playable or directly visualized.
- Avoid comedic treatment of sacred moments or spaces.
- Avoid gore, dismemberment, or harsh death presentation.
- Prefer stylized Roblox combat feedback over realistic violence.
- Use a review pass for every story script so the writing stays respectful and historically careful.

## Monetization Direction

Roblox uses `Robux`, so the project foundation should be planned around Roblox monetization systems.

The safest approach is cosmetic-first monetization:

- banners
- outfit variants
- mount skins
- camp decorations
- profile frames
- supporter tags

Try to avoid selling direct battle power, especially in educational historical content. The more respectful model is:

- cosmetics
- convenience
- supporter products
- private servers

Good examples:

- `Founder Support Pack`
- `VIP Courtyard Access`
- `Historic Banner Pack`
- `Private Server`

Bad examples:

- extra damage in Badr
- paid-only access to core learning content
- sacred content locked behind a paywall

## MVP Production Order

### Phase 1. World And Navigation

- build the central hub
- create portals for stories and battles
- create one clean main menu

### Phase 2. Story System

- click-to-open companion UI
- basic dialogue flow
- first story quest
- completion rewards

### Phase 3. Battle System

- team assignment
- scenario phases
- narrator checkpoints
- win and reward logic

### Phase 4. Progression And Shop

- save data
- currency rewards
- cosmetic inventory
- game passes and products

## Technical Foundation In This Repo

This repo now includes a simple Luau content structure:

- `GameConfig.lua` stores project-level settings and rules
- `CompanionStories.lua` stores story metadata
- `BattleScenarios.lua` stores battle metadata and phases
- `ShopCatalog.lua` stores monetization definitions
- `ContentIndex.lua` pulls all startup content into one place
- `GameBootstrap.server.lua` prepares server-side folders and startup checks
- `ClientBootstrap.client.lua` loads the content manifest on the client

This is intentionally lightweight so we can grow it step by step instead of overengineering the first version.

## Best Next Coding Step

The most valuable next feature is a playable hub plus one clickable story NPC. After that, the second best step is a narrator-driven Badr prototype with simple team objectives.
