# EakUI Icons

EakUI ships **176 built-in icons** that you can use by name anywhere an image is accepted.

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

### Farming & Harvest (22)

|   |   |   |   |   |   |
|---|---|---|---|---|---|
| <img src="assets/icons/preview/sprout.svg" width="28" height="28" alt="sprout"><br>`sprout` | <img src="assets/icons/preview/leaf.svg" width="28" height="28" alt="leaf"><br>`leaf` | <img src="assets/icons/preview/wheat.svg" width="28" height="28" alt="wheat"><br>`wheat` | <img src="assets/icons/preview/tree.svg" width="28" height="28" alt="tree"><br>`tree` | <img src="assets/icons/preview/tree-round.svg" width="28" height="28" alt="tree-round"><br>`tree-round` | <img src="assets/icons/preview/flower.svg" width="28" height="28" alt="flower"><br>`flower` |
| <img src="assets/icons/preview/seed.svg" width="28" height="28" alt="seed"><br>`seed` | <img src="assets/icons/preview/shovel.svg" width="28" height="28" alt="shovel"><br>`shovel` | <img src="assets/icons/preview/watering-can.svg" width="28" height="28" alt="watering-can"><br>`watering-can` | <img src="assets/icons/preview/droplet.svg" width="28" height="28" alt="droplet"><br>`droplet` | <img src="assets/icons/preview/apple.svg" width="28" height="28" alt="apple"><br>`apple` | <img src="assets/icons/preview/carrot.svg" width="28" height="28" alt="carrot"><br>`carrot` |
| <img src="assets/icons/preview/grape.svg" width="28" height="28" alt="grape"><br>`grape` | <img src="assets/icons/preview/cherry.svg" width="28" height="28" alt="cherry"><br>`cherry` | <img src="assets/icons/preview/egg.svg" width="28" height="28" alt="egg"><br>`egg` | <img src="assets/icons/preview/fish.svg" width="28" height="28" alt="fish"><br>`fish` | <img src="assets/icons/preview/fishing-rod.svg" width="28" height="28" alt="fishing-rod"><br>`fishing-rod` | <img src="assets/icons/preview/bug.svg" width="28" height="28" alt="bug"><br>`bug` |
| <img src="assets/icons/preview/paw.svg" width="28" height="28" alt="paw"><br>`paw` | <img src="assets/icons/preview/barn.svg" width="28" height="28" alt="barn"><br>`barn` | <img src="assets/icons/preview/tractor.svg" width="28" height="28" alt="tractor"><br>`tractor` | <img src="assets/icons/preview/basket.svg" width="28" height="28" alt="basket"><br>`basket` |   |   |

### Tools & Gathering (9)

|   |   |   |   |   |   |
|---|---|---|---|---|---|
| <img src="assets/icons/preview/axe.svg" width="28" height="28" alt="axe"><br>`axe` | <img src="assets/icons/preview/pickaxe.svg" width="28" height="28" alt="pickaxe"><br>`pickaxe` | <img src="assets/icons/preview/hammer.svg" width="28" height="28" alt="hammer"><br>`hammer` | <img src="assets/icons/preview/wrench.svg" width="28" height="28" alt="wrench"><br>`wrench` | <img src="assets/icons/preview/magnet.svg" width="28" height="28" alt="magnet"><br>`magnet` | <img src="assets/icons/preview/hand.svg" width="28" height="28" alt="hand"><br>`hand` |
| <img src="assets/icons/preview/recycle.svg" width="28" height="28" alt="recycle"><br>`recycle` | <img src="assets/icons/preview/bag.svg" width="28" height="28" alt="bag"><br>`bag` | <img src="assets/icons/preview/backpack.svg" width="28" height="28" alt="backpack"><br>`backpack` |   |   |   |

### Automation (14)

