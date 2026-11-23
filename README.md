# EakUI

Custom UI library for Roblox script hubs. Dark glassmorphism style, smooth tweens, and no external dependencies: everything is built with `Instance.new()`.

## Icons

176 built-in icons can be used by name, for example `Icon = "settings"`. All of them are listed with previews in **[ICONS.md](ICONS.md)**.

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
│   │   ├── Assets.lua       Image loader (asset ids, URLs, workspace files)
│   │   ├── Badge.lua        Status pill next to element titles
│   │   ├── Tooltip.lua      Shared hover tooltip
│   │   └── Gui.lua          Protected root ScreenGui
│   ├── Themes/              Theme presets, one file each
│   ├── Components/          One file per element
│   │   ├── Element.lua      Shared base card (icon, badge, tooltip, search)
│   │   ├── Inputs           Button ButtonGroup Toggle Checkbox Slider RangeSlider Stepper
│   │   │                    Input TextArea Dropdown PlayerDropdown Segmented ColorPicker
│   │   │                    Keybind Grid List Swatches
│   │   ├── Tasks & stats    TaskCard StatTiles KeyValue
│   │   ├── Display          Paragraph Image CodeBlock ProgressBar Spinner Notification
│   │   └── Layout           Section Divider Collapsible GroupBox (+Columns) SubTabs
│   ├── KeySystem/           License key screen shown before the hub
│   │   ├── init.lua         Flow: verify, save, success, Wait()
│   │   ├── Format.lua       Key formatting rules (pure, no UI)
│   │   ├── Storage.lua      Remembered key in the executor workspace
│   │   ├── KeyField.lua     Auto-formatting key input + paste + errors
│   │   ├── SuccessView.lua  Plan / expiry details + launch bar
│   │   └── Widgets.lua      Buttons, spinner, checkbox, icons
│   └── Window/
│       ├── init.lua         Window (drag, resize, minimize, visibility)
│       ├── MiniBar.lua      Minimized pill: [logo] brand
│       ├── Topbar.lua
│       ├── SearchBar.lua    Sidebar search (filters the active tab)
│       ├── Profile.lua      Sidebar footer with player avatar + name
│       ├── Tab.lua          Sidebar entry + page header, exposes components
│       ├── Dialog.lua       Modal confirmation dialog
│       └── ToggleButton.lua Floating open/close button
├── dist/EakUI.lua           Built single-file bundle (generated)
├── examples/                Basic, Showcase, Components, AutoClear, KeySystem
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
| Built-in icon name | `"settings"`, `"sword"`, `"map-pin"` (all names are in [ICONS.md](ICONS.md)) |
| Asset id | `123456789` or `"rbxassetid://123456789"` |
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
Tab:Slider({ Title, Desc, Min, Max, Default, Step, Suffix, ShowRange, MinLabel, MaxLabel, Flag, Callback }) -- :Set :Get :SetMinMax
Tab:Input({ Title, Placeholder, Default, Numeric, Live, Flag, Callback })
Tab:Dropdown({ Title, Values, Value, Multi, Search, Flag, Callback })  -- :Set :Refresh :Open :Close
Tab:Keybind({ Title, Value = Enum.KeyCode.F, Flag, Callback, ChangedCallback })
Tab:Grid({ Title, Size = 5, Value = { Vector2 }, Modes, ActionText, StopText,
           Callback(tiles), ActionCallback(running, tiles, mode) })   -- :Get :Set :Clear :SetMode :SetRunning
Tab:Paragraph({ Title, Desc })                                         -- :Set
```

#### Inputs (v1.5)

```lua
Tab:Checkbox({ Title, Desc, Value, Flag, Callback })                          -- :Set :Get :Toggle
Tab:Segmented({ Title, Values = {"A","B","C"}, Value, Flag, Callback })       -- :Set :Get :SetValues   (alias Tab:Radio)
Tab:ColorPicker({ Title, Default = Color3, Transparency, Presets, Flag,
                  Callback(color, transparency) })                            -- :Set :Get :Open :Close
Tab:RangeSlider({ Title, Min, Max, Default = {Min=, Max=}, Step, Suffix, Flag, Callback }) -- :Set :Get :SetMinMax
Tab:Stepper({ Title, Min, Max, Step, Default, Suffix, Flag, Callback })       -- :Set :Get :SetMinMax (hold to repeat)
Tab:TextArea({ Title, Placeholder, Default, Lines = 4, MaxLength, Live, Flag, Callback }) -- :Set :Get :SetPlaceholder
Tab:ButtonGroup({ Buttons = { { Title, Variant = "Primary"|"Secondary"|"Danger", Callback } } }) -- :SetButtonText
Tab:List({ Title, Items = { "A" | { Title, Desc, Icon } }, Multi, Search, MaxHeight, Flag, Callback }) -- :SetItems :Set :Get
Tab:PlayerDropdown({ Title, ExcludeLocal = true, Format = "Both"|"Name"|"DisplayName", Multi, Flag,
                     Callback(player) })                                      -- :GetPlayer :Set :Refresh (auto-updates)
