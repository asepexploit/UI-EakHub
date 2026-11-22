# Changelog

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
