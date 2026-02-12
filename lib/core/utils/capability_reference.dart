/// ╔═══════════════════════════════════════════════════════════════════════╗
/// ║               HAVEN CAPABILITY & COLOR REFERENCE                     ║
/// ║                                                                       ║
/// ║  Single source of truth for every capability, color ID, hex value,    ║
/// ║  brightness level, and lighting status used in the Haven system.      ║
/// ║                                                                       ║
/// ║  Related files:                                                       ║
/// ║    • color_capability.dart — palette builders (getColors, getWhites)  ║
/// ║    • lighting_status.dart  — on/off + brightness helpers             ║
/// ║    • location_data_service.dart — ItemCapability model               ║
/// ║    • color_palette.dart    — effect color picker constants           ║
/// ╚═══════════════════════════════════════════════════════════════════════╝
library;

// ═══════════════════════════════════════════════════════════════════════
//  1.  ITEM CAPABILITIES
// ═══════════════════════════════════════════════════════════════════════
//
//  Every light, zone, and the location itself has an [ItemCapability]
//  object returned by the API under the `"capability"` key.
//
//  Model: lib/core/services/location_data_service.dart → ItemCapability
//
//  ┌──────────────────────┬────────┬──────────────────────────────────┐
//  │ Field                │ Type   │ Description                      │
//  ├──────────────────────┼────────┼──────────────────────────────────┤
//  │ colorCapability      │ String │ "Legacy" or "Extended".          │
//  │                      │        │ Determines which color palette   │
//  │                      │        │ to show (20 vs 32 colors).       │
//  ├──────────────────────┼────────┼──────────────────────────────────┤
//  │ brightnessCapability │ bool   │ true → brightness slider shown.  │
//  │                      │        │ Maps to brightnessId 1–10        │
//  │                      │        │ (10%–100%).                      │
//  ├──────────────────────┼────────┼──────────────────────────────────┤
//  │ whiteCapability      │ bool   │ true → Whites tab shown.         │
//  │                      │        │ 8 white temperatures (id 1–8).   │
//  ├──────────────────────┼────────┼──────────────────────────────────┤
//  │ patternCapability    │ bool   │ true → light supports patterns.  │
//  │                      │        │ (Reserved — not yet surfaced.)   │
//  ├──────────────────────┼────────┼──────────────────────────────────┤
//  │ lightShowCapability  │ bool   │ true → light supports shows.     │
//  │                      │        │ (Reserved — not yet surfaced.)   │
//  ├──────────────────────┼────────┼──────────────────────────────────┤
//  │ effectCapability     │ bool   │ true → Effects & Music tabs      │
//  │                      │        │ shown.                           │
//  └──────────────────────┴────────┴──────────────────────────────────┘
//
//  Tab visibility rules (see light_control_wrapper.dart → _buildAvailableTabs):
//
//    • Colors  — ALWAYS shown. Palette = Legacy (20) or Extended (32).
//    • Whites  — shown when whiteCapability == true.
//    • Effects — shown when effectCapability == true.
//    • Music   — shown when effectCapability == true.
//
//  "All Lights / Zones" container (DeviceControlCard) icon rules:
//
//    • Color palette icon (colors.png)  — shown when hasColorCapability.
//    • White palette icon (whitesicon.png) — shown when NO color but
//      whiteCapability == true.
//    • Color palette hidden — when neither color nor white capability.
//    • Brightness icon (sun) — shown when brightnessCapability == true.
//    • Image View icon — always shown.
//
//  Tapping the color/white palette icon in the "All Lights / Zones"
//  container opens LightControlWrapper with the **location-level**
//  capability (from `location.capability` in the API response).
//  This shows all tabs the location supports.
//
//  "All Lights / Zones" mode merges all items via LocationDataService
//  .bestCapability — any true flag wins, any "Extended" wins.

