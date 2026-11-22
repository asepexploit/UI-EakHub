# EakUI Icons

EakUI ships **91 built-in icons** that you can use by name anywhere an image is accepted.

```lua
Window:Tab({ Title = "Settings", Icon = "settings" })
Tab:Button({ Title = "Teleport", Icon = "map-pin" })
Tab:Toggle({ Title = "God Mode", Icon = "shield" })
UI:Notify({ Title = "Saved", Icon = "check-circle" })
```

## How it works

- Icons are white line icons on a 24px grid (Lucide style). Element and tab icons are tinted by the theme automatically.
- The first time an icon is used, it is downloaded from this repository into `workspace/EakUI/assets/` and reused after that.
- This needs an executor with `writefile` and `getcustomasset`, which is the same requirement as URL images.
- Asset IDs (`rbxassetid://...`), URLs and workspace files still work exactly as before.
- `UI:GetIcons()` returns every name grouped by category.
- `UI:SetIconBaseUrl(url)` loads icons from your own host instead of this repository.
- `UI:Preload({ "settings", "sword" })` downloads icons ahead of time so they appear instantly.

## Names are case-insensitive

`"Settings"`, `"settings"` and `"SETTINGS"` all work. Spaces and underscores become dashes, so `"map pin"` and `"map_pin"` both resolve to `"map-pin"`.

## Icons

### Interface (19)

|   |   |   |   |   |   |
|---|---|---|---|---|---|
| <img src="assets/icons/preview/home.svg" width="28" height="28" alt="home"><br>`home` | <img src="assets/icons/preview/settings.svg" width="28" height="28" alt="settings"><br>`settings` | <img src="assets/icons/preview/sliders.svg" width="28" height="28" alt="sliders"><br>`sliders` | <img src="assets/icons/preview/menu.svg" width="28" height="28" alt="menu"><br>`menu` | <img src="assets/icons/preview/search.svg" width="28" height="28" alt="search"><br>`search` | <img src="assets/icons/preview/x.svg" width="28" height="28" alt="x"><br>`x` |
| <img src="assets/icons/preview/check.svg" width="28" height="28" alt="check"><br>`check` | <img src="assets/icons/preview/plus.svg" width="28" height="28" alt="plus"><br>`plus` | <img src="assets/icons/preview/minus.svg" width="28" height="28" alt="minus"><br>`minus` | <img src="assets/icons/preview/chevron-right.svg" width="28" height="28" alt="chevron-right"><br>`chevron-right` | <img src="assets/icons/preview/chevron-down.svg" width="28" height="28" alt="chevron-down"><br>`chevron-down` | <img src="assets/icons/preview/arrow-left.svg" width="28" height="28" alt="arrow-left"><br>`arrow-left` |
| <img src="assets/icons/preview/arrow-right.svg" width="28" height="28" alt="arrow-right"><br>`arrow-right` | <img src="assets/icons/preview/external-link.svg" width="28" height="28" alt="external-link"><br>`external-link` | <img src="assets/icons/preview/refresh.svg" width="28" height="28" alt="refresh"><br>`refresh` | <img src="assets/icons/preview/filter.svg" width="28" height="28" alt="filter"><br>`filter` | <img src="assets/icons/preview/grid.svg" width="28" height="28" alt="grid"><br>`grid` | <img src="assets/icons/preview/list.svg" width="28" height="28" alt="list"><br>`list` |
| <img src="assets/icons/preview/more.svg" width="28" height="28" alt="more"><br>`more` |   |   |   |   |   |

### User & Security (14)

|   |   |   |   |   |   |
|---|---|---|---|---|---|
| <img src="assets/icons/preview/user.svg" width="28" height="28" alt="user"><br>`user` | <img src="assets/icons/preview/users.svg" width="28" height="28" alt="users"><br>`users` | <img src="assets/icons/preview/user-plus.svg" width="28" height="28" alt="user-plus"><br>`user-plus` | <img src="assets/icons/preview/crown.svg" width="28" height="28" alt="crown"><br>`crown` | <img src="assets/icons/preview/shield.svg" width="28" height="28" alt="shield"><br>`shield` | <img src="assets/icons/preview/shield-check.svg" width="28" height="28" alt="shield-check"><br>`shield-check` |
| <img src="assets/icons/preview/lock.svg" width="28" height="28" alt="lock"><br>`lock` | <img src="assets/icons/preview/unlock.svg" width="28" height="28" alt="unlock"><br>`unlock` | <img src="assets/icons/preview/key.svg" width="28" height="28" alt="key"><br>`key` | <img src="assets/icons/preview/eye.svg" width="28" height="28" alt="eye"><br>`eye` | <img src="assets/icons/preview/eye-off.svg" width="28" height="28" alt="eye-off"><br>`eye-off` | <img src="assets/icons/preview/bell.svg" width="28" height="28" alt="bell"><br>`bell` |
| <img src="assets/icons/preview/star.svg" width="28" height="28" alt="star"><br>`star` | <img src="assets/icons/preview/heart.svg" width="28" height="28" alt="heart"><br>`heart` |   |   |   |   |

