# TicTie for Acrobat (plug-in)

The same TicTie workpaper workflow, but **inside Adobe Acrobat Pro** — for when
you love Acrobat too much to leave it. It adds a **`View ▸ TicTie`** menu with
tickmarks, an adding-machine calculator tape, sign-offs, page rotation,
bookmarking and cross-reference "ties".

This is a **folder-level JavaScript** add-on. It uses only Adobe's documented
Acrobat JavaScript API, so there's **nothing to compile** and it works in
Acrobat Pro on **both macOS and Windows**. (It's the companion to the
standalone [TicTie Mac](../README.md) app — pick whichever fits your day.)

## Requirements

- **Adobe Acrobat Pro** (DC / subscription, or 2017/2020). The free Acrobat
  Reader does not run folder-level scripts or allow annotations/saving.

## Install (macOS)

```bash
cd AcrobatPlugin
./install.sh            # copies TicTie.js into Acrobat's JavaScripts folder
```

Then **quit and reopen Acrobat**. You'll find the menu under **View ▸ TicTie**.

To remove it later: `./install.sh --uninstall`.

### Manual install (macOS or Windows)

Copy `TicTie.js` into Acrobat's **user JavaScripts** folder and restart Acrobat:

- **macOS:** `~/Library/Application Support/Adobe/Acrobat/<version>/JavaScripts/`
  (`<version>` is `DC`, `2020`, `24`, `25`, …)
- **Windows:** `%APPDATA%\Adobe\Acrobat\<version>\JavaScripts\`

## Using it

Open a PDF workpaper, then use **View ▸ TicTie**:

| Menu item | What it does |
| --------- | ------------ |
| **Stamp Tickmark ▸ …** | Drops the chosen tickmark on the current page. Drag it where you want it. |
| **Tickmark Color** | Override the color of stamped tickmarks (or use each mark's default). |
| **Calculator Tape…** | Prompts for amounts (use `-` or `(…)` to subtract), then stamps a monospaced adding-machine tape with the running total. |
| **Preparer / Reviewer Sign-off…** | Stamps `P: JD 06/10/26` / `R: AB 06/10/26`. |
| **Rotate Page 90°** | Rotates the current page clockwise. |
| **Bookmark Page…** | Adds a PDF bookmark to the current page. |
| **Create Tie…** | Adds a clickable marker on the current page that jumps to another page. |

Use Acrobat's own **Save** (⌘S) to write the annotated PDF, and **Edit ▸ Undo**
to back out a stamp.

## Shared tickmark legend

The tickmark palette is defined once in
[`Sources/TicTieCore/Resources/tickmark-legend.json`](../Sources/TicTieCore/Resources/tickmark-legend.json)
and used by **both** the standalone app and this plug-in.

- The app reads (and lets you edit) a copy at
  `~/Library/Application Support/TicTie/tickmark-legend.json`
  (**Tickmarks ▸ Edit Legend…**).
- For Acrobat, `generate-legend.sh` turns that JSON into `TicTie-legend.js`,
  which `install.sh` installs next to `TicTie.js`. After editing the legend,
  re-run:

  ```bash
  ./generate-legend.sh && ./install.sh
  ```

If `TicTie-legend.js` isn't present, the plug-in falls back to a built-in
default palette.

## Notes & differences vs. the standalone app

- Acrobat's scripting API can't capture an arbitrary click point on the page,
  so stamps land near the top-left and are **draggable** into place (Acrobat
  annotations move freely). The standalone app supports click-to-place.
- Everything here maps 1:1 to the standalone app's features, so a workpaper
  annotated in one reads naturally in the other.

## Trust / security

Folder-level scripts only register a menu and operate on the document you
explicitly open and act on. If your organization restricts Acrobat JavaScript
(Enhanced Security), an admin may need to allow this folder script. The file is
plain, readable JavaScript — review `TicTie.js` before installing.

> Not affiliated with cPaperless LLC or Drake Software. "TicTie Calculate" is
> referenced only to describe the workflow this add-on reimplements.
