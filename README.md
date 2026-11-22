# EakUI

Custom UI library for Roblox script hubs. Dark glassmorphism style, smooth tweens, and no external dependencies: everything is built with `Instance.new()`.

## Installation

```lua
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/asepexploit/UI-EakHub/main/dist/EakUI.lua"))()
```

Only `dist/EakUI.lua` needs to be hosted. Everything under `src/` is the readable source it is built from.

## Project structure

```
UI-EakHub/
├── src/                     Library source (edit here)
│   ├── init.lua             Public API entry point
│   ├── Core/                Internals, no UI of their own
│   │   ├── State.lua        Shared runtime state (flags, theme, gui, connections)
│   │   ├── Services.lua     Cached Roblox services
│   │   ├── Constants.lua    Sizes, fonts, glass levels, colors
│   │   ├── Utility.lua      Create / Tween / layout / input helpers
│   │   ├── Theme.lua        Theme registry + live re-theming
│   │   ├── Builders.lua     Themed primitives (stroke, label, chevron, ripple)
│   │   ├── Draggable.lua    Mouse + touch dragging
│   │   └── Gui.lua          Protected root ScreenGui
│   ├── Themes/              Theme presets, one file each
│   ├── Components/          One file per element
│   │   ├── Element.lua      Shared base card
│   │   ├── Button.lua  Toggle.lua  Slider.lua  Input.lua  Keybind.lua  Grid.lua
│   │   ├── Dropdown.lua  Paragraph.lua  Section.lua  Divider.lua
│   │   └── Notification.lua
│   └── Window/
│       ├── init.lua         Window (drag, resize, minimize, visibility)
│       ├── Topbar.lua
│       ├── SearchBar.lua    Sidebar search (filters the active tab)
│       ├── Profile.lua      Sidebar footer with player avatar + name
│       ├── Tab.lua          Sidebar entry + page header, exposes components
│       ├── Dialog.lua       Modal confirmation dialog
│       └── ToggleButton.lua Floating open/close button
├── dist/EakUI.lua           Built single-file bundle (generated)
├── examples/                Basic.lua, Showcase.lua
├── tools/build.py           Bundler
├── CHANGELOG.md
└── stylua.toml              Formatter config
```

## Development

1. Edit files in `src/`. Each module starts with `local import = ...` and loads others with `import("Core/Utility")`. A path to a `Folder/init.lua` file is imported as `"Folder"`.
2. Build the bundle (requires Python 3.8+):

   ```
   python tools/build.py
   python tools/build.py --minify   # smaller output
   ```

3. Commit `dist/EakUI.lua` along with the source.

To publish to GitHub on Windows, double-click `tools/publish.bat`. It signs in through your browser, creates the repo on the first run, and pushes changes after that.

Formatting uses [StyLua](https://github.com/JohnnyMorganz/StyLua): `stylua src`.

## API

### Window

```lua
local Window = UI:CreateWindow({
    Title = "MyHub",
    Author = "v1.0",                        -- optional pill next to the title
    Icon = "rbxassetid://...",              -- optional
    Size = UDim2.fromOffset(560, 400),
    MinSize = Vector2.new(420, 300),
    Theme = "Dark",                         -- Dark | Midnight | Rose | Emerald | Light
    Accent = Color3.fromRGB(124, 92, 255),  -- optional override
    ToggleKey = Enum.KeyCode.RightShift,
    ToggleButton = true,
    Search = true,        -- sidebar search
    Profile = true,       -- sidebar avatar footer
    ConfirmClose = true,  -- ask before closing
})

Window:Minimize()  Window:Toggle()  Window:SetVisible(bool)
Window:SetTitle(text)  Window:SetTheme(name)  Window:SelectTab(index | tab)
Window:Dialog({ Title, Content, Buttons = { { Title, Variant = "Primary" | "Danger" | "Secondary", Callback } } })
Window:Destroy()
```

### Images, logo and brand

Any `Icon`, `Image`, `Logo` or `BrandLogo` option accepts:

| Source | Example |
|---|---|
| Asset id | `10723407389` or `"rbxassetid://10723407389"` |
| URL | `"https://example.com/logo.png"` (PNG or JPG) |
| Workspace file | `"EakUI/logo.png"` |

URL and file images need an executor with `writefile` and `getcustomasset`. Downloads are cached in `workspace/EakUI/assets/`.

```lua
local Window = UI:CreateWindow({
    Title = "MyHub",
    Logo = "https://example.com/logo.png",        -- square logo: topbar, floating button, minimized pill
    BrandLogo = "https://example.com/brand.png",  -- wordmark shown next to the logo when minimized
    BrandLogoSize = UDim2.fromOffset(110, 24),
})

Tab:Button({ Title = "Teleport", Icon = "rbxassetid://..." })               -- tinted icon
Tab:Paragraph({ Title = "Update", Desc = "...", Image = "https://.../a.png" }) -- full-color image
UI:Preload({ "https://example.com/logo.png" })                               -- optional warm-up
```

When minimized, the window becomes a small pill showing the logo and brand. Drag the pill anywhere and click it to restore the window at that spot.

### Tab and components

```lua
local Tab = Window:Tab({ Title = "Main", Icon = "rbxassetid://...", Desc = "Shown under the page title" })

Tab:Section("Player")
Tab:Divider()
Tab:Button({ Title, Desc, Color, Callback })
Tab:Toggle({ Title, Desc, Value, Flag, Callback })                     -- :Set :Get :Toggle
Tab:Slider({ Title, Min, Max, Default, Step, Suffix, Flag, Callback }) -- :Set :Get :SetMinMax
Tab:Input({ Title, Placeholder, Default, Numeric, Live, Flag, Callback })
Tab:Dropdown({ Title, Values, Value, Multi, Search, Flag, Callback })  -- :Set :Refresh :Open :Close
Tab:Keybind({ Title, Value = Enum.KeyCode.F, Flag, Callback, ChangedCallback })
Tab:Grid({ Title, Size = 5, Value = { Vector2 }, Modes, ActionText, StopText,
           Callback(tiles), ActionCallback(running, tiles, mode) })   -- :Get :Set :Clear :SetMode :SetRunning
Tab:Paragraph({ Title, Desc })                                         -- :Set
```

Every element also has `:SetTitle`, `:SetDesc`, `:SetVisible` and `:Destroy`.

### Notifications, themes and flags

```lua
UI:Notify({ Title = "Done", Content = "Saved", Type = "Success", Duration = 4 })
UI:SetTheme("Midnight")
UI:SetAccent(Color3.fromRGB(255, 140, 0))
print(UI.Flags.Enabled.Value)
```

## Adding things

- **New component:** create `src/Components/MyThing.lua` that returns `function(tab, options) ... end`, build on `Element.new`, then register it in the `Components` table in `src/Window/Tab.lua`.
- **New theme:** copy `src/Themes/Dark.lua`, change the colors, and list the new file in `src/Themes/init.lua`.
