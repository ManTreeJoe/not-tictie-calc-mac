/*
 * TicTie for Acrobat — folder-level JavaScript add-on
 * ---------------------------------------------------
 * Brings the TicTie Mac workpaper workflow *inside* Adobe Acrobat Pro
 * (macOS and Windows) by adding a "TicTie" submenu under the View menu:
 * tickmarks, an adding-machine calculator tape, preparer/reviewer sign-offs,
 * page rotation, bookmarking and cross-reference "ties".
 *
 * This is a companion to the standalone TicTie Mac app — same workflow, but
 * for people who would rather live in Acrobat. It uses only the documented
 * Acrobat JavaScript API, so there is no native plug-in to compile.
 *
 * Install: copy this file into Acrobat's user "JavaScripts" folder and
 * restart Acrobat. See AcrobatPlugin/README.md (or run install.sh on macOS).
 *
 * Written in ES5 for maximum Acrobat compatibility.
 */

var TicTieAcro = (function () {
    "use strict";

    // --- Colors (the three TicTie annotation colors) ----------------------
    var COLORS = {
        red:   ["RGB", 0.85, 0.18, 0.18],
        green: ["RGB", 0.13, 0.55, 0.27],
        blue:  ["RGB", 0.15, 0.39, 0.84]
    };

    // --- Tickmark palette --------------------------------------------------
    // Prefer the shared legend (TicTie-legend.js, generated from the same
    // tickmark-legend.json the standalone app uses) when it is installed
    // alongside this script; otherwise fall back to this built-in default.
    var DEFAULT_PALETTE = [
        { symbol: "✓", meaning: "Verified / agreed",        color: "green" },
        { symbol: "F",      meaning: "Footed (column adds)",     color: "blue"  },
        { symbol: "C",      meaning: "Cross-footed",             color: "blue"  },
        { symbol: "T",      meaning: "Traced / tied to support", color: "green" },
        { symbol: "A",      meaning: "Agreed to prior year",     color: "green" },
        { symbol: "PY",     meaning: "Per prior-year workpaper", color: "blue"  },
        { symbol: "R",      meaning: "Recomputed",               color: "green" },
        { symbol: "N/A",    meaning: "Not applicable",           color: "red"   },
        { symbol: "?",      meaning: "Open item — follow up",    color: "red"   },
        { symbol: "X",      meaning: "Exception / discrepancy",  color: "red"   }
    ];
    var PALETTE = (typeof TICTIE_LEGEND !== "undefined" &&
                   TICTIE_LEGEND && TICTIE_LEGEND.tickmarks &&
                   TICTIE_LEGEND.tickmarks.length)
        ? TICTIE_LEGEND.tickmarks
        : DEFAULT_PALETTE;

    // Optional override color; when set, tickmarks use it instead of their
    // default. null == use each tickmark's own color.
    var colorOverride = null;

    // Per-page placement cursor so successive stamps don't pile up exactly.
    var placement = { page: -1, step: 0 };

    // --- Helpers ----------------------------------------------------------

    function requireDoc() {
        if (typeof event === "undefined" || event.target === null) {
            app.alert("Open a PDF first.");
            return null;
        }
        return event.target;
    }

    // Returns the crop box as [left, bottom, right, top] in user space.
    function cropBox(doc, page) {
        var b = doc.getPageBox("Crop", page); // [left, top, right, bottom]
        return { left: b[0], top: b[1], right: b[2], bottom: b[3] };
    }

    // Next placement rect near the upper-left of the current page, cascading
    // downward so multiple stamps stay readable. Width/height in points.
    function nextRect(doc, page, width, height) {
        if (placement.page !== page) { placement.page = page; placement.step = 0; }
        var box = cropBox(doc, page);
        var x = box.left + 36 + (placement.step * 6);
        var y = box.top - 48 - (placement.step * 22);
        placement.step = (placement.step + 1) % 18;
        return [x, y, x + width, y - height];
    }

    function colorFor(name) {
        return COLORS[name] || COLORS.red;
    }

    // Parse free-form accounting input ("$1,234.56", "(75.25)") to a Number.
    function parseAmount(text) {
        if (text === null) { return null; }
        var t = ("" + text).replace(/^\s+|\s+$/g, "");
        if (t === "") { return null; }
        var negative = false;
        if (t.charAt(0) === "(" && t.charAt(t.length - 1) === ")") {
            negative = true;
            t = t.substring(1, t.length - 1);
        }
        t = t.replace(/[^0-9.\-]/g, "");
        if (t === "" || t === "-") { return null; }
        var n = parseFloat(t);
        if (isNaN(n)) { return null; }
        return negative ? -n : n;
    }

    function fmt(n) {
        // Grouped, 2-decimal formatting: 1495.2 -> "1,495.20"
        var neg = n < 0;
        var s = Math.abs(n).toFixed(2);
        var parts = s.split(".");
        parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        return (neg ? "-" : "") + parts[0] + "." + parts[1];
    }

    function pad(str, width) {
        var s = "" + str;
        while (s.length < width) { s = " " + s; }
        return s;
    }

    // --- Features ---------------------------------------------------------

    function stampTickmark(index) {
        var doc = requireDoc();
        if (!doc) { return; }
        var mark = PALETTE[index];
        if (!mark) { return; }
        var page = doc.pageNum;
        var colorName = colorOverride || mark.color;
        var width = Math.max(22, mark.symbol.length * 11 + 8);
        var annot = doc.addAnnot({
            page: page,
            type: "FreeText",
            rect: nextRect(doc, page, width, 20),
            contents: mark.symbol,
            textColor: colorFor(colorName),
            textSize: 14,
            alignment: "center",
            richContents: [],
            popupOpen: false,
            fillColor: ["T"],            // transparent background
            author: "TicTie",
            subject: mark.meaning
        });
        annot.borderWidth = 0;
    }

    function setColorOverride(name) {
        colorOverride = name; // "red" | "green" | "blue" | null
        app.alert(name
            ? "Tickmark color set to " + name + "."
            : "Tickmarks will use their default colors.");
    }

    function calculatorTape() {
        var doc = requireDoc();
        if (!doc) { return; }

        var label = app.response({
            cQuestion: "Optional label for this tape:",
            cTitle: "TicTie Calculator Tape",
            cDefault: ""
        });
        if (label === null) { return; } // cancelled

        var entries = [];
        var total = 0;
        while (true) {
            var raw = app.response({
                cQuestion:
                    "Enter an amount and press OK.\n" +
                    "Prefix with \"-\" or use ( ) to subtract.\n" +
                    "Leave blank and press OK to finish.\n\n" +
                    "Running total: " + fmt(total),
                cTitle: "TicTie Calculator Tape" + (label ? " — " + label : ""),
                cDefault: ""
            });
            if (raw === null) { return; }            // cancelled entirely
            if (("" + raw).replace(/^\s+|\s+$/g, "") === "") { break; } // done
            var amount = parseAmount(raw);
            if (amount === null) {
                app.alert("\"" + raw + "\" isn't a number — skipped.");
                continue;
            }
            entries.push(amount);
            total += amount;
        }

        if (entries.length === 0) {
            app.alert("No amounts entered — nothing stamped.");
            return;
        }

        // Render the tape as fixed-width text.
        var lines = [];
        if (label) { lines.push(label); }
        var i;
        for (i = 0; i < entries.length; i++) {
            var v = entries[i];
            lines.push(pad(fmt(Math.abs(v)), 16) + " " + (v < 0 ? "-" : "+"));
        }
        lines.push("----------------");
        lines.push(pad(fmt(total), 16));
        var text = lines.join("\n");

        var page = doc.pageNum;
        var width = 130;
        var height = 14 * lines.length + 10;
        var annot = doc.addAnnot({
            page: page,
            type: "FreeText",
            rect: nextRect(doc, page, width, height),
            contents: text,
            textFont: font.Cour,         // monospaced so columns line up
            textSize: 9,
            textColor: color.black,
            fillColor: ["RGB", 1, 1, 0.86],
            alignment: "left",
            author: "TicTie",
            subject: "Calculator tape (total " + fmt(total) + ")"
        });
        annot.borderWidth = 0.75;
        annot.popupOpen = false;
    }

    function signOff(role) {
        var doc = requireDoc();
        if (!doc) { return; }
        var tag = (role === "reviewer") ? "R" : "P";
        var colorName = (role === "reviewer") ? "red" : "blue";
        var initials = app.response({
            cQuestion: "Your initials:",
            cTitle: tag + " sign-off",
            cDefault: ""
        });
        if (initials === null) { return; }
        initials = ("" + initials).replace(/^\s+|\s+$/g, "").toUpperCase();
        if (initials === "") { app.alert("No initials entered."); return; }

        var text = tag + ": " + initials + " " + util.printd("mm/dd/yy", new Date());
        var page = doc.pageNum;
        var annot = doc.addAnnot({
            page: page,
            type: "FreeText",
            rect: nextRect(doc, page, text.length * 8 + 10, 20),
            contents: text,
            textColor: colorFor(colorName),
            textSize: 11,
            alignment: "left",
            fillColor: ["T"],
            author: "TicTie",
            subject: (role === "reviewer" ? "Reviewer" : "Preparer") + " sign-off"
        });
        annot.borderWidth = 0;
    }

    function rotatePage() {
        var doc = requireDoc();
        if (!doc) { return; }
        var p = doc.pageNum;
        var current = doc.getPageRotation(p);
        doc.setPageRotations(p, p, (current + 90) % 360);
    }

    function bookmarkPage() {
        var doc = requireDoc();
        if (!doc) { return; }
        var p = doc.pageNum;
        var label = app.response({
            cQuestion: "Bookmark name:",
            cTitle: "Add bookmark",
            cDefault: "Page " + (p + 1)
        });
        if (label === null || label === "") { return; }
        var root = doc.bookmarkRoot;
        root.createChild(label, "this.pageNum = " + p + ";", root.children ? root.children.length : 0);
        app.alert("Bookmarked \"" + label + "\".");
    }

    function createTie() {
        var doc = requireDoc();
        if (!doc) { return; }
        var sourcePage = doc.pageNum;
        var targetStr = app.response({
            cQuestion: "Tie this reference to which page number?",
            cTitle: "Create Tie (cross-reference)",
            cDefault: "" + (sourcePage + 1)
        });
        if (targetStr === null) { return; }
        var targetPage = parseInt(targetStr, 10) - 1;
        if (isNaN(targetPage) || targetPage < 0 || targetPage >= doc.numPages) {
            app.alert("Page " + targetStr + " is out of range.");
            return;
        }

        var label = "→ p." + (targetPage + 1);
        var rect = nextRect(doc, sourcePage, label.length * 8 + 8, 18);

        // Visible marker.
        var marker = doc.addAnnot({
            page: sourcePage,
            type: "FreeText",
            rect: rect,
            contents: label,
            textColor: colorFor("blue"),
            textSize: 11,
            alignment: "center",
            fillColor: ["T"],
            author: "TicTie",
            subject: "Tie to page " + (targetPage + 1)
        });
        marker.borderWidth = 0;

        // Clickable link over the same rect.
        var link = doc.addLink(sourcePage, rect);
        link.borderColor = color.transparent;
        link.setAction("this.pageNum = " + targetPage + ";");
    }

    function about() {
        app.alert(
            "TicTie for Acrobat\n\n" +
            "View ▸ TicTie:\n" +
            "  • Stamp Tickmark — drag the stamp to position it\n" +
            "  • Calculator Tape — enter amounts, stamp the tape\n" +
            "  • Preparer / Reviewer Sign-off\n" +
            "  • Rotate Page / Bookmark Page\n" +
            "  • Create Tie — links a marker to another page\n\n" +
            "Companion to the standalone TicTie Mac app.",
            3
        );
    }

    return {
        PALETTE: PALETTE,
        stampTickmark: stampTickmark,
        setColorOverride: setColorOverride,
        calculatorTape: calculatorTape,
        signOff: signOff,
        rotatePage: rotatePage,
        bookmarkPage: bookmarkPage,
        createTie: createTie,
        about: about
    };
})();

