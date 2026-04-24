# SKILL — STICKER SCAN FEATURE (FLOATING ACTION BUTTON INTEGRATION)

## CONTEXT

This is an existing Flutter application for collecting World Cup stickers. The app already has:

- A defined UI/UX
- A local database (likely Hive)
- Existing sticker models and collection logic
- A Floating Action Button (+) already present in the UI

Your task is to implement a **new scanning feature** integrated into the existing app WITHOUT breaking or redesigning anything.

IMPORTANT:
- Do NOT change existing UI layouts
- Do NOT redesign screens
- Do NOT modify styles, themes, spacing, or typography
- Do NOT refactor unrelated parts of the app
- Only ADD the new functionality cleanly
- Respect the current architecture (Clean Architecture if present)

---

## GOAL

Enhance the existing "+" Floating Action Button so that the user can:

1. Take one or multiple photos using the camera
2. Select one or multiple images from the gallery
3. Process those images using OCR (local, on-device)
4. Detect the sticker identifier (number/code)
5. Match it against the local sticker database
6. Automatically add the sticker to the user's collection

---

## CRITICAL REQUIREMENT — STICKER NUMBERING SYSTEM

The current app uses a numeric system (1–960), but this is NOT reliable.

You MUST:

1. Research and understand the sticker numbering system used in the **FIFA World Cup Qatar 2022 album**
   - Stickers were NOT purely numeric
   - They included structured codes like:
     - Team codes (e.g., ARG, BRA, FRA)
     - Categories (e.g., FW, GK, etc.)
     - Numbers (e.g., 01–20)
   - Some stickers used composite identifiers like:
     - "ARG-01"
     - "FWC-12"
     - etc.

2. Adapt the current app to support a **flexible sticker identification system**, not only numeric

3. Ensure compatibility with:
   - Current seed data (1–960)
   - Future structured IDs (like Qatar 2022 format)

4. Update or extend the matching logic so it can handle:
   - Pure numbers
   - Alphanumeric codes
   - Mixed formats

5. DO NOT break existing data — extend it

---

## FUNCTIONAL FLOW

### Step 1 — FAB Interaction

Use the EXISTING Floating Action Button (+).

On tap:
- Open a bottom sheet / modal (use existing UI patterns)
- Provide options:
  - Take photo
  - Take multiple photos
  - Pick single image from gallery
  - Pick multiple images from gallery

Do NOT redesign the button.

---

### Step 2 — Image Acquisition

Use a reliable Flutter solution:
- Prefer `image_picker` unless the project already uses `camera`

Support:
- Single image
- Multiple images

If multiple camera capture is not directly supported:
- Loop capture until user finishes

---

### Step 3 — Temporary Storage

If needed:
- Store images in temporary directory
- Clean up after processing

---

### Step 4 — OCR Processing (LOCAL ONLY)

Use:
- `google_mlkit_text_recognition`

For each image:
1. Extract raw text
2. Normalize it:
   - Trim
   - Uppercase
   - Remove noise
   - Fix common OCR mistakes:
     - O → 0
     - I → 1
     - S → 5
     - B → 8 (only if safe)

---

### Step 5 — TEXT PARSING

Create a dedicated parsing layer.

Responsibilities:
- Extract possible sticker identifiers from OCR text
- Support:
  - Pure numbers (e.g., "123")
  - Team codes (e.g., "ARG")
  - Combined IDs (e.g., "ARG-12", "BRA-PL-01")

Use regex and heuristics.

DO NOT mix parsing logic inside UI.

---

### Step 6 — MATCHING LOGIC

You MUST:

- Reuse existing sticker data (Hive or equivalent)
- Identify how stickers are stored:
  - id
  - code
  - globalNumber
  - other fields

Implement a flexible matcher:
- Match by number
- Match by code
- Match by normalized string

If multiple candidates:
- choose best match
- or mark as ambiguous

---

### Step 7 — ADD TO COLLECTION

CRITICAL:

DO NOT create new logic if one already exists.

You MUST:
- Find existing use case / provider / notifier / repository responsible for adding stickers
- Reuse it

For each detected sticker:
- If found → add
- If already owned → follow existing logic
- If not found → mark as notFound

---

### Step 8 — BATCH PROCESSING

Support multiple images.

Requirements:
- Process images sequentially or in a controlled queue
- Do NOT block UI
- Handle per-image errors
- Do NOT stop entire batch if one fails

---

### Step 9 — USER FEEDBACK

Provide feedback using existing UI patterns:

At the end:
- Show summary:
  - total processed
  - added
  - already owned
  - not found
  - failed OCR

Use:
- Snackbar / Dialog / Bottom Sheet (consistent with app)

---

## ARCHITECTURE REQUIREMENTS (VERY IMPORTANT)

Follow Clean Architecture principles.

### Suggested layers:

#### Presentation
- Trigger from FAB
- UI interactions
- State management (reuse existing: Riverpod, Bloc, etc.)

#### Domain
- Use cases:
  - ScanStickersFromImages
  - ParseStickerText
  - MatchSticker
  - AddStickerToCollection

#### Data
- OCR service
- Image input service
- Local data source (Hive)

---

### Suggested components

- StickerScanCoordinator
- StickerImageInputService
- StickerOcrService
- StickerTextParser
- StickerMatcherService
- BatchStickerScanResult
- SingleStickerScanResult

Adapt naming to project conventions.

---

## RESULT MODELS

Create clear models:

SingleStickerScanResult:
- imagePath
- rawText
- normalizedText
- detectedIdentifier
- matchedSticker
- status
- message

BatchStickerScanResult:
- total
- added
- alreadyOwned
- notFound
- failed
- items

Use enums:
- added
- alreadyExists
- notFound
- ocrFailed
- error

---

## ERROR HANDLING

Handle:
- camera permissions
- gallery permissions
- user cancel
- OCR failure
- parsing failure
- no match found

No crashes allowed.

---

## PERFORMANCE

- Avoid blocking main thread
- Process images efficiently
- Clean temp files
- Avoid memory leaks

---

## WHAT YOU MUST NOT DO

- Do NOT redesign UI
- Do NOT break existing features
- Do NOT duplicate logic
- Do NOT introduce backend
- Do NOT use cloud AI
- Do NOT hardcode sticker IDs

---

## WHAT YOU MUST DO

- Fully implement the feature
- Integrate into existing project
- Respect architecture
- Reuse existing logic
- Keep code clean and maintainable

---

## FINAL TASK

Implement the full feature directly in the project.

At the end, provide:

1. List of modified files
2. List of new files
3. Explanation of the implemented flow
4. Dependencies added
5. Any assumptions made about the project

---

## FINAL INSTRUCTION

Before coding:
- Analyze the existing project structure
- Identify how stickers are stored and added
- Extend, do NOT replace

Then implement the feature completely.