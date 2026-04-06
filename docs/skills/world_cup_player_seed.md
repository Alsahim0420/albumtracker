# World Cup 2026 National Team Player Seed Skill

## Purpose
This skill is used for a **one-time data generation/update task** in the Album Tracker project.

The goal is to replace generic player placeholders with real player names for each qualified 2026 World Cup national team, using the latest senior men's national-team lineup available on FBref.

This skill must be executed with **strict scope control**:
- do not redesign anything
- do not refactor unrelated code
- do not modify app architecture
- do not change UI
- do not rename models or screens
- do not touch navigation or styling

Only update the team player data.

---

## Primary Source
Use:

- https://fbref.com/en/

FBref is the primary source for:
- national team pages
- scores and fixtures
- match logs
- player appearances
- lineups
- recent matches

If a detail is unclear in one page, use nearby recent FBref pages for the same national team as a fallback.

---

## Team List

### Hosts
- United States
- Mexico
- Canada

### CONMEBOL
- Argentina
- Brazil
- Colombia
- Ecuador
- Paraguay
- Uruguay

### UEFA
- Germany
- Austria
- Belgium
- Bosnia and Herzegovina
- Croatia
- Czech Republic
- Scotland
- Spain
- France
- England
- Norway
- Netherlands
- Portugal
- Sweden
- Switzerland
- Turkey

### AFC
- Saudi Arabia
- Australia
- Iran
- Iraq
- Japan
- Jordan
- Qatar
- Korea Republic
- Uzbekistan

### CAF
- Algeria
- Cape Verde
- Côte d'Ivoire
- Egypt
- Ghana
- Morocco
- DR Congo
- Senegal
- South Africa
- Tunisia

### CONCACAF
- Curaçao
- Haiti
- Panama

### OFC
- New Zealand

---

## Final Output Requirement
For each team, produce exactly **18 players** with this exact distribution:

- 2 Goalkeepers
- 6 Defenders
- 6 Midfielders
- 4 Forwards

No duplicates.
No placeholders.
Only real player names.

Names must be stored as:
- first name + first surname

Examples:
- Lionel Messi
- Julián Álvarez
- James Rodríguez
- Alphonso Davies

Avoid overly long names unless necessary.

---

## Data Selection Logic

For each national team:

1. Open FBref.
2. Search for the senior men's national team page.
3. Open the team's latest available match before the 2026 World Cup.
4. The latest match may be:
   - a friendly
   - a playoff / repechage match
   - another official senior national-team match if that is the latest available
5. Extract:
   - starting lineup
   - substitutes / bench
   - positions
   - minutes played if available
6. Build a candidate pool from the latest match.
7. If the latest match is not enough to complete the required positional distribution, inspect nearby recent matches from the same national team on FBref.
8. Prioritize:
   - players from the latest match first
   - players with more minutes
   - players with more recent appearances
   - players who appear consistently across recent matches
9. Build the final 18-player squad with this exact structure:
   - 2 GK
   - 6 DEF
   - 6 MID
   - 4 FWD

---

## Position Rules

Classify players by their most consistent recent national-team role.

Use these categories:

- GK = goalkeeper
- DEF = defenders (center-back, full-back, wing-back if mainly used defensively)
- MID = midfielders (defensive, central, attacking midfielders)
- FWD = forwards (wingers, strikers, center forwards, second strikers if mainly used in attack)

If a player can fit multiple roles:
- use the role most consistently reflected in recent national-team usage
- prefer the role that helps satisfy the required team distribution without forcing unrealistic picks

---

## Strict Scope Rules

You must only update team player data.

You must NOT:
- change UI widgets
- change screens
- change colors
- change themes
- change navigation
- change architecture
- change repositories or services unless strictly necessary to inject the new data
- rename unrelated variables
- refactor unrelated files
- change business logic outside the team player seed/update

This is a data update task only.

---

## Project Update Behavior

When working inside the project:

1. First locate the file or files where the app stores national-team player data.
2. Preserve:
   - team IDs
   - sticker IDs
   - group IDs
   - country codes
   - asset references
   - flags
   - image references
   - existing structure
3. Replace only generic placeholder names such as:
   - Player 1
   - Player 2
   - Unknown Player
   - temporary names
4. Keep the existing app schema intact whenever possible.
5. If the project stores players in arrays, maps, JSON seed files, model constructors, or local constants, update only the player-name values.
6. Do not introduce a new system unless truly necessary.

---

## Team Name Mapping Rules

If the app uses alternate country labels, map them safely.

Examples:
- United States -> USA / US
- Korea Republic -> South Korea / KOR
- DR Congo -> Congo DR / Democratic Republic of the Congo
- Côte d'Ivoire -> Ivory Coast
- Curaçao -> Curacao
- Bosnia and Herzegovina -> Bosnia-Herzegovina
- Czech Republic -> Czechia
- Turkey -> Türkiye / Turkiye

Preserve the app's existing naming convention if one already exists.

---

## Expected Workflow Inside Cursor

Follow this exact workflow:

1. Inspect the project and find the national team seed/data source.
2. Identify the current structure used for players.
3. Do not change that structure unless absolutely required.
4. For each team in the qualified-team list:
   - fetch latest lineup context from FBref
   - identify starters and substitutes
   - complete the 18-player selection
   - assign them to the correct role group
5. Update the existing team data in place.
6. After editing, verify:
   - every team has exactly 18 players
   - every team has 2 goalkeepers
   - every team has 6 defenders
   - every team has 6 midfielders
   - every team has 4 forwards
   - no placeholder names remain
   - no unrelated files were modified

---

## Validation Checklist

Before finishing, verify all of the following:

- [ ] all qualified teams are included
- [ ] each team has exactly 18 players
- [ ] each team has exactly 2 goalkeepers
- [ ] each team has exactly 6 defenders
- [ ] each team has exactly 6 midfielders
- [ ] each team has exactly 4 forwards
- [ ] no duplicate players inside the same team
- [ ] no placeholder names remain
- [ ] no UI files were changed
- [ ] no design files were changed
- [ ] no unrelated refactors were introduced

---

## Output Preference

If asked to produce structured output before editing files, use this shape:

```json
{
  "United States": {
    "goalkeepers": ["Player A", "Player B"],
    "defenders": ["Player C", "Player D", "Player E", "Player F", "Player G", "Player H"],
    "midfielders": ["Player I", "Player J", "Player K", "Player L", "Player M", "Player N"],
    "forwards": ["Player O", "Player P", "Player Q", "Player R"]
  }
}