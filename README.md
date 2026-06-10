# TicTie Mac

A native **macOS** workpaper-annotation app for tax & accounting
professionals — an independent reimagining of the Windows-only
[TicTie Calculate](https://www.drakesoftware.com/products/tictie-calculate/)
Adobe Acrobat plug-in, built as **its own thing** on Apple's
[PDFKit](https://developer.apple.com/documentation/pdfkit) so it needs **no
Adobe Acrobat installation**.

> Open a PDF workpaper, stamp tickmarks, run an adding-machine tape, tie
> cross-references, sign off as preparer/reviewer, rotate pages and bookmark —
> then save the annotated PDF.

## Why this exists

TicTie Calculate is the leading Acrobat plug-in for the tax/accounting
profession (15,000+ accountants) but ships **Windows only**. This project
brings the same core workflow to the Mac as a standalone, sandbox-friendly
SwiftUI app.

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

## Status & roadmap

This is a v1 that covers the core daily workflow. Natural next steps:
custom tickmark legends, template-driven auto-bookmarking/repagination,
multi-document tie targets, and a signed/notarized distributable build.

## License

See repository. Not affiliated with cPaperless LLC or Drake Software;
"TicTie Calculate" is referenced only to describe the workflow this app
reimplements for macOS.