```

#### Tasks & stats (v1.7)

```lua
local job = Tab:TaskCard({
    Unit = "tiles", StartText = "Start Sweep", StopText = "Stop Sweep",
    MiniStatus = "Clearing",                       -- minimized pill: "Clearing · 45%"
    OnStart = function(job)
        local tiles = findTiles()
        job:SetTotal(#tiles)
        for _, tile in ipairs(tiles) do
            if not job:WaitIfPaused() then return end
            breakTile(tile)
            job:Increment()
        end
    end,
    OnComplete = function(job) UI:Notify({ Title = "Done", Type = "Success" }) end,
})                                                 -- :Start :Stop :Resume :Toggle :Reset :GetProgress :GetElapsed

local stats = Tab:StatTiles({ Tiles = { { Title = "Speed", Value = "—", Icon = "activity" } } })
stats:Set("Speed", "120/min")

Tab:KeyValue({ Rows = { { "Version", "1.0.0" }, { "Hotkey", "F6" } } })    -- :Set :Get :Remove :SetRows
Tab:Swatches({ Title = "Accent color", Callback = function(color) UI:SetAccent(color) end })
Tab:SetLive(true)                                  -- pulsing dot on the tab (TaskCard does this for you)
Window:SetStatus("Clearing · 45%")                 -- minimized pill status (TaskCard does this too)
```

`examples/AutoClear.lua` shows a complete screen built from these components.

#### Display

```lua
Tab:Image({ Image = "https://.../banner.png", Height = 140, Title, Desc })    -- :SetImage
Tab:CodeBlock({ Title, Code })                                                -- :SetCode (Copy button)
Tab:ProgressBar({ Title, Value, Max = 100, Percent, Color, Flag })            -- :Set :SetMax :Get
Tab:Spinner({ Title, Desc, Spinning = true })                                 -- :Start :Stop :SetText :SetDone
```

#### Layout

Containers return an object that accepts every component, nested containers included:

```lua
local combat = Tab:Collapsible({ Title = "Combat", Open = true })   -- :Open :Close :SetOpen :ToggleOpen :IsOpen
combat:Toggle({ Title = "Kill Aura" })

local box = Tab:GroupBox({ Title = "Movement" })
box:Slider({ Title = "Speed", Min = 16, Max = 200 })

local left, right = table.unpack(Tab:Columns({ Count = 2, Gap = 8 }))
left:Button({ Title = "Left" })
right:Button({ Title = "Right" })

local sub = Tab:SubTabs({ Tabs = { "Aimbot", "ESP", "Misc" }, Callback = print })
sub:Get("ESP"):Toggle({ Title = "Boxes" })                           -- :Select :GetActive
```

#### Shared element options

Every element also takes these options:

- `Icon` (tinted) or `Image` (full color)
- `IconSize`
- `Badge`: `"NEW"`, `"ON"`, `"OFF"`, `"BETA"`, `"PREMIUM"`, `"VIP"`, `"HOT"`, or `{ Text, Color }`
- `Tooltip`

Every element also has these methods: `:SetTitle`, `:SetDesc`, `:SetIcon`, `:SetBadge`, `:SetTooltip`, `:SetVisible` and `:Destroy`.

### Key system (v1.9)

A license screen shown before the hub. Keys are auto-formatted as you type
(`7a4b28c1` becomes `EAKHUB-7A4B-28C1`), a verified key can be remembered on the
device, and errors shake the field with a message.

```lua
local Key = UI:KeySystem({
    Title = "EakHub",
    Logo = "https://example.com/logo.png",     -- optional, any image source
    Prefix = "EAKHUB", Groups = 3, GroupSize = 4, -- EAKHUB-XXXX-XXXX-XXXX
    -- Format = false,                         -- free-form keys instead

    -- Either a static list...
    Keys = { "EAKHUB-7A4B-28C1-9F3E" },
    -- ...or your own check (runs in its own thread, may HttpGet):
    Verify = function(key)
        local ok = game:HttpGet("https://api.example.com/check?key=" .. key) == "valid"
        if ok then
            return true, { Plan = "Premium", Expires = os.time() + 29 * 86400 }
        end
        return false, "This key is invalid or expired"
    end,

    Discord = "https://discord.gg/xxxx",       -- "Join Discord" button (copies the invite)
    GetKey = "https://link-to-get-a-key",      -- "Get a key" link (copies; or a function)
    Help = "Open a ticket in our Discord.",    -- "Need help?" link (text toast; or a function)

    SaveKey = true,          -- remember the key (file: <Title>/key.txt, or FileName = "...")
    AutoLogin = false,       -- true: verify a saved key immediately
    OnSuccess = function(key, info) end,
    OnClose = function() end,
})

local ok, info = Key:Wait()  -- yields until verified (true, info) or closed (false)
if not ok then return end
```

Shortcut: pass the same table as `KeySystem` to `CreateWindow`. The call
then returns `nil` if the key screen was closed without a valid key.

```lua
local Window = UI:CreateWindow({ Title = "EakHub", KeySystem = { Keys = { "EAKHUB-7A4B-28C1-9F3E" } } })
if not Window then return end
```

`Verify` may return `true, info`, an `info` table, `false, "message"` or just
`"message"`. `info` fields shown on the success screen: `Plan`, `Expires` (unix
time, text, or `true` for lifetime), `User` and `Details = { { "Label", "Value" } }`.

| Option | Default | |
| --- | --- | --- |
| `Heading`, `Subtitle`, `Pill` | "Activate <Title>", ..., "License" | header text (`Pill = false` hides it) |
| `ButtonText`, `VerifyingText` | "Verify & Launch", "Verifying key..." | primary button |
| `DiscordText`, `GetKeyText`, `HelpText` | "Join Discord", "Get a key", "Need help?" | |
| `Placeholder`, `FieldLabel` | from the format, "License key" | |
| `Remember`, `RememberText` | `true`, "Remember key on this device" | checkbox |
| `LaunchText`, `LaunchDelay` | "Loading <Title>...", `1.6` | success bar |
| `Theme`, `Accent`, `Backdrop`, `Closable`, `Notify`, `AllowReset` | | look and behavior |

Methods: `Key:Wait()`, `Key:Verify(key?)`, `Key:Close()`, `Key:IsVerified()`,
`Key:GetSavedKey()`, `Key:ClearSavedKey()`. Fields `Key.Key` and `Key.Info` after success.

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