### Combat & Game (13)

|   |   |   |   |   |   |
|---|---|---|---|---|---|
| <img src="assets/icons/preview/sword.svg" width="28" height="28" alt="sword"><br>`sword` | <img src="assets/icons/preview/crosshair.svg" width="28" height="28" alt="crosshair"><br>`crosshair` | <img src="assets/icons/preview/target.svg" width="28" height="28" alt="target"><br>`target` | <img src="assets/icons/preview/zap.svg" width="28" height="28" alt="zap"><br>`zap` | <img src="assets/icons/preview/flame.svg" width="28" height="28" alt="flame"><br>`flame` | <img src="assets/icons/preview/skull.svg" width="28" height="28" alt="skull"><br>`skull` |
| <img src="assets/icons/preview/bomb.svg" width="28" height="28" alt="bomb"><br>`bomb` | <img src="assets/icons/preview/trophy.svg" width="28" height="28" alt="trophy"><br>`trophy` | <img src="assets/icons/preview/gem.svg" width="28" height="28" alt="gem"><br>`gem` | <img src="assets/icons/preview/coins.svg" width="28" height="28" alt="coins"><br>`coins` | <img src="assets/icons/preview/gift.svg" width="28" height="28" alt="gift"><br>`gift` | <img src="assets/icons/preview/package.svg" width="28" height="28" alt="package"><br>`package` |
| <img src="assets/icons/preview/rocket.svg" width="28" height="28" alt="rocket"><br>`rocket` |   |   |   |   |   |

### World & Movement (9)

|   |   |   |   |   |   |
|---|---|---|---|---|---|
| <img src="assets/icons/preview/map.svg" width="28" height="28" alt="map"><br>`map` | <img src="assets/icons/preview/map-pin.svg" width="28" height="28" alt="map-pin"><br>`map-pin` | <img src="assets/icons/preview/compass.svg" width="28" height="28" alt="compass"><br>`compass` | <img src="assets/icons/preview/navigation.svg" width="28" height="28" alt="navigation"><br>`navigation` | <img src="assets/icons/preview/globe.svg" width="28" height="28" alt="globe"><br>`globe` | <img src="assets/icons/preview/mountain.svg" width="28" height="28" alt="mountain"><br>`mountain` |
| <img src="assets/icons/preview/sun.svg" width="28" height="28" alt="sun"><br>`sun` | <img src="assets/icons/preview/moon.svg" width="28" height="28" alt="moon"><br>`moon` | <img src="assets/icons/preview/cloud.svg" width="28" height="28" alt="cloud"><br>`cloud` |   |   |   |

### Actions (14)

|   |   |   |   |   |   |
|---|---|---|---|---|---|
| <img src="assets/icons/preview/play.svg" width="28" height="28" alt="play"><br>`play` | <img src="assets/icons/preview/pause.svg" width="28" height="28" alt="pause"><br>`pause` | <img src="assets/icons/preview/stop.svg" width="28" height="28" alt="stop"><br>`stop` | <img src="assets/icons/preview/save.svg" width="28" height="28" alt="save"><br>`save` | <img src="assets/icons/preview/download.svg" width="28" height="28" alt="download"><br>`download` | <img src="assets/icons/preview/upload.svg" width="28" height="28" alt="upload"><br>`upload` |
| <img src="assets/icons/preview/trash.svg" width="28" height="28" alt="trash"><br>`trash` | <img src="assets/icons/preview/copy.svg" width="28" height="28" alt="copy"><br>`copy` | <img src="assets/icons/preview/edit.svg" width="28" height="28" alt="edit"><br>`edit` | <img src="assets/icons/preview/send.svg" width="28" height="28" alt="send"><br>`send` | <img src="assets/icons/preview/link.svg" width="28" height="28" alt="link"><br>`link` | <img src="assets/icons/preview/log-out.svg" width="28" height="28" alt="log-out"><br>`log-out` |
| <img src="assets/icons/preview/power.svg" width="28" height="28" alt="power"><br>`power` | <img src="assets/icons/preview/undo.svg" width="28" height="28" alt="undo"><br>`undo` |   |   |   |   |

