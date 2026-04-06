# Global Ascending Sticker Numbering Refactor Skill

## Purpose
This skill updates the sticker numbering system in the project so that sticker numbers are assigned using a single global ascending sequence across the entire World Cup 2026 seed.

The numbering must no longer depend on sticker type labels or composite code fragments such as:
- team code
- badge/player/photo prefixes
- local team-relative numbering

Instead, each sticker must expose or store only a simple ascending numeric value.

Example:
- if Mexico badge is currently the 10th sticker in the overall sequence, it should simply be numbered as `10`
- the final sticker in the final team of the final group should contain the final ascending number in the full dataset

This is a controlled data/schema refactor.
Do not modify UI, design, navigation, or unrelated business logic.

---

## Goal
Update the existing sticker numbering representation so that:

1. Sticker numbering is globally ascending across all stickers.
2. The numbering starts from the first sticker in the seed and continues sequentially to the last sticker.
3. Each sticker number is represented only by the number itself.
4. Old composite numbering fragments should no longer be used as the visible/main numbering value.
5. The system should remain easy to adjust later if team order or seed order changes.

---

## Scope Rules
You must work with strict scope control.

Allowed:
- inspect the World Cup seed file
- inspect related model fields only if necessary
- update numbering-related fields
- update logic that generates numbering values if required

Not allowed:
- do not redesign UI
- do not change screen structure
- do not refactor unrelated code
- do not rename unrelated classes
- do not change routing
- do not touch styling
- do not modify player names
- do not change groups, teams, flags, colors, or assets
- do not alter unrelated seed behavior

---

## Primary Task
Inspect the current seed implementation and identify how sticker numbering is currently generated.

Then update it so that:
- every sticker has a global ascending numeric sequence
- the value stored for sticker numbering is only the plain number
- old suffix fragments like `B-01`, `P-01`, `PL-01`, etc. are removed from the numbering representation that the app uses for sticker numbering

If a legacy internal ID must still remain for technical reasons, preserve it only if necessary.
However, the sticker number shown/stored as the main numbering value must be only the ascending number.

---

## Expected Interpretation
Per team, the dataset currently includes:
- 1 badge sticker
- 1 team photo sticker
- 18 player stickers

That means:
- 20 stickers per team
- 48 teams total
- 960 stickers total

The numbering must be globally sequential across all 960 stickers.

Example concept:
- Sticker 1
- Sticker 2
- Sticker 3
- ...
- Sticker 10 = Mexico badge, if that is where Mexico badge falls in the current seed order
- ...
- Sticker 960 = final player sticker of the last team in the final group

---

## File Targeting
Prioritize the existing World Cup seed file already used by the app, especially:

`lib/core/data/world_cup_2026_seed.dart`

Inspect related files only if strictly necessary to understand:
- which field represents sticker numbering
- whether numbering is stored in `id`, `code`, `globalNumber`, `number`, or similar fields
- which field the app actually uses as the sticker number

Do not make unnecessary file changes.

---

## Required Analysis Before Editing
Before changing anything, determine:

1. how sticker numbering is currently generated
2. which field is used for the app's sticker number
3. whether composite values are stored in:
   - id
   - code
   - globalNumber
   - displayNumber
   - number
   - another field
4. which exact field should now contain only the plain ascending number
5. whether any legacy internal identifier must remain untouched for compatibility

---

## Refactor Rules
When implementing the change:

1. Preserve compatibility whenever possible.
2. Prefer updating only the field actually used as sticker numbering.
3. If the app currently depends on one field for display and another for identity, keep identity stable and update only the displayed numbering field.
4. If no dedicated display-number field exists, introduce the smallest safe change possible.
5. Avoid broad schema redesign.
6. Keep numbering deterministic based on seed order.
7. Make the solution future-friendly:
   - if team ordering changes later, numbering should still be recalculated in ascending order from the seed structure

---

## Do Not Change
Do NOT change:
- player names
- team names
- group IDs
- team IDs
- colors
- assets
- flags
- sticker types
- player slot ordering
- UI text
- translations
- themes
- unrelated model behavior

Only change numbering behavior/fields as needed.

---

## Validation Requirements
Before finishing, verify:

- [ ] sticker numbering is globally ascending
- [ ] numbering is sequential with no gaps
- [ ] numbering covers the full dataset from first sticker to last sticker
- [ ] the main sticker numbering value contains only the plain number
- [ ] composite fragments like `B-01`, `P-01`, `PL-01` are no longer used as the main numbering value
- [ ] no unrelated files were modified unless strictly necessary
- [ ] UI/design was not changed
- [ ] player data was not changed

---

## Output Style
If reporting before editing, explain briefly:
- current numbering structure
- which field will be changed
- whether internal IDs will remain
- why the chosen field is the safest place for the refactor

If editing directly, keep the changes minimal and focused.

---

## Final Instruction
This is a focused numbering refactor.

Optimize for:
- minimal code disturbance
- preserving compatibility
- future-proof sequential numbering
- zero UI changes
- zero unrelated refactors