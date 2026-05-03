# SKILL — STICKER SCAN REFINEMENT (FRONT/BACK DETECTION + BETTER MULTI-CAPTURE UX)

## CONTEXT

This is an existing Flutter application for collecting World Cup stickers. The app already has:
- an existing UI
- an existing floating action button "+"
- local sticker data
- a sticker scan feature already implemented
- OCR with Google ML Kit
- local persistence and collection logic

The current feature needs refinement.

Your task is to improve the sticker scan system WITHOUT redesigning the app and while keeping the code aligned with Clean Architecture.

IMPORTANT:
- Do NOT redesign the UI
- Do NOT refactor unrelated parts of the project
- Do NOT break existing collection flows
- Do NOT replace the current architecture with ad-hoc code
- Keep changes clean, scoped, and maintainable

---

## HIGH-LEVEL GOALS

You must improve the sticker scan feature in three areas:

1. Fix the matching logic so one image does not produce many unrelated sticker matches
2. Add clear FRONT vs BACK interpretation logic
3. Improve the multiple-camera-capture flow so it is intuitive and does not feel like an infinite loop

---

## PROBLEM 1 — OVERMATCHING FROM OCR

Current behavior:
A single image containing multiple visible stickers or many numeric fragments can produce too many matches, because the OCR text is interpreted too broadly.

The current implementation appears to:
- extract many OCR candidates from the full text blob
- treat numeric fragments too loosely
- combine candidate-based matching and raw full-text player-name matching
- allow one image to generate many distinct sticker updates

This must be corrected.

---

## PROBLEM 2 — FRONT VS BACK INTERPRETATION

The scan system currently does not clearly separate:
- scanning the FRONT of a sticker
- scanning the BACK of a sticker

This causes incorrect matching behavior.

### Intended behavior

#### FRONT image
If the user scans the front side of a sticker:
- the app should identify the sticker using player name + country
- it should ignore loose numeric fragments as primary match signals
- it should not rely on the back-side code logic

#### BACK image
If the user scans the back side of a sticker:
- the app should identify the sticker using only the printed sticker code
- it should ignore names, dates, country-only tokens, and loose numeric fragments
- matching should be strict and code-based

#### UNKNOWN image
If the side cannot be identified confidently:
- do not auto-add anything
- return an unknown / not identifiable result
- let the UI show proper feedback

---

## PROBLEM 3 — MULTIPLE CAMERA CAPTURE UX

The current "take multiple photos" flow feels like an infinite loop or a poor repeated-capture experience.

This must be redesigned WITHOUT redesigning the visual identity of the app.

### Desired UX

If the user chooses "take multiple photos", the flow should feel intuitive:

1. Open the camera
2. Let the user take one photo
3. After each capture, show a review/confirmation step for that photo
4. The user should be able to:
   - confirm the photo
   - retake the photo
   - add another photo
   - finish the capture session
5. Only when the user finishes the capture session should the app start the OCR + matching + add-to-collection process for the confirmed images

### Important
It should NOT feel like:
- endless repeated capture
- automatic looping without clear confirmation
- unclear state transitions

The user must always know:
- what photo was just captured
- whether it was accepted
- whether they are adding another one
- when processing will begin

---

## ARCHITECTURE REQUIREMENTS

Keep the implementation aligned with Clean Architecture.

### Presentation layer
Responsible for:
- triggering scan actions from the existing FAB
- managing user interaction flow
- multi-capture confirmation UX
- showing scan summary / feedback

### Domain layer
Responsible for:
- deciding whether an image is FRONT, BACK, or UNKNOWN
- parsing valid identifiers
- selecting the appropriate matching strategy
- orchestrating scan processing

### Data layer
Responsible for:
- image acquisition
- OCR service
- access to local sticker data and collection persistence

Do not place business logic directly inside widgets.

---

## REQUIRED DESIGN OF THE NEW LOGIC

Implement a side-detection and strategy-based scan system.

### New conceptual flow

For each image:
1. Run OCR
2. Normalize OCR text
3. Detect image side:
   - FRONT
   - BACK
   - UNKNOWN
4. Use the correct matching strategy:
   - FRONT → player name + country
   - BACK → strict sticker code only
   - UNKNOWN → no auto-add
5. Collect results
6. Save only valid matches using the existing add-to-collection logic

---

## REQUIRED COMPONENTS

Create or adapt components similar to these, following the project's naming conventions if needed:

- StickerImageSideDetector
- FrontStickerMatcher
- BackStickerCodeParser
- StickerScanStrategyResolver
- StickerScanCoordinator or equivalent orchestration service
- Updated result models if needed

You do not need to use these exact names if the project has stronger conventions, but the responsibilities must exist clearly.

---