|   |   |   |   |   |   |
|---|---|---|---|---|---|
| <img src="assets/icons/preview/bot.svg" width="28" height="28" alt="bot"><br>`bot` | <img src="assets/icons/preview/repeat.svg" width="28" height="28" alt="repeat"><br>`repeat` | <img src="assets/icons/preview/timer.svg" width="28" height="28" alt="timer"><br>`timer` | <img src="assets/icons/preview/hourglass.svg" width="28" height="28" alt="hourglass"><br>`hourglass` | <img src="assets/icons/preview/workflow.svg" width="28" height="28" alt="workflow"><br>`workflow` | <img src="assets/icons/preview/infinity.svg" width="28" height="28" alt="infinity"><br>`infinity` |
| <img src="assets/icons/preview/route.svg" width="28" height="28" alt="route"><br>`route` | <img src="assets/icons/preview/radar.svg" width="28" height="28" alt="radar"><br>`radar` | <img src="assets/icons/preview/scan.svg" width="28" height="28" alt="scan"><br>`scan` | <img src="assets/icons/preview/fast-forward.svg" width="28" height="28" alt="fast-forward"><br>`fast-forward` | <img src="assets/icons/preview/skip-forward.svg" width="28" height="28" alt="skip-forward"><br>`skip-forward` | <img src="assets/icons/preview/toggle.svg" width="28" height="28" alt="toggle"><br>`toggle` |
| <img src="assets/icons/preview/trending-up.svg" width="28" height="28" alt="trending-up"><br>`trending-up` | <img src="assets/icons/preview/layers.svg" width="28" height="28" alt="layers"><br>`layers` |   |   |   |   |

### Economy & Items (10)

|   |   |   |   |   |   |
|---|---|---|---|---|---|
| <img src="assets/icons/preview/cart.svg" width="28" height="28" alt="cart"><br>`cart` | <img src="assets/icons/preview/store.svg" width="28" height="28" alt="store"><br>`store` | <img src="assets/icons/preview/wallet.svg" width="28" height="28" alt="wallet"><br>`wallet` | <img src="assets/icons/preview/dollar.svg" width="28" height="28" alt="dollar"><br>`dollar` | <img src="assets/icons/preview/archive.svg" width="28" height="28" alt="archive"><br>`archive` | <img src="assets/icons/preview/diamond.svg" width="28" height="28" alt="diamond"><br>`diamond` |
| <img src="assets/icons/preview/potion.svg" width="28" height="28" alt="potion"><br>`potion` | <img src="assets/icons/preview/scroll.svg" width="28" height="28" alt="scroll"><br>`scroll` | <img src="assets/icons/preview/flag.svg" width="28" height="28" alt="flag"><br>`flag` | <img src="assets/icons/preview/anchor.svg" width="28" height="28" alt="anchor"><br>`anchor` |   |   |

### Blocks & Building (14)

|   |   |   |   |   |   |
|---|---|---|---|---|---|
| <img src="assets/icons/preview/block.svg" width="28" height="28" alt="block"><br>`block` | <img src="assets/icons/preview/blocks.svg" width="28" height="28" alt="blocks"><br>`blocks` | <img src="assets/icons/preview/brick.svg" width="28" height="28" alt="brick"><br>`brick` | <img src="assets/icons/preview/block-break.svg" width="28" height="28" alt="block-break"><br>`block-break` | <img src="assets/icons/preview/block-place.svg" width="28" height="28" alt="block-place"><br>`block-place` | <img src="assets/icons/preview/block-remove.svg" width="28" height="28" alt="block-remove"><br>`block-remove` |
| <img src="assets/icons/preview/door.svg" width="28" height="28" alt="door"><br>`door` | <img src="assets/icons/preview/ladder.svg" width="28" height="28" alt="ladder"><br>`ladder` | <img src="assets/icons/preview/chest.svg" width="28" height="28" alt="chest"><br>`chest` | <img src="assets/icons/preview/sign.svg" width="28" height="28" alt="sign"><br>`sign` | <img src="assets/icons/preview/portal.svg" width="28" height="28" alt="portal"><br>`portal` | <img src="assets/icons/preview/fence.svg" width="28" height="28" alt="fence"><br>`fence` |
| <img src="assets/icons/preview/platform.svg" width="28" height="28" alt="platform"><br>`platform` | <img src="assets/icons/preview/seed-pack.svg" width="28" height="28" alt="seed-pack"><br>`seed-pack` |   |   |   |   |

