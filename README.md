### Phase 1: Core System Architecture & Global Colors

To maintain the strict, high-contrast black-and-white look across all 5 tabs, the app will run on a global reactive `themeProvider` with zero fuzzy drop-shadows or curved cards.

```
       DARK MODE CONFIGURATION                LIGHT MODE CONFIGURATION
┌──────────────────────────────────┐   ┌──────────────────────────────────┐
│ Canvas:   Pure Black #000000     │   │ Canvas:   Pure White #FFFFFF     │
│ Main Text: Pure White #FFFFFF    │   │ Main Text: Pure Black #000000    │
│ Sub Text:  Muted Grey #737373    │   │ Sub Text:  Muted Grey #404040    │
│ Borders:   Fine Grey  #1F1F1F    │   │ Borders:   Fine Grey  #E5E5E5    │
│ Panels:    Off-Black  #0A0A0A    │   │ Panels:    Off-White  #F5F5F5    │
└──────────────────────────────────┘   └──────────────────────────────────┘
 Accent/Fruit/Legend Color: Deep Crimson Burgundy (#5F0E0D) - Flat fill across both modes.

```

* **Borders:** Fixed at `width: 0.8` using strict `Border.all()`. No `BorderRadius` elements allowed unless drawing circles for the compass/snake.
* **Typography Engine:** Global forced uppercase for all system metrics, titles, and layout headers. Font configurations will use tight line heights (`height: 1.0` to `1.2`), compact sizes (`9px` to `13px`), sharp weights (`FontWeight.w700`), and explicit tracking adjustments (`letterSpacing: 0.05` to `0.12`).

### Phase 2: Structural Plan for the 5 Tabs

#### Tab 1: Weather Dashboard (`weather.dart`)

Instead of realistic cloud illustrations or soft gradients, weather conditions are rendered via flat, geometric primitive blocks.

```
  [ CLEAN ]            [ CLOUDY ]             [ RAINY ]            [ NIGHT ]
 ┌─────────┐                                 \ \ \ \ \ \          ┌────
 │         │            - = - = -             \ \ \ \ \ \         │    |
 │         │            = - = - =              \ \ \ \ \ \        │    |
 │         │                                  \ \ \ \ \ \         │    |
 └─────────┘                                                      └────
 Pure Square         ASCII Pattern Strata      Raw Slashing lines    Half-Cut Square
 (Border Fill)       (Monospace Type)         (Custom Painter)     (Custom Painter)

```

1. **Layout Stack:** A vertically scrollable system interface. The top hero component holds the current location, large digit temp text, and the structural asset state card.
2. **Dense Metadata Row Grid:** A flat 2x2 grid containing system-monitored variables:
* `WIND DIRECTION & SPEED` (e.g., `NW // 14.2 KM/H`)
* `CLOUD COVER RATIO` (e.g., `88% // STRATUS`)
* `HORIZONTAL VISIBILITY` (e.g., `12.0 KM`)
* `BAROMETRIC PRESSURE` (e.g., `1012 HPA`)


3. **Graph Engine 1 (Hourly Forecast):** A customized, minimalist line chart plotted inside a strict rectangle canvas using `CustomPainter`. No gradients underneath the path; just a clean, sharp, 1-pixel-wide line connecting coordinate points, accented with micro numbers above each node.
4. **Graph Engine 2 (7-Day Matrix Overview):** A horizontal matrix block layout displaying columns for `PAST 3 | CURRENT | FUTURE 3`. It uses flat, solid vertical bars to represent temperature shifts over the 7-day span.

#### Tab 2: Precision Dot Compass (`compass.dart`)

An exercise in extreme subtraction. This view strips out traditional dial markings, degree readouts, and crosshairs.

```
                     [ COMPASS INTERFACE ]
                     
                         ┌───────────┐
                         │     ·     │ <-- Micro North Tracker Dot
                         │           │     (Rotates dynamically)
                         │     +     │ <-- Stationary Center Pivot Anchor
                         │           │
                         │           │
                         └───────────┘
                         BEARING: 024°

```

1. **Mechanical Base:** A pure circular or square tracking layout mapped via a `StreamBuilder` connected to device heading hardware sensors.
2. **Visual Elements:**
* **Center Anchor:** A fixed micro-crosshair `+` symbol or a 2-pixel point directly at the origin coordinates.
* **North Tracker:** No outer ring lines. Only a single solid dot or a tiny empty circle orbiting the pivot point. It dynamically rotates using a `Transform.rotate` widget based on the current heading angle, pointing directly toward physical North.


3. **Telemetry Data:** Positioned below the canvas, a crisp typography block displays data in all-caps: `BEARING: XXX° // TRUE NORTH HARMONIZED`.

#### Tab 3: Matrix Time Ledger Calendar (`calendar.dart`)

This screen replicates the contribution grid from `ideainbox.dart`, removing data input arrays to turn it into an immutable visual timeline tracker.

