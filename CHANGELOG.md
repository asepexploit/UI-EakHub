# Changelog

## 1.10.1 — button layout fixes

- **Fixed:** a button with `AutomaticSize` (small buttons, inspector actions such as the world map's "Walk here") could stretch into a full-width bar after a click. The click ripple was drawn in a layer parented inside the button, so `AutomaticSize` measured the growing circle, widened the button, and fed back until it filled its container. `ClipsDescendants` and a `UISizeConstraint` do not stop this — `AutomaticSize` still measures clipped descendants. The ripple layer is now a sibling of the button (parented to `button.Parent`) that tracks the button's position and size, so the ripple can grow and clip without ever being measured by the button's `AutomaticSize`.
- **Fixed:** the inspector's action buttons ("Copy coords", "Walk here", custom actions) jumped around when clicked. Two causes: the row used a wrapping `UIListLayout`, so any width change re-flowed it and a button could hop to the next line; and swapping a button's text ("Copy coords" → "Copied" → back) changed its width. The action row is now a single, non-wrapping, left-aligned row, and `Parts.Button:SetText` freezes the button to its current pixel width on the first swap, so the row never moves.

## 1.10.0 — world map

- **`Tab:WorldMap(options)`** is a live minimap of a tile world:
  - Draws the fg layer (or bg with fg ghosted) with sky/ground background, grass caps, a surface guide, the player marker, and a hover / pinned outline.
  - Equal neighbouring tiles are merged into one Frame and frames are pooled per row. Unchanged rows are skipped on rescan, so a 100 × 60 world uses a few hundred Instances.
  - Tile inspector shows coordinates, fg / bg item with EMPTY / SKIP / CLEARABLE / BG ITEM tags, and distance from the player, with Copy coords and your own `Actions`.
  - Tile distribution list with bars and SKIP tags. Click a row or a chip to highlight one tile type.
  - Layer switch, zoom (fit, 1.5x, 2x, 3x), Live auto-rescan (only while visible) and a Rescan button.
  - `Preset = "Growblox"` (100 × 60, `fg[row][col]`, skip set `{0, 6, 8, 242}`, surface row 37). Any game works through `GetTile`.
  - API: `Refresh`, `SetLive`, `SetInterval`, `SetLayer`, `SetFilter`, `SetZoom`, `Select`, `ClearSelection`, `GetTile`, `GetCounts`, `Find`, `SetMarkers`.
- `Core/Services` now also exposes `RunService`.
- New `examples/WorldMap.lua`.

## 1.9.0 — key system

- **`UI:KeySystem(config)`** is a license screen to show before the hub:
  - Auto-formatting key field (`EAKHUB-XXXX-XXXX-XXXX`, configurable `Prefix` / `Groups` / `GroupSize`, or `Format = false`), live character count, valid-format check and a Paste button.
  - Verify with a static `Keys` list or your own `Verify(key)` function (can yield for HTTP checks). Errors shake the field with a message and a toast.
  - Remembers the verified key on the device (`SaveKey`, `FileName`, remember checkbox), shows a "Saved key found" banner and supports `AutoLogin`. A saved key that stops working is forgotten.
  - Success screen with plan, expiry, masked key and a launch progress bar.
  - Optional "Join Discord" button, "Get a key" and "Need help?" links.
  - `Key:Wait()` yields until verified or closed.
- **`CreateWindow({ KeySystem = {...} })`** shows the key screen first and returns `nil` if it was closed.
- New `examples/KeySystem.lua`.

## 1.8.0 — 85 new icons (176 total)

- **New categories:**
  - Farming & Harvest (22)
  - Tools & Gathering (9)
  - Automation (14)
  - Economy & Items (10)
  - Blocks & Building (14)
  - Player & Movement (16)
- **New aliases:** `cube`, `wall`, `build`, `break`, `farm`, `plant`, `harvest`, `crop`, `water`, `walk`, `run`, `character`, `tp`, `shop`, `money`, `cash`, `inventory`, `loop`, `auto`, `mine` and `chop`.
- **Changed:** `player` and `teleport` are now real icons. They were previously aliases for `user` and `navigation`. Use `"user"` / `"navigation"` directly if you relied on the old look.
- Added `assets/icons/LICENSE-LUCIDE.txt`. Some icons use Lucide path data (ISC License).

## 1.7.0 — task & stats components

- **`Tab:TaskCard`** is a status, progress and Start/Stop control for any long-running job:
  - State machine: idle, preparing, running, paused, done.
  - Live timer, `86 / 180 tiles` counter with an automatic ETA, and a progress bar with a moving shine.
  - A single main button that switches between Start, Stop, Resume and Run again, plus a reset button.
  - Worker helpers: `:WaitIfPaused()`, `:Increment()` and `:GetProgress()`.
  - Automatically sets the tab live dot and the minimized-pill status.
- **`Tab:StatTiles`**: a row of 2-4 compact stat tiles. Use `:Set(title|index, value)` and `:SetColor`.
- **`Tab:KeyValue`**: a card of label/value rows. Use `:Set`, `:Get`, `:Remove` and `:SetRows`.
- **`Tab:Swatches`**: round color picker dots, useful for an accent-color setting.
- **Slider** now shows `Desc`. `ShowRange = true` adds min/max captions, with optional `MinLabel`/`MaxLabel`.
- **`Tab:SetLive(bool)`** shows a pulsing dot next to the tab name.
- **`Window:SetStatus(text, color)`** shows a live line in the minimized pill (for example `Clearing · 45%`).
- New `examples/AutoClear.lua` is a full hub screen built from these components.

## 1.6.0 — built-in icons

- **91 named icons** usable anywhere an image is accepted (`Icon = "settings"`), plus 30 aliases such as `gear`, `close` and `pin`. Names are case-, space- and underscore-insensitive. See [ICONS.md](ICONS.md).
- Icons are white PNGs hosted in `assets/icons/png/`. They are downloaded on first use, cached in `workspace/EakUI/assets/`, and tinted by the theme.
- New API: `UI:GetIcons()`, `UI:HasIcon(name)` and `UI:SetIconBaseUrl(url)` for self-hosting. `UI:Preload()` also accepts icon names.
- Notifications show a default icon for each `Type` (info, check-circle, alert, x-circle).
- New pipeline: `tools/icons/icons.json` is the single source of truth, and `tools/build_icons.py` generates the PNGs, SVGs, GitHub previews, `src/Core/IconList.lua` and `ICONS.md`.
- Examples now use named icons instead of placeholder asset ids.

## 1.5.2

- **Fix:** clicking a Button made it grow downward. The ripple circle was parented directly to an `AutomaticSize.Y` holder, so the holder expanded to fit it. Ripples now render in a full-size, clipped `RippleLayer`, which never affects AutomaticSize. This fixes Button, ButtonGroup, Stepper and the Grid action button together, and Buttons with a `Desc` still size to their text.

## 1.5.1

- **Fix:** `tab:Button()` failed with "attempt to call an Instance value". The Tab object stored its sidebar button in a field named `Button`, which shadowed the `Tab:Button()` method. The field is now `TabButton`.
- `tools/build.py` now refuses to build if any Tab field shadows a Tab method.

## 1.5.0 — component expansion

- **Inputs:** `Checkbox`, `Segmented` (alias `Radio`), `ColorPicker`, `RangeSlider`, `Stepper`, `TextArea`, `ButtonGroup`, `List`, `PlayerDropdown`.
- **Display:** `Image`, `CodeBlock`, `ProgressBar`, `Spinner`.
- **Layout:** `Collapsible` (alias `Accordion`), `GroupBox`, `Columns`, `SubTabs`. Containers accept every component and can be nested.
- **Every element:** new `Badge` and `Tooltip` options, with `:SetBadge()` and `:SetTooltip()`.
- New internal `Tab:_Child(frame)`, which lets containers reuse the whole component set and stay searchable.

## 1.4.0

- Every image and icon now accepts an asset id, `rbxassetid://`, an **https URL**, or a file in the executor workspace. URLs are downloaded once to `workspace/EakUI/assets/` and loaded with `getcustomasset`.
- New window options `Logo` and `BrandLogo` (plus `BrandLogoSize`).
- Minimizing now shrinks the window into a draggable pill showing `[logo] brand`. Click the pill to restore the window where the pill was.
- The floating toggle button and the topbar use `Logo` when it is set.
- Every element accepts `Icon` (tinted) or `Image` (full color), with `IconSize` and `IconTint`, plus a new `:SetIcon()`.
- Tabs accept `IconTint = false` for full-color icons.
- New `UI:Preload({ urls })` and `UI:GetImage(source)`.

## 1.3.0

- New `Tab:Grid`: a tile picker around the player with a center "ME" tile. Click or drag to select tiles; includes a mode chip, a Start/Stop action button and "Clear selection".

## 1.2.0 — design audit

- Sidebar search that filters elements in the active tab, with an empty state when nothing matches.
- Sidebar profile footer showing the player's avatar, display name and @username.
- Each tab page starts with a header showing its title and optional `Desc`.
- New components: `Tab:Keybind` and `Tab:Divider`.
- New `Window:Dialog`. Closing the window now asks for confirmation (`ConfirmClose = false` turns this off).
- Dropdowns with more than 8 options get a search box (control it with `Search = true/false`).
- Placeholder text contrast raised to at least 4.5:1 in every theme.
- Sidebar widened to 156px.

## 1.1.0

- Split the library into modules under `src/` (Core, Components, Themes, Window).
- Added `tools/build.py` to bundle the modules into `dist/EakUI.lua`.
- Added `UI:GetTheme()`.
- Window close no longer runs twice when clicked repeatedly.

## 1.0.0

- First release: Window, Tab, Button, Toggle, Slider, Input, Dropdown, Paragraph, Section and Notification.
- Five themes, flags, floating toggle button and keybind.