## FRONT-SIDE MATCHING RULES

When an image is classified as FRONT:
- Use player name as the primary signal
- Use country as a validation signal
- Ignore loose numeric fragments as primary identifiers
- Do not match by global numeric ID unless there is an explicit, safe, and justified fallback
- Avoid partial weak matches that can create false positives

### Expected behavior
Examples like:
- "LIONEL MESSI" + "ARG"
- "CRISTIANO RONALDO" + "POR"
should resolve correctly

But values like:
- years
- height
- weight
- dates
must not drive sticker matching

---

## BACK-SIDE MATCHING RULES

When an image is classified as BACK:
- Extract only structured sticker-code candidates
- Match only by code
- Use strict or near-strict validation
- Ignore names
- Ignore dates
- Ignore country-only tokens unless they are part of a full valid code
- Ignore loose numeric fragments

### Examples of acceptable structured codes
Examples may include formats like:
- A1
- C12
- ARG01
- ARG-PL-01
- BRA-10
- one letter + one number
- one letter + multiple numbers
- multiple letters + multiple numbers

The code parser must be flexible enough to support current and future formats, but strict enough to avoid noisy matches.

---

## UNKNOWN-SIDE RULES

If the system cannot confidently classify the image as FRONT or BACK:
- do not auto-add anything
- mark the result as unknown / unclassified / not confidently identified
- preserve clean feedback to the user

---

## MULTI-CAPTURE CAMERA FLOW REQUIREMENTS

Refactor the current multi-photo camera behavior into a session-like flow.

### Desired session behavior
If the user selects "Take multiple photos":
- start a capture session
- each photo is captured one at a time
- after each capture, show a review step
- review step actions:
  - Confirm photo
  - Retake photo
  - Add another photo
  - Finish session

### Processing behavior
- Only confirmed photos belong to the session
- Retaken photos should replace the rejected capture
- OCR and sticker matching should begin only after the user taps "Finish session"
- The user should never feel trapped in a loop

### UX constraints
- Keep this consistent with the app's current UI patterns
- Reuse existing bottom sheets, dialogs, or pages if appropriate
- Do not redesign the app visually
- Make the flow feel natural and explicit

---

## MATCH LIMITS AND SAFETY RULES

You must prevent one image from generating many unrelated sticker matches.

Implement safe constraints such as:
- FRONT image should usually resolve to one sticker
- BACK image should usually resolve to one sticker
- UNKNOWN should resolve to none
- If multiple possible matches exist, do not blindly add all of them
- Use confidence and strategy rules to narrow results
- Prefer one high-confidence match over many weak matches

Do not allow broad OCR text blobs to create uncontrolled match unions.

---

## EXISTING LOGIC REUSE

You must reuse existing project logic wherever possible:
- existing scan entry point from the FAB
- existing repository / notifier / bloc / provider logic for adding stickers
- existing local storage
- existing OCR service if still appropriate
- existing result presentation if reusable

Do not duplicate add-to-collection logic.

---

## CLEAN IMPLEMENTATION REQUIREMENTS

Your implementation must:
- be production-ready
- be code-grounded
- stay within project scope
- avoid placeholder code
- avoid TODO-only stubs
- use clear separation of responsibilities
- maintain project consistency

---

## DO NOT

- Do NOT redesign the UI
- Do NOT create cloud dependencies
- Do NOT use backend services
- Do NOT keep the current infinite-feeling multi-capture flow
- Do NOT allow unrestricted numeric OCR matching to keep causing false positives
- Do NOT merge all possible match sources without strategy and confidence rules

---

## DO

- Do keep the current FAB
- Do improve the scan interpretation logic
- Do implement FRONT/BACK/UNKNOWN detection
- Do use FRONT strategy for player name + country
- Do use BACK strategy for strict code matching
- Do improve the multiple-photo camera UX with explicit review and confirmation
- Do keep the architecture clean
- Do reuse existing collection and persistence logic

---

## IMPLEMENTATION EXPECTATIONS

Before coding:
1. Inspect the existing scan pipeline
2. Identify where OCR text is normalized, parsed, and matched
3. Identify the current multi-capture camera flow
4. Reuse as much of the existing project structure as possible

Then implement the refinement directly in the project.

---

## FINAL DELIVERABLE

When finished, provide:
1. Summary of what changed
2. Modified files
3. New files
4. Dependencies added or removed
5. Explanation of the new FRONT/BACK/UNKNOWN logic
6. Explanation of the new multi-capture camera flow
7. Any assumptions made based on the current project structure

---

## FINAL INSTRUCTION

Implement this refinement directly in the existing Flutter project.

Preserve the current visual design, keep the architecture clean, improve scan accuracy, and make the multiple-camera-capture experience intuitive and explicit.