// ═══════════════════════════════════════════════════════════════════════
//  2.  COLOR CAPABILITY TYPES
// ═══════════════════════════════════════════════════════════════════════
//
//  ┌──────────┬──────────────────────────────────────────────────────┐
//  │ Value    │ Description                                          │
//  ├──────────┼──────────────────────────────────────────────────────┤
//  │ "Legacy" │ 20 colors (id 11–30) + 8 whites (id 1–8).           │
//  │          │ Used by K Series and older controllers.              │
//  ├──────────┼──────────────────────────────────────────────────────┤
//  │"Extended"│ 32 colors (id 11–57) + 8 whites (id 1–8).           │
//  │          │ Used by X Series (TRIM LIGHT, X MINI, X-POE, etc.)  │
//  └──────────┴──────────────────────────────────────────────────────┘

// ═══════════════════════════════════════════════════════════════════════
//  3.  LEGACY COLORS  (id 11–30, 20 colors)
// ═══════════════════════════════════════════════════════════════════════
//
//  ┌────┬─────────────┬────────────┐
//  │ ID │ Name        │ Hex        │
//  ├────┼─────────────┼────────────┤
//  │ 11 │ Red         │ #EC202C    │
//  │ 12 │ Fire        │ #ED3A1A    │
//  │ 13 │ Pumpkin     │ #EF5023    │
//  │ 14 │ Amber       │ #F17B20    │
//  │ 15 │ Tangerine   │ #F39220    │
//  │ 16 │ Marigold    │ #F5A623    │
//  │ 17 │ Sunset      │ #FAA819    │
//  │ 18 │ Yellow      │ #FDD901    │
//  │ 19 │ Lime        │ #C7D92C    │
//  │ 20 │ Light Green │ #8DC63F    │
//  │ 21 │ Green       │ #00A651    │
//  │ 22 │ Sea Foam    │ #00B89C    │
//  │ 23 │ Turquoise   │ #00BCD4    │
//  │ 24 │ Ocean       │ #0076C0    │
//  │ 25 │ Deep Blue   │ #1B3FA0    │
//  │ 26 │ Violet      │ #6A3FA0    │
//  │ 27 │ Purple      │ #93278F    │
//  │ 28 │ Lavender    │ #B576BD    │
//  │ 29 │ Pink        │ #E84C8A    │
//  │ 30 │ Hot Pink    │ #EC2180    │
//  └────┴─────────────┴────────────┘

// ═══════════════════════════════════════════════════════════════════════
//  4.  EXTENDED COLORS  (id 11–57, 32 colors)
// ═══════════════════════════════════════════════════════════════════════
//
//  Includes overlapping IDs with Legacy but may have different display
//  names or hex values (tuned for X Series LEDs).
//
//  ┌────┬─────────────┬────────────┐
//  │ ID │ Name        │ Hex        │
//  ├────┼─────────────┼────────────┤
//  │ 11 │ Red         │ #EC202C    │
//  │ 13 │ Pumpkin     │ #ED2F24    │
//  │ 39 │ Orange      │ #EF5023    │
//  │ 16 │ Marigold    │ #F37A20    │
//  │ 17 │ Sunset      │ #FAA819    │
//  │ 18 │ Yellow      │ #FDD901    │
//  │ 40 │ Lemon       │ #EFE814    │
//  │ 19 │ Lime        │ #C7D92C    │
//  │ 41 │ Pear        │ #A7CE38    │
//  │ 42 │ Emerald     │ #88C440    │
//  │ 20 │ Lt Green    │ #75BF43    │
//  │ 21 │ Green       │ #6ABC45    │
//  │ 22 │ Sea Foam    │ #6CBD45    │
//  │ 55 │ Teal        │ #71BE48    │
//  │ 23 │ Turquoise   │ #71C178    │
//  │ 44 │ Arctic      │ #70C5A2    │
//  │ 24 │ Ocean       │ #70C9CC    │
//  │ 45 │ Sky         │ #61CAE5    │
//  │ 46 │ Water       │ #43B4E7    │
//  │ 47 │ Sapphire    │ #4782C3    │
//  │ 48 │ Lt Blue     │ #4165AF    │
//  │ 25 │ Deep Blue   │ #3E57A6    │
//  │ 57 │ Indigo      │ #3C54A3    │
//  │ 50 │ Orchid      │ #4B53A3    │
//  │ 27 │ Purple      │ #6053A2    │
//  │ 28 │ Lavender    │ #7952A0    │
//  │ 51 │ Lilac       │ #94519F    │
//  │ 29 │ Pink        │ #B2519E    │
//  │ 52 │ Bubblegum   │ #C94D9B    │
//  │ 53 │ Flamingo    │ #E63A94    │
//  │ 30 │ Hot Pink    │ #EC2180    │
//  │ 54 │ Deep Pink   │ #ED1F52    │
//  └────┴─────────────┴────────────┘