```
                    [ 7-COLUMN YEAR MATRIX ]
                    
                    JANUARY           FEBRUARY
                    M T W T F S S     M T W T F S S
                    ■ ■ ■ ■ □ □ □     □ □ ■ ■ ■ □ □
                    ■ ■ ■ ■ ■ □ □     ■ ■ ■ ■ ■ □ □
                    
                    ■ ELAPSED   □ REMAINING   ■ CURRENT/UPCOMING

```

1. **Layout System:** A vertical list of month blocks. Each month features a bold, all-caps header string (`JANUARY`, `FEBRUARY`), a dense 7-column day-of-the-week indicator row (`M T W T F S S`), and a custom grid showing the exact calendar days for that year.
2. **Cell State Painting Architecture:**
* **Elapsed Days:** Filled boxes using `textMain` color (White in Dark mode, Black in Light mode).
* **Remaining Days:** Empty boxes styled with a fine `ruleBorder` framework.
* **Current/Upcoming Indicator:** Blocks filled with your signature deep crimson burgundy `Color(0xFF5F0E0D)`.


3. **Zero-Input Constraints:** All list interaction tap listeners and item builders from the previous notes-app architecture are completely removed, creating a lightweight, read-only system canvas.

#### Tab 4: Cellular Snake Engine (`snake.dart`)

An arcade loop that functions like an embedded terminal game widget inside your technical layout framework.

```
                    [ ARCADE SUBSYSTEM ]
                    
                    ┌─────────────────────────┐
                    │       ■■■■              │ <-- Snake Body (Text Main Color)
                    │          ■              │
                    │          ■              │ <-- Fruit (Deep Crimson #5F0E0D)
                    │                         │
                    └─────────────────────────┘
                    SCORE: 004 // BEST: 028
                    
                    [ START ]  [ ◀ ]  [ ▲ ]  [ ▼ ]  [ ▶ ]

```

1. **Game Canvas Box:** A flat container outline defining a strict coordinate cell grid (e.g., 20x20 matrix coordinates).
2. **Loop & State Architecture:** An internal engine driven by a standard `Timer.periodic` loop (ticking every 150-200ms). Movement is processed using point vectors (`Point<int>`).
3. **Component Styling:**
* **Snake Segments:** Rendered as clean, flat squares using your theme's `textMain` color.
* **Fruit Segment:** A solitary grid node filled with the signature deep crimson burgundy `Color(0xFF5F0E0D)`.


4. **Operational Interface:** A sharp, horizontal button deck containing the all-caps `START` control alongside a directional input pad mapped with thin borders. It includes a live telemetry metadata tracker below reading: `SCORE: XXX // HIGH SCORE: XXX`.

#### Tab 5: Serial System Settings (`settings.dart`)

This menu structure mirrors `settings.dart` exactly, focusing entirely on configuration toggles and outward destination portals.

```
                    [ SYSTEM UTILITIES ]
                    
                    THEME CONFIGURATION
                    Toggle between absolute light and dark canvases
                    ───────────────────────────────────────────────
                    PRIVACY PROTOCOLS
                    Review localized data persistence parameters
                    ───────────────────────────────────────────────
                    OUTWARD SYSTEM WEB PORTAL
                    Access source architectural documentation
                    ───────────────────────────────────────────────
                    COMPANION APPLICATIONS
                    Explore alternative DarshSerphic systems
                    ───────────────────────────────────────────────
                    
                         BUILD BY DARSHSERPHIC

```

1. **Component Menu Framework:** Simple, flat rows stacked vertically. Each row features a bold, uppercase section header, a muted subtext description paragraph detailing the utility path, and an explicit full-width boundary line (`height: 1`).
2. **Target Action Routes:**
* `THEME CONFIGURATION` -> Calls the reactive `themeProvider.notifier` to flip the global boolean state.
* `PRIVACY PROTOCOLS` -> Triggers a `showGeneralDialog` overlay with transparent backdrops, displaying your terms text.
* `OUTWARD SYSTEM WEB PORTAL` -> Launches external URLs via the system framework.
* `COMPANION APPLICATIONS` -> Links directly to your ecosystem project hubs.


3. **System Stamp Signature:** Centered at the absolute bottom coordinates, the static text signature reads: `BUILD BY DARSHSERPHIC`, utilizing an ultra-compact `fontSize: 9` layout with heavy tracking (`letterSpacing: 0.12`).


### Step-by-Step Implementation Blueprint

1. **Step 1:** Establish the base directory tree (`main.dart`, `core/theme.dart`, `tabs/`). Initialize Riverpod and set up the global true black-and-white theme layout shell.
2. **Step 2:** Build out the structural custom painter assets for Tab 1 (Weather), mapping the four structural ASCII/Geometric conditions alongside the horizontal coordinate charts.
3. **Step 3:** Hook up the sensor stream telemetry calculations inside Tab 2 to translate absolute heading degrees into a clean orbiting tracking point.
4. **Step 4:** Extract the raw matrix math blocks from `ideainbox.dart` into Tab 3 to render the static yearly grid timeline.
5. **Step 5:** Write the grid update loops and coordinate checkers for Tab 4's game loop, assigning the crimson hue to the target fruit.
6. **Step 6:** Construct the modular menu row lists for Tab 5, placing your signature design stamp at the bottom.
