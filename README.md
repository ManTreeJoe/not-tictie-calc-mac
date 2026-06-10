# TicTie

A macOS workpaper-annotation toolkit for tax & accounting professionals — an
independent reimagining of the Windows-only
[TicTie Calculate](https://www.drakesoftware.com/products/tictie-calculate/)
Adobe Acrobat plug-in.

> Open a PDF workpaper, stamp tickmarks, run an adding-machine tape, tie
> cross-references, sign off as preparer/reviewer, rotate pages and bookmark —
> then save the annotated PDF.

It ships **two ways** so you can use whichever fits your day:

1. **TicTie Mac** — a native standalone macOS app built on Apple's
   [PDFKit](https://developer.apple.com/documentation/pdfkit). Needs **no Adobe
   Acrobat installation**. (This repo's Swift package.)
2. **TicTie for Acrobat** — a folder-level JavaScript add-on that puts the same
   workflow on a **`View ▸ TicTie`** menu **inside Adobe Acrobat Pro** (macOS &
   Windows), for when you love Acrobat too much to leave it. No native plug-in
   to compile. See [`AcrobatPlugin/`](AcrobatPlugin/README.md).

The two share the same tickmark legend, tape format and sign-off style, so a
workpaper annotated in one reads naturally in the other. The tickmark legend
lives in one canonical, editable file
([`Sources/TicTieCore/Resources/tickmark-legend.json`](Sources/TicTieCore/Resources/tickmark-legend.json))
that both products read — see [Shared tickmark legend](#shared-tickmark-legend).

## Why this exists

TicTie Calculate is the leading Acrobat plug-in for the tax/accounting
profession (15,000+ accountants) but ships **Windows only**. This project
brings the same core workflow to the Mac — both as a standalone app and as an
Acrobat Pro add-on.

---

## TicTie Mac (standalone app)

## Feature mapping

| TicTie Calculate (Windows / Acrobat) | TicTie Mac (this app)                              |
| ------------------------------------ | -------------------------------------------------- |
| Customizable tickmarks, 3 colors     | Tickmark palette (10 marks) in red / green / blue  |
| Digital calculator tape              | Adding-machine tape with running total, stamped on the page |
| Hyperlinked cross-references ("tie")  | Tie tool — click target, then place a clickable marker that jumps to it |
| Preparer / reviewer sign-offs        | One-click sign-off stamps (`P: JD 06/10/26`)       |
| Single-click page rotation           | Rotate the current page 90° (toolbar / panel)      |
| Bookmarking & repagination           | Add PDF outline bookmarks; jump to them            |

## Architecture

The code is split so the business logic is fully testable without any UI:

```
Sources/
  TicTieCore/        Pure Swift — no PDFKit/SwiftUI. Builds & tests anywhere.
    CalculatorTape   Adding-machine engine (entries, running total, rendering)
    Tickmark         Tickmark + color models, default palette
    SignOff          Preparer/reviewer sign-off model
    Formatting       Amount parsing & grouped/fixed-fraction formatting
  TicTieMac/         SwiftUI + PDFKit app (macOS 13+)
    AppModel         Observable app state + tool/placement actions
    PDF/             PDFDocumentController, AnnotationFactory
    Views/           PDF viewer + inspector panels
Tests/
  TicTieCoreTests/   Unit tests for the core engine
```

All Apple-only code is guarded with `#if canImport(SwiftUI)` /
`#if canImport(PDFKit)`, so `TicTieCore` and its tests also build on Linux for
CI.

## Build & run (macOS 13+)

With the Swift toolchain that ships with Xcode 15+:

```bash
# Run the core engine unit tests
swift test

# Launch the app
swift run TicTieMac
```

Or open the package in Xcode (`File ▸ Open…` → select the repo folder, or
`xed .`), pick the **TicTieMac** scheme and press ▶. To produce a
double-clickable `.app` bundle, archive the **TicTieMac** scheme from Xcode.

## Using it

1. **Open** a PDF workpaper (toolbar ▸ Open, or the empty-state button).
2. Pick a tool in the left inspector — it arms a crosshair cursor:
   - **Tickmarks**: choose a color + glyph, then click the page.
   - **Calculator Tape**: type amounts, press **+** / **−** to build the tape,
     then **Stamp on Page** and click where it should land.
   - **Sign-offs**: enter your initials, click **Preparer**/**Reviewer**, then
     click the page.
   - **Tie**: click the target location, then click where the reference marker
     goes — the marker becomes a clickable link to the target.
3. **Rotate** / **Bookmark** the current page from the inspector or toolbar.
4. **Save** (⌘-equivalent toolbar button) to write the annotated PDF.
   `⌘Z` undoes placements and rotations.

## Shared tickmark legend

The tickmark palette is defined once in
[`Sources/TicTieCore/Resources/tickmark-legend.json`](Sources/TicTieCore/Resources/tickmark-legend.json)
and consumed by both products:

- **App:** on first run it copies the default legend to
  `~/Library/Application Support/TicTie/tickmark-legend.json`, then loads it.
  Use **Tickmarks ▸ Edit Legend…** to open it in Finder and **Reload** to pick
  up edits. The file is plain JSON:

  ```json
  { "tickmarks": [ { "symbol": "✓", "meaning": "Verified / agreed", "color": "green" } ] }
  ```

  (`color` is `red`, `green` or `blue`.)
- **Acrobat plug-in:** `AcrobatPlugin/generate-legend.sh` compiles the same
  JSON into `TicTie-legend.js`, which `install.sh` installs alongside
  `TicTie.js`.

## Status & roadmap

This is a v1 that covers the core daily workflow. Natural next steps:
template-driven auto-bookmarking/repagination, multi-document tie targets,
and a signed/notarized distributable build.

## License

See repository. Not affiliated with cPaperless LLC or Drake Software;
"TicTie Calculate" is referenced only to describe the workflow this app
reimplements for macOS.