// ═══════════════════════════════════════════════════════════════════════
//  5.  WHITE TEMPERATURES  (id 1–8, shared by Legacy & Extended)
// ═══════════════════════════════════════════════════════════════════════
//
//  ┌────┬───────┬────────────┬──────────────────────────────────────────┐
//  │ ID │ Name  │ Hex        │ Effect Palette Alias                     │
//  ├────┼───────┼────────────┼──────────────────────────────────────────┤
//  │  1 │ 2700K │ #F8E96C    │ Warm White                               │
//  │  2 │ 3000K │ #F6F08E    │ Soft White                               │
//  │  3 │ 3500K │ #F4F4AC    │ White                                    │
//  │  4 │ 3700K │ #F2F4C2    │ Cool White                               │
//  │  5 │ 4000K │ #ECF5DA    │ Bright White                             │
//  │  6 │ 4100K │ #E3F3E9    │ Daylight                                 │
//  │  7 │ 4700K │ #DDF1F2    │ Ice White                                │
//  │  8 │ 5000K │ #D6EFF6    │ Blue White                               │
//  └────┴───────┴────────────┴──────────────────────────────────────────┘

// ═══════════════════════════════════════════════════════════════════════
//  6.  BRIGHTNESS LEVELS
// ═══════════════════════════════════════════════════════════════════════
//
//  API field: `lightBrightnessId`  (int, 1–10)
//  UI slider: 0–100 %  →  converted via  (slider / 10).round().clamp(1, 10)
//
//  ┌────────────────┬────────────┐
//  │ brightnessId   │ Display %  │
//  ├────────────────┼────────────┤
//  │ 0 / null       │   0 % (off)│
//  │ 1              │  10 %      │
//  │ 2              │  20 %      │
//  │ 3              │  30 %      │
//  │ 4              │  40 %      │
//  │ 5              │  50 %      │
//  │ 6              │  60 %      │
//  │ 7              │  70 %      │
//  │ 8              │  80 %      │
//  │ 9              │  90 %      │
//  │ 10             │ 100 %      │
//  └────────────────┴────────────┘
//
//  Helper: LightingStatus.brightnessPercent(id)
//  Helper: LightingStatus.brightnessFraction(id)   → 0.0–1.0

// ═══════════════════════════════════════════════════════════════════════
//  7.  LIGHTING STATUS
// ═══════════════════════════════════════════════════════════════════════
//
//  API field: `lightingStatus`  (String)
//
//  ┌──────────────────┬────────────────────────────────────────────────┐
//  │ Value            │ Meaning                                        │
//  ├──────────────────┼────────────────────────────────────────────────┤
//  │ "OFF"            │ Light is off.                                  │
//  │ "SOLID_COLOR"    │ Light is on, showing a solid color.            │
//  │ "PATTERN"        │ Light is running a pattern.                    │
//  └──────────────────┴────────────────────────────────────────────────┘
//
//  `lightingStatusId` values used in optimistic updates:
//    • 1 = OFF
//    • 3 = SOLID_COLOR
//
//  Helper: LightingStatus.isOn(lightingStatus:, brightnessId:)
//  Helper: LightingStatus.isOff(lightingStatus:, brightnessId:)