### Info & System (22)

|   |   |   |   |   |   |
|---|---|---|---|---|---|
| <img src="assets/icons/preview/info.svg" width="28" height="28" alt="info"><br>`info` | <img src="assets/icons/preview/alert.svg" width="28" height="28" alt="alert"><br>`alert` | <img src="assets/icons/preview/help.svg" width="28" height="28" alt="help"><br>`help` | <img src="assets/icons/preview/check-circle.svg" width="28" height="28" alt="check-circle"><br>`check-circle` | <img src="assets/icons/preview/x-circle.svg" width="28" height="28" alt="x-circle"><br>`x-circle` | <img src="assets/icons/preview/clock.svg" width="28" height="28" alt="clock"><br>`clock` |
| <img src="assets/icons/preview/calendar.svg" width="28" height="28" alt="calendar"><br>`calendar` | <img src="assets/icons/preview/bar-chart.svg" width="28" height="28" alt="bar-chart"><br>`bar-chart` | <img src="assets/icons/preview/activity.svg" width="28" height="28" alt="activity"><br>`activity` | <img src="assets/icons/preview/terminal.svg" width="28" height="28" alt="terminal"><br>`terminal` | <img src="assets/icons/preview/code.svg" width="28" height="28" alt="code"><br>`code` | <img src="assets/icons/preview/cpu.svg" width="28" height="28" alt="cpu"><br>`cpu` |
| <img src="assets/icons/preview/wifi.svg" width="28" height="28" alt="wifi"><br>`wifi` | <img src="assets/icons/preview/monitor.svg" width="28" height="28" alt="monitor"><br>`monitor` | <img src="assets/icons/preview/smartphone.svg" width="28" height="28" alt="smartphone"><br>`smartphone` | <img src="assets/icons/preview/keyboard.svg" width="28" height="28" alt="keyboard"><br>`keyboard` | <img src="assets/icons/preview/mouse-pointer.svg" width="28" height="28" alt="mouse-pointer"><br>`mouse-pointer` | <img src="assets/icons/preview/camera.svg" width="28" height="28" alt="camera"><br>`camera` |
| <img src="assets/icons/preview/image.svg" width="28" height="28" alt="image"><br>`image` | <img src="assets/icons/preview/music.svg" width="28" height="28" alt="music"><br>`music` | <img src="assets/icons/preview/volume.svg" width="28" height="28" alt="volume"><br>`volume` | <img src="assets/icons/preview/message.svg" width="28" height="28" alt="message"><br>`message` |   |   |

## Aliases

Common alternative names map to the icons above:

| Alias | Icon |
|---|---|
| `aim` | `crosshair` |
| `alert-triangle` | `alert` |
| `chart` | `bar-chart` |
| `chat` | `message` |
| `close` | `x` |
| `cog` | `settings` |
| `ellipsis` | `more` |
| `exit` | `log-out` |
| `fire` | `flame` |
| `flash` | `zap` |
| `gear` | `settings` |
| `hamburger` | `menu` |
| `help-circle` | `help` |
| `home-2` | `home` |
| `house` | `home` |
| `lightning` | `zap` |
| `location` | `map-pin` |
| `pc` | `monitor` |
| `pencil` | `edit` |
| `phone` | `smartphone` |
| `pin` | `map-pin` |
| `player` | `user` |
| `players` | `users` |
| `question` | `help` |
| `reset` | `undo` |
| `sound` | `volume` |
| `star-filled` | `star` |
| `teleport` | `navigation` |
| `trash-2` | `trash` |
| `warning` | `alert` |

## Adding an icon

1. Add an entry to `tools/icons/icons.json` with a `name`, a `category` and `paths` (SVG path data on a 24x24 grid, stroke only).
2. Run `python tools/build_icons.py`. This regenerates the PNGs, SVGs, `src/Core/IconList.lua` and this file.
3. Run `python tools/build.py`, then publish with `tools/publish.bat`.

## License

The icon designs follow the [Lucide](https://lucide.dev) style; Lucide is ISC licensed.
