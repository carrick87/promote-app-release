# Web feature series (default for platform = Web)

One 1920×1080 image per feature plus a cover, composited from **real** browser captures. This replaced collage posters and AI-redrawn UI, which reviewers found unprofessional (mismatched crops, label pills over the UI, unreadable shrunken tables, invented screens).

Build with [`build-feature-series.ps1`](build-feature-series.ps1) and a JSON spec (see [`feature-series.example.json`](feature-series.example.json)). Windows PowerShell + `System.Drawing`; no packages added to the app.

## Before building: design review (recommended)

If an earlier poster exists or the user says the images look unprofessional, ask a strong reviewer model (subagent) to critique it and return: top problems, a layout spec, and per-feature copy (title ≤ 5 words, body ≤ 18 words, 3 bullets). Do not edit files in the review step.

## Layout spec

| Element | Rule |
|---|---|
| Canvas | 1920×1080, background `#F4F6F9` |
| Margins | 96 px left/right, 88 px top, 72 px bottom; 12-col grid, 24 px gutters |
| Text column | x 96, width 560 (cols 1–4) |
| Screenshot frame | x 680, width 1144 (cols 5–12), vertically centred in y 88–912 |
| Eyebrow | 20 px SemiBold, uppercase, tracked, brand colour — `FEATURE 03 · GROUPS` |
| Title | 60 px SemiBold, ink; ≤ 5 words; reword if it leaves a one-word orphan line |
| Body | 28 px Regular, `#3D4A5C`, line height 41 |
| Bullets | 24 px Regular; numbered navy badge when it maps to a marker, 12 px brand square otherwise |
| Frame | 40 px browser bar `#EEF1F5` with three dots and URL pill, radius 12, 1 px `#DDE2E9` border, soft navy shadow |
| Highlight | Dim the rest of the screenshot with ~60 % white; one 2 px brand outline (radius 8, padding 6) per region; at most 2 regions |
| Markers | 36 px navy circles, white mono numbers, max 3; numbers match the bullets; **no text on the screenshot** |
| Footer | 1 px rule at y 952; icon 28 px + `Product · vX.Y.Z` left; `Company · Internal   03 / 08` right |
| Cover | Icon, eyebrow, product name (84 px), one-line subtitle, `NEW IN X.Y.Z` with 3 bullets, undimmed hero screenshot |

Use the app's own fonts (download open-licence TTFs to a temp folder if not installed — never add them to the project) and the app's palette only. No gradients, glass, emoji, stock imagery, arrows, or label pills.

## Capturing screenshots (browser MCP)

- Capture at the viewport's native 1× (e.g. 1404 or 1440 wide). Keep **one crop width for the whole series** (e.g. 1254 px → ~0.91 scale) so zoom is consistent, and never upscale more than ~1.2×.
- Do **not** use `Emulation.setDeviceMetricsOverride` with `deviceScaleFactor: 2` or `Page.captureScreenshot` `clip.scale: 2` in the Cursor browser — output comes back tiled. CSS `zoom` changes the layout. Stay at 1×.
- Before each capture, in one `Runtime.evaluate` immediately followed by the screenshot (pages can re-render between calls):
  - remove the dev overlay: `document.querySelectorAll('nextjs-portal').forEach(e=>e.remove())`
  - hide scrollbars: inject `*{scrollbar-width:none!important}*::-webkit-scrollbar{display:none!important}`
  - mask personal data (emails → `staff1@company…`) and drop unrelated error banners — for the image only; mention it in the newsletter
  - scroll inner lists so they start on a whole row and the highlighted rows are fully visible
- Drive real states via URL params where possible (e.g. repeat `group=` for multi-select) and type into filters to show them in use.
- Measure element boxes with `getBoundingClientRect()` at the **capture** viewport size and put them in the spec (outline/marker coords are source-pixel coordinates).
- If a screen errors (e.g. a report timeout), leave it out and footnote it — never fake its data.

## Feature list

Derive from README Version History (whole app when the user asks for all features). Typical web set: overview/header, primary filter dimension, grouping/selection, filters & search, totals, table controls (sort/filter/reorder/paging), export, access/sign-in. Copy is plain and factual: no exclamation marks, no claims the app does not make.

## Spec gotchas (PowerShell)

- Variables are case-insensitive: `$ink` overwrites `$INK`.
- Save scripts as UTF-8 **with BOM** or use `[char]0x00B7` for `·`; otherwise it renders as `Â·`.
- Loading Regular and Bold of the same family into one `PrivateFontCollection` can render Regular as bold — load only the weights you use, with distinct family names (Regular, Medium, SemiBold).
- `| Select -First N` on the build command stops the script early.

## Outputs

`marketing/<VERSION>/features/<Product>-<VER>-feature-00-cover.png` … `-feature-08-<slug>.png`, copied to `~/Desktop/<Product>-<VER>-features/`. Embed them in `NEWSLETTER.md` in order and list the source capture for each.