// ---------------------------------------------------------------------------
// Menu registration (runs once at Acrobat startup).
// ---------------------------------------------------------------------------
(function registerMenus() {
    var ENABLE_DOC = "event.rc = (event.target !== null);";

    function item(name, parent, exec, enable) {
        app.addMenuItem({
            cName: name,
            cParent: parent,
            cExec: exec,
            cEnable: typeof enable === "undefined" ? ENABLE_DOC : enable,
            nPos: -1
        });
    }

    function separator(parent) {
        app.addMenuItem({ cName: "-", cParent: parent, cExec: "void(0);", nPos: -1 });
    }

    // Top-level "TicTie" submenu under View (reliable across Acrobat versions).
    app.addSubMenu({ cName: "TicTie", cParent: "View", nPos: 0 });

    // Tickmarks submenu.
    app.addSubMenu({ cName: "Stamp Tickmark", cParent: "TicTie", nPos: -1 });
    var i;
    for (i = 0; i < TicTieAcro.PALETTE.length; i++) {
        var m = TicTieAcro.PALETTE[i];
        item(m.symbol + "   " + m.meaning, "Stamp Tickmark",
             "TicTieAcro.stampTickmark(" + i + ");");
    }

    // Tickmark color override submenu.
    app.addSubMenu({ cName: "Tickmark Color", cParent: "TicTie", nPos: -1 });
    item("Default (per tickmark)", "Tickmark Color", "TicTieAcro.setColorOverride(null);", "event.rc = true;");
    item("Red",   "Tickmark Color", "TicTieAcro.setColorOverride('red');",   "event.rc = true;");
    item("Green", "Tickmark Color", "TicTieAcro.setColorOverride('green');", "event.rc = true;");
    item("Blue",  "Tickmark Color", "TicTieAcro.setColorOverride('blue');",  "event.rc = true;");

    separator("TicTie");
    item("Calculator Tape…",  "TicTie", "TicTieAcro.calculatorTape();");
    separator("TicTie");
    item("Preparer Sign-off…", "TicTie", "TicTieAcro.signOff('preparer');");
    item("Reviewer Sign-off…", "TicTie", "TicTieAcro.signOff('reviewer');");
    separator("TicTie");
    item("Rotate Page 90°", "TicTie", "TicTieAcro.rotatePage();");
    item("Bookmark Page…",  "TicTie", "TicTieAcro.bookmarkPage();");
    item("Create Tie…",     "TicTie", "TicTieAcro.createTie();");
    separator("TicTie");
    item("About TicTie…", "TicTie", "TicTieAcro.about();", "event.rc = true;");
})();