### Player & Movement (16)

|   |   |   |   |   |   |
|---|---|---|---|---|---|
| <img src="assets/icons/preview/player.svg" width="28" height="28" alt="player"><br>`player` | <img src="assets/icons/preview/player-run.svg" width="28" height="28" alt="player-run"><br>`player-run` | <img src="assets/icons/preview/jump.svg" width="28" height="28" alt="jump"><br>`jump` | <img src="assets/icons/preview/move.svg" width="28" height="28" alt="move"><br>`move` | <img src="assets/icons/preview/move-vertical.svg" width="28" height="28" alt="move-vertical"><br>`move-vertical` | <img src="assets/icons/preview/move-horizontal.svg" width="28" height="28" alt="move-horizontal"><br>`move-horizontal` |
| <img src="assets/icons/preview/rotate.svg" width="28" height="28" alt="rotate"><br>`rotate` | <img src="assets/icons/preview/teleport.svg" width="28" height="28" alt="teleport"><br>`teleport` | <img src="assets/icons/preview/fly.svg" width="28" height="28" alt="fly"><br>`fly` | <img src="assets/icons/preview/footprints.svg" width="28" height="28" alt="footprints"><br>`footprints` | <img src="assets/icons/preview/spawn.svg" width="28" height="28" alt="spawn"><br>`spawn` | <img src="assets/icons/preview/punch.svg" width="28" height="28" alt="punch"><br>`punch` |
| <img src="assets/icons/preview/swim.svg" width="28" height="28" alt="swim"><br>`swim` | <img src="assets/icons/preview/ghost.svg" width="28" height="28" alt="ghost"><br>`ghost` | <img src="assets/icons/preview/speed.svg" width="28" height="28" alt="speed"><br>`speed` | <img src="assets/icons/preview/health.svg" width="28" height="28" alt="health"><br>`health` |   |   |

## Aliases

Common alternative names map to the icons above:

| Alias | Icon |
|---|---|
| `aim` | `crosshair` |
| `alert-triangle` | `alert` |
| `auto` | `bot` |
| `break` | `block-break` |
| `build` | `block-place` |
| `cash` | `dollar` |
| `character` | `player` |
| `chart` | `bar-chart` |
| `chat` | `message` |
| `chop` | `axe` |
| `close` | `x` |
| `cog` | `settings` |
| `crop` | `wheat` |
| `cube` | `block` |
| `ellipsis` | `more` |
| `exit` | `log-out` |
| `farm` | `sprout` |
| `fire` | `flame` |
| `flash` | `zap` |
| `gear` | `settings` |
| `hamburger` | `menu` |
| `harvest` | `wheat` |
| `help-circle` | `help` |
| `home-2` | `home` |
| `house` | `home` |
| `inventory` | `backpack` |
| `lightning` | `zap` |
| `location` | `map-pin` |
| `loop` | `repeat` |
| `mine` | `pickaxe` |
| `money` | `dollar` |
| `pc` | `monitor` |
| `pencil` | `edit` |
| `phone` | `smartphone` |
| `pin` | `map-pin` |
| `plant` | `sprout` |
| `players` | `users` |
| `question` | `help` |
| `reset` | `undo` |
| `run` | `player-run` |
| `shop` | `store` |
| `sound` | `volume` |
| `star-filled` | `star` |
| `tp` | `teleport` |
| `trash-2` | `trash` |
| `walk` | `footprints` |
| `wall` | `brick` |
| `warning` | `alert` |
| `water` | `droplet` |

## Adding an icon

1. Add an entry to `tools/icons/icons.json` with a `name`, a `category` and `paths` (SVG path data on a 24x24 grid, stroke only).
2. Run `python tools/build_icons.py`. This regenerates the PNGs, SVGs, `src/Core/IconList.lua` and this file.
3. Run `python tools/build.py`, then publish with `tools/publish.bat`.

## License

Some icons use path data from [Lucide](https://lucide.dev) (ISC License); the others were drawn for EakUI in the same style. See [assets/icons/LICENSE-LUCIDE.txt](assets/icons/LICENSE-LUCIDE.txt).