// ═══════════════════════════════════════════════════════════════════════
//  8.  EFFECT TYPES (effectCapability == true)
// ═══════════════════════════════════════════════════════════════════════
//
//  When `effectCapability` is true, the Effects and Music tabs appear.
//  Each effect has an `effectType` string that drives the painter:
//
//  ┌──────────────┬────────────────────────────────────────────────────┐
//  │ effectType   │ Description                                        │
//  ├──────────────┼────────────────────────────────────────────────────┤
//  │ "wave3"      │ Multi-wave gradient animation.                     │
//  │              │ Config: startColor, peakColor, valleyColor,        │
//  │              │         waves[], opacity.                          │
//  ├──────────────┼────────────────────────────────────────────────────┤
//  │ "comet"      │ Shooting comet trails.                             │
//  │              │ Config: colors[], cometCount, tailLength,          │
//  │              │         minSpeed, maxSpeed.                        │
//  ├──────────────┼────────────────────────────────────────────────────┤
//  │ "usaFlag"    │ USA flag pattern animation.                        │
//  │              │ Config: none (built-in).                           │
//  ├──────────────┼────────────────────────────────────────────────────┤
//  │ "sparkle"    │ Twinkling sparkle overlay.                         │
//  │              │ Config: backgroundColor, sparkleColor,             │
//  │              │         sparkleCount, minSize, maxSize,            │
//  │              │         twinkleSpeed.                              │
//  └──────────────┴────────────────────────────────────────────────────┘

// ═══════════════════════════════════════════════════════════════════════
//  9.  UI THEME COLORS
// ═══════════════════════════════════════════════════════════════════════
//
//  App-wide hex values used across screens:
//
//  ┌────────────────────────┬────────────┬────────────────────────────┐
//  │ Usage                  │ Hex        │ Where                      │
//  ├────────────────────────┼────────────┼────────────────────────────┤
//  │ Background (primary)   │ #1C1C1C    │ AppBar, header ribbon      │
//  │ Background (content)   │ #2A2A2A    │ Scaffold, tab bar          │
//  │ Card default (off)     │ #1D1D1D    │ Light card unlit           │
//  │ Accent / brand orange  │ #C56A21    │ Add effect button, badges  │
//  │ Accent / brand orange 2│ #F57F20    │ Buttons, links             │
//  │ Accent / brand orange 3│ #D4842A    │ Channel pin highlight      │
//  │ Tab unselected         │ #6E6E6E    │ Bottom nav text & icon     │
//  │ Subtitle / muted text  │ #828282    │ Empty-state helper text    │
//  │ Muted text (lighter)   │ #9E9E9E    │ Section subtitles          │
//  │ Surface / pill         │ #3A3A3A    │ Buttons, chips             │
//  └────────────────────────┴────────────┴────────────────────────────┘

// ═══════════════════════════════════════════════════════════════════════
//  10.  API COMMAND REFERENCE  (quick look-up)
// ═══════════════════════════════════════════════════════════════════════
//
//  All commands go through CommandService (lib/core/services/command_service.dart).
//
//  ┌───────────────────────┬──────────────────────────────────────────┐
//  │ Method                │ API Action                               │
//  ├───────────────────────┼──────────────────────────────────────────┤
//  │ setColor(id, type,    │ Set a single light/zone to a color ID.  │
//  │   colorId)            │                                          │
//  │ setAllColor(colorId)  │ Set entire location to a color ID.      │
//  │ turnOn(id, type)      │ Turn a single light/zone on.            │
//  │ turnOff(id, type)     │ Turn a single light/zone off.           │
//  │ turnAllOn()           │ Turn entire location on.                 │
//  │ turnAllOff()          │ Turn entire location off.                │
//  │ setBrightness(id,     │ Set brightness on a single light/zone.  │
//  │   type, brightnessId) │                                          │
//  │ setAllBrightness(     │ Set brightness for entire location.     │
//  │   brightnessId)       │                                          │
//  └───────────────────────┴──────────────────────────────────────────┘
//
//  `type` is either "Light" or "Zone".
//  `colorId` is from the palettes above (1–8 for whites, 11–57 for colors).
//  `brightnessId` is 1–10.
