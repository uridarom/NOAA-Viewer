# SPC Severe Weather Outlook — iOS App Spec

## 0. Overview

A lightweight iOS app that fetches and displays NOAA Storm Prediction Center (SPC) Convective Outlooks for Days 1–8. Pure client-side; no backend. The app surfaces:

- The official SPC categorical and probabilistic outlook images
- A user-location-aware "Local Risks" panel showing the tornado/hail/wind probabilities at the user's coordinates
- The forecast discussion text issued alongside each outlook
- The schedule of the next expected outlook issuance

Design language: monospace (Courier New), dark theme, terminal/CRT aesthetic. Looks like a forecaster's HUD rather than a consumer weather app.

---

## 1. Data Sources

All data comes directly from `www.spc.noaa.gov`. No third-party APIs required.

### 1.1 Outlook Images (PNG/GIF)

Single, latest-issued image per product. URLs are stable; the file is overwritten at each new issuance.

| Product | URL |
|---|---|
| Day 1 Categorical | `https://www.spc.noaa.gov/products/outlook/day1otlk.gif` |
| Day 1 Tornado prob | `https://www.spc.noaa.gov/products/outlook/day1probotlk_torn.gif` |
| Day 1 Hail prob | `https://www.spc.noaa.gov/products/outlook/day1probotlk_hail.gif` |
| Day 1 Wind prob | `https://www.spc.noaa.gov/products/outlook/day1probotlk_wind.gif` |
| Day 2 Categorical | `https://www.spc.noaa.gov/products/outlook/day2otlk.gif` |
| Day 2 Tornado prob | `https://www.spc.noaa.gov/products/outlook/day2probotlk_torn.gif` |
| Day 2 Hail prob | `https://www.spc.noaa.gov/products/outlook/day2probotlk_hail.gif` |
| Day 2 Wind prob | `https://www.spc.noaa.gov/products/outlook/day2probotlk_wind.gif` |
| Day 3 Categorical | `https://www.spc.noaa.gov/products/outlook/day3otlk.gif` |
| Day 3 Probabilistic (combined) | `https://www.spc.noaa.gov/products/outlook/day3prob.gif` |
| Day 4–8 (combined) | `https://www.spc.noaa.gov/products/outlook/day48probotlk.gif` |

**Note on Days 4–8:** SPC publishes a single combined probabilistic image for all of Days 4–8 (not per-day). The app should still let the user "select" Days 4, 5, 6, 7, 8 in the slider, but each selection will display the same `day48probotlk.gif` image. This must be communicated to the user via the helper text under the day slider (e.g., "Days 4–8 share a combined outlook").

**Note on Day 3:** Day 3 only has a single probabilistic outlook (no separate tornado/hail/wind breakdown). The TORNADO/HAIL/WIND tabs should be disabled when Day 3 is selected.

### 1.2 GeoJSON Polygons (for Local Risk Calculation)

SPC publishes GeoJSON layers for the polygon boundaries of each outlook. These are the *exact same data* as the images, but as machine-readable polygons. URL pattern:

```
https://www.spc.noaa.gov/products/outlook/day{N}otlk_cat.lyr.geojson
https://www.spc.noaa.gov/products/outlook/day{N}otlk_torn.lyr.geojson
https://www.spc.noaa.gov/products/outlook/day{N}otlk_hail.lyr.geojson
https://www.spc.noaa.gov/products/outlook/day{N}otlk_wind.lyr.geojson
```

Each feature in the GeoJSON has a `LABEL` or `LABEL2` property indicating the probability tier (e.g., `"2 %"`, `"5 %"`, `"10 %"`, `"15 %"`, `"30 %"`, `"45 %"`, `"60 %"`, `"SIGN"` for significant hatched areas) and a `Polygon` or `MultiPolygon` geometry in WGS84.

**Local Risk Calculation algorithm:**

1. Fetch each GeoJSON file for Day 1 (tornado, hail, wind).
2. For each layer, iterate features from highest probability to lowest.
3. Run point-in-polygon (PIP) against the user's `(lat, lon)`.
4. The first matching feature determines the user's local probability for that hazard. If no polygon contains the point, the local risk is `0%`.

### 1.3 Forecast Discussion Text

Raw text product, plain ASCII, no auth needed:

| Product | URL |
|---|---|
| Day 1 Discussion | `https://www.spc.noaa.gov/products/outlook/day1otlk.txt` |
| Day 2 Discussion | `https://www.spc.noaa.gov/products/outlook/day2otlk.txt` |
| Day 3 Discussion | `https://www.spc.noaa.gov/products/outlook/day3otlk.txt` |
| Day 4–8 Discussion | `https://www.spc.noaa.gov/products/outlook/day48otlk.txt` |

**Text structure** is consistent across products. Example:

```
ZCZC SPCAC1
ACUS01 KWNS 221958
SWODY1
SPC AC 221956

Day 1 Convective Outlook  
NWS Storm Prediction Center Norman OK
0256 PM CDT Fri May 22 2026

Valid 222000Z - 231200Z

...THERE IS A SLIGHT RISK OF SEVERE THUNDERSTORMS ACROSS PARTS OF
THE CENTRAL HIGH PLAINS...

...SUMMARY...
Thunderstorms capable of producing large hail and isolated severe wind
gusts will continue across parts of the central and southern High Plains
evening. A tornado may also occur in the central High Plains.

...Central and Southern High Plains...
The latest water vapor imagery shows a mid-level shortwave trough...

...Synopsis...
[more sections, each prefixed with ...HEADING...]

&&

$$
```

**Parsing rules:**

- Strip leading WMO header lines (`ZCZC`, `ACUS01`, `SWODY1`, `SPC AC`) until the product title line is reached.
- The headline (e.g., "THERE IS A SLIGHT RISK...") is bracketed by `...` and may span multiple lines.
- Sections are delimited by `...SECTION NAME...` headings.
- Body ends at `&&` and `$$`.
- Preserve the line breaks within paragraphs (this is a fixed-width product designed for monospace rendering — that aesthetic should carry into the app).

### 1.4 Issuance Schedule

SPC issues outlooks on a fixed UTC schedule. The app needs this to display "next 8:00 PM" text and to know when to auto-refresh.

| Product | Issuance Times (UTC) |
|---|---|
| Day 1 | 06:00, 13:00, 16:30, 20:00, 01:00 (next day) |
| Day 2 | 07:00, 17:30 |
| Day 3 | 08:30 |
| Day 4–8 | 09:00 |

Convert these to the user's local timezone for display. The "next" issuance is the next scheduled time strictly after `now`, accounting for day rollover.

### 1.5 Regional ("Local View") Outlook Images — keyed by WFO

The "local view" the user sees when they tap the map is **not a zoom of the national PNG**. SPC publishes a parallel set of pre-rendered regional images cropped to each NWS Weather Forecast Office's County Warning Area (CWA), with the office's coverage area highlighted (see the example screenshot of NWS Boston / BOX). These are the images to fetch for local view.

**URL pattern:**

```
https://www.spc.noaa.gov/partners/outlooks/cwa/images/{WFO}_swody{N}.png         (categorical, days 1–3)
https://www.spc.noaa.gov/partners/outlooks/cwa/images/{WFO}_swody{N}_TORN.png    (tornado prob, days 1–2)
https://www.spc.noaa.gov/partners/outlooks/cwa/images/{WFO}_swody{N}_HAIL.png    (hail prob, days 1–2)
https://www.spc.noaa.gov/partners/outlooks/cwa/images/{WFO}_swody{N}_WIND.png    (wind prob, days 1–2)
https://www.spc.noaa.gov/partners/outlooks/cwa/images/{WFO}_swody3_PROB.png      (Day 3 combined prob)
https://www.spc.noaa.gov/partners/outlooks/cwa/images/{WFO}_swody{N}_PROB.png    (Days 4–8 prob — per-day!)
```

`{WFO}` is a 3-letter office code (`BOX` = Boston, `OKX` = New York, `LWX` = Baltimore/DC, etc.).

**Important asymmetry vs. the national side:** SPC publishes **per-day** Days 4–8 regional images (`swody4_PROB.png` through `swody8_PROB.png`), even though the national product is a single combined `day48probotlk.gif`. This means:

- In **national view**, selecting any of Days 4–8 shows the same combined image (as documented in §1.1).
- In **local view**, selecting Day 4 vs. Day 5 vs. Day 6 vs. Day 7 vs. Day 8 each shows a distinct regional image.

This is a feature, not a bug — flag the difference to the user via the helper text under the day strip when they're in local view.

### 1.6 WFO Lookup from User Coordinates

To know which `{WFO}` code to use, resolve the user's location to their assigned NWS office via the NWS public API:

```
GET https://api.weather.gov/points/{lat},{lon}
```

Response is GeoJSON; the relevant field is `properties.cwa` (e.g., `"BOX"`). This mapping is stable — cache it indefinitely. Per the NWS API design, callers should set a `User-Agent` header identifying the app (`"SPCOutlookApp/1.0 (contact@example.com)"`); without it the API may rate-limit aggressively.

**Edge cases:**

- User outside CONUS (Alaska, Hawaii, territories): `cwa` will be one of the regional offices (`AFC`, `AFG`, `AJK`, `HFO`, etc.). SPC does not produce regional severe weather outlook images for non-CONUS offices, so the regional image fetch will 404. Fall back to the national view and disable the "tap for local view" action.
- User in international waters or outside the US: `/points/` returns an error. Same fallback — no local view available.
- The user moves between CWAs (e.g., travels): re-resolve the WFO whenever the user's coordinate changes by more than ~50 km.

### 1.7 Flood Risk — Separate Source (WPC)

The "Flood" row in the Local Risks panel is **not an SPC product**. SPC does not issue flood outlooks. The equivalent product is the **Weather Prediction Center's Excessive Rainfall Outlook (ERO)**:

- Image: `https://www.wpc.ncep.noaa.gov/qpf/94ewbg.gif` (Day 1 ERO)
- GeoJSON via NOAA NWS map services: `https://mapservices.weather.noaa.gov/vector/rest/services/precip/wpc_ero/MapServer`

Recommended approach: keep Flood in the UI as designed, but fetch from WPC. Flag in code that it's a separate fetch pipeline. If skipping for v1, hide the Flood row gracefully.

---

## 2. Visual Design Spec

### 2.1 Typography

- **Font family:** Courier New, fall back to `Menlo` then `Courier`.
- **Weights used:** Regular and Bold only.
- **Sizes:**
  - App title: 22pt bold
  - Section headers ("Local Risks", "Day 1 Convective Outlook"): 16pt bold
  - Body text (discussion, labels): 14pt regular
  - Helper / subtitle text ("Last Updated:", "Tap for local view..."): 13pt regular
  - Tab button labels: 13pt regular, letter-spaced

### 2.2 Color Palette

| Token | Hex | Use |
|---|---|---|
| `bg.primary` | `#000000` | Screen background |
| `bg.card` | `#141414` | Panel/card backgrounds (Local Risks, day thumbnails, body) |
| `bg.tab.selected` | `#2A2A2A` | Active GENERAL/TORNADO/HAIL/WIND button |
| `bg.tab.unselected` | `#0F0F0F` | Inactive tab buttons |
| `text.primary` | `#FFFFFF` | Headers, primary labels |
| `text.secondary` | `#A0A0A0` | Helper text, "Last Updated", inactive day labels |
| `text.tertiary` | `#5A5A5A` | Disabled states |
| `accent.risk` | `#E89B9B` | Risk percentages (Hail, Tornado, Wind values) |
| `accent.safe` | `#7CB97C` | Low-percentage "safe" values (e.g., Flood 5%) |
| `divider` | `#2A2A2A` | Subtle separators (optional) |

The risk percentage colors shift based on tier:

| Range | Color |
|---|---|
| 0% | `text.tertiary` (`#5A5A5A`) |
| 2–5% | `accent.safe` (`#7CB97C`) |
| 10–15% | `#E8C88C` (amber) |
| 30%+ | `accent.risk` (`#E89B9B`) |
| 60%+ | `#E85050` (deep red) |

### 2.3 Layout (top to bottom)

All horizontal margins: 16pt. Vertical spacing between blocks: 12pt.

1. **Header row**
   - Left: App title `SPC SEVERE WEATHER OUTLOOK` (bold) + below it `Last Updated: HH:MM AM/PM (next HH:MM AM/PM)` in secondary color.
   - Right: two square icon buttons (~36×36pt), 8pt apart: settings gear, refresh arrow. Use SF Symbols `gearshape` and `arrow.clockwise`. Background `bg.card`, corner radius 6pt, icon tint `text.primary`.

2. **Local Risks + Day Selector row** (horizontal stack, equal-ish split or 40/60)
   - **Local Risks card** (`bg.card`, 12pt internal padding, 8pt corner radius):
     - Bold header: `Local Risks`
     - Four rows: `Hail:`, `Tornado:`, `Wind:`, `Flood:` left-aligned in `text.primary`; percentage right-aligned (or simply space-padded) in the appropriate tier color.
     - Use monospace alignment — pad labels so percentages line up.
   - **Day Selector** (horizontal `ScrollView`):
     - Each cell: label `Day N` above a thumbnail of that day's categorical outlook image. ~110pt wide.
     - Selected cell: label and image full opacity. Unselected: label and image at ~45% opacity.
     - Tapping a cell changes the active day.
     - Day 1, 2, 3 visible by default; user can scroll horizontally to reach Days 4–8.

3. **Outlook title block**
   - Bold: `Day {N} Convective Outlook` (or `Day 4–8 Outlook` for those)
   - Helper text (secondary color): `Tap for local view, swipe for Day {N+1}`

4. **Main outlook image**
   - Full-width, aspect-fit. `bg.card`, 6pt corner radius.
   - Tap toggles between "full CONUS view" and "local view" (a pre-rendered SPC regional image for the user's WFO; see §3.4).
   - Swipe left/right advances/retreats the selected day.

5. **Risk tabs** (horizontal stack of 4 equal-width buttons)
   - Labels: `GENERAL`, `TORNADO`, `HAIL`, `WIND`. All uppercase, Courier New, slight letter-spacing.
   - Selected: `bg.tab.selected`, text `text.primary`.
   - Unselected: `bg.tab.unselected`, text `text.secondary`.
   - 44pt tall (Apple HIG min tappable). 6pt corner radius. 4pt gap between buttons.
   - Selecting a tab swaps the main image to the appropriate probabilistic product. `GENERAL` = categorical.

6. **Forecast discussion text block** (`bg.card`, 12pt padding)
   - Bold centered headline (the "THERE IS A SLIGHT RISK..." line). Wraps preserving Courier New monospace look.
   - Then sections, each with bold section header (`SUMMARY`, `Central and Southern High Plains`, etc.) and body text.
   - Preserve the SPC text's original line breaks (it's hand-wrapped at ~72 chars for monospace; let it wrap naturally on mobile by *not* re-wrapping — just render it as-is in a monospace font). On narrow screens this means horizontal scroll inside the card, OR the text re-flows. **Recommendation:** Re-flow for mobile — strip the SPC line breaks within paragraphs (single newlines), preserve double-newlines as paragraph breaks.

### 2.4 Interaction Details

- **Refresh button:** rotates while a fetch is in flight. On success, briefly flash a checkmark or update the "Last Updated" timestamp. On failure (no new data, or network error), show a small toast at the bottom.
- **Settings button:** Pushes a NavigationStack destination with an empty placeholder view (`Text("Settings")` or similar). Reserved for v2.
- **Tap on map:** toggles `isLocalView`. In local view, the displayed image is swapped to SPC's pre-rendered regional outlook for the user's WFO (see §1.5 and §3.4). No zoom, no projection math — just a different image file. The transition can be a simple crossfade.
- **Swipe on map:** horizontal swipe changes selected day. Use `DragGesture` with threshold (e.g., 50pt).

---

## 3. Technical Architecture

### 3.1 Stack

- **Language:** Swift 5.9+
- **UI:** SwiftUI
- **Min iOS:** 16.0 (gives us `NavigationStack`, `.task`, `ScrollView` improvements)
- **Concurrency:** async/await + structured concurrency
- **Networking:** `URLSession` (no Alamofire — keep it lean)
- **Caching:** `URLCache` for images, `FileManager` for GeoJSON, `UserDefaults` for metadata (last fetch times)
- **Location:** `CoreLocation`
- **Geometry:** `MapKit` for `MKPolygon.contains(_:)` PIP, or a small custom ray-casting PIP function
- **Persistence (v1):** none beyond caches. (v2 could add SwiftData for an issuance history.)

### 3.2 Folder Structure

```
SPCOutlook/
├── App/
│   └── SPCOutlookApp.swift         // @main entry
├── Theme/
│   ├── Color+Theme.swift
│   └── Font+Theme.swift
├── Models/
│   ├── OutlookDay.swift            // enum Day1..Day8
│   ├── RiskType.swift              // enum general/tornado/hail/wind
│   ├── OutlookSnapshot.swift       // image refs + discussion text + issuance
│   ├── LocalRisks.swift            // tornado/hail/wind/flood percentages
│   └── GeoJSON.swift               // minimal GeoJSON decoder
├── Services/
│   ├── SPCEndpoints.swift          // URL builders
│   ├── SPCNetworkService.swift     // fetch images, geojson, text
│   ├── DiscussionParser.swift      // raw text -> structured sections
│   ├── LocalRiskCalculator.swift   // PIP against polygons
│   ├── IssuanceSchedule.swift      // next-issuance calculator
│   ├── LocationService.swift       // CLLocationManager wrapper
│   └── WFOResolver.swift           // (lat, lon) -> WFO code via api.weather.gov
├── ViewModels/
│   └── OutlookViewModel.swift      // @MainActor, ObservableObject
└── Views/
    ├── ContentView.swift           // root
    ├── HeaderView.swift
    ├── LocalRisksCard.swift
    ├── DaySelector.swift
    ├── OutlookImageView.swift
    ├── RiskTabs.swift
    ├── DiscussionView.swift
    └── SettingsView.swift          // empty placeholder
```

### 3.3 Data Flow

```
┌─────────────────┐     ┌───────────────────┐     ┌──────────────┐
│ LocationService │────▶│ OutlookViewModel  │◀────│ SPC Service  │
└─────────────────┘     │  - selectedDay    │     └──────────────┘
                        │  - selectedRisk   │             │
                        │  - isLocalView    │             ▼
                        │  - snapshot       │     ┌──────────────┐
                        │  - localRisks     │     │ URLCache /   │
                        └─────────┬─────────┘     │ FileManager  │
                                  │               └──────────────┘
                                  ▼
                        ┌───────────────────┐
                        │  ContentView      │
                        │   ├ Header        │
                        │   ├ LocalRisks    │
                        │   ├ DaySelector   │
                        │   ├ OutlookImage  │
                        │   ├ RiskTabs      │
                        │   └ Discussion    │
                        └───────────────────┘
```

The ViewModel owns all state. Views are stateless reads + `@Bindable`/`@Binding` writes for tab/day selection.

### 3.4 Local View Implementation

"Local view" swaps the displayed national image for the corresponding **WFO regional image** from §1.5. No projection math, no zooming, no cropping — it's a different file. This is the entire mechanism.

Sequence on first launch:

1. `LocationService` resolves user `(lat, lon)`.
2. `WFOResolver` calls `https://api.weather.gov/points/{lat},{lon}` (with a `User-Agent` header) and reads `properties.cwa` → e.g. `"BOX"`.
3. The resolved WFO code is cached in `UserDefaults` indefinitely (re-resolve only if the user moves > 50 km from the last-resolved location).
4. `SPCEndpoints` exposes `regionalImage(day:risk:wfo:)` returning the URL from §1.5.
5. When `isLocalView == true`, the ViewModel asks for `regionalImage(...)` instead of the national URL.

If WFO resolution fails (non-CONUS, network error, `cwa` missing) OR the regional image returns 404, fall back silently to the national image and disable the local-view toggle for the session.

### 3.5 Caching Strategy

- **In-memory:** `URLCache.shared` configured to 50MB memory, 200MB disk.
- **On disk:** Cache the last-fetched GeoJSON for each (day, risk) under `Caches/spc/day{N}_{risk}.geojson`. These are small (typically <100KB).
- **Metadata in UserDefaults:**
  - `lastFetchAt: Date`
  - `lastSeenIssuanceAt: Date` (parsed from the discussion text header)
  - `localRisks: Data` (encoded `LocalRisks` struct)
- **Cache freshness:** A cached snapshot is considered fresh until the next scheduled issuance time passes. On launch, show cached data immediately, then kick off a background fetch.

### 3.6 Update Detection

To detect a new issuance without downloading the full image first:

1. Issue a `HEAD` request to the categorical image URL.
2. Compare the `Last-Modified` header to the stored `lastSeenIssuanceAt`.
3. If newer, fetch all products. Otherwise, skip.

Fallback: parse the issuance timestamp from the first few lines of the discussion text (`SPC AC 221956` → 22nd day of month, 19:56 UTC).

### 3.7 Background Refresh (optional for v1)

Register a `BGAppRefreshTask` that fires near each scheduled issuance time (06:00, 13:00, 16:30, 20:00, 01:00 UTC for Day 1). Use it only to update cached data — no notifications in v1.

### 3.8 Performance Budget

- Cold launch to visible (cached) UI: < 400ms.
- Refresh fetching all Day 1 products in parallel: < 3s on LTE.
- Memory ceiling: < 60MB resident.

Keep the dependency list at zero. Everything in this spec is achievable with the standard library + Apple frameworks.

---

## 4. Edge Cases & Error Handling

| Case | Behavior |
|---|---|
| No network on launch | Show cached snapshot if available; otherwise show a centered "No outlook available — pull to retry" message in the discussion area. |
| Image fetch succeeds but GeoJSON fetch fails | Show the image and discussion; Local Risks panel shows dashes (`---%`) for unfetchable hazards. |
| Location permission denied | Local Risks panel shows `--%` for all rows with a small tappable "Enable location" hint. |
| Day 3 selected, user taps TORNADO/HAIL/WIND | Tabs are disabled (rendered with `text.tertiary` color, no tap response). |
| Day 4–8 selected | National view: same combined image for any of 4/5/6/7/8. Local view: distinct per-day regional image. Helper text updates to match. Discussion text is from `day48otlk.txt` regardless. |
| User in a region with no severe outlook | Local Risks shows `0%` across the board, in `text.tertiary`. |
| SPC returns a stale image (issuance unchanged) | Don't update `lastFetchAt`; flash a toast on manual refresh: "No new outlook yet". |
| User is outside the CONUS | Local Risks shows `0%`. National images still viewable; local-view toggle is disabled (SPC publishes regional images only for CONUS WFOs). |
| `api.weather.gov/points/` fails or returns no `cwa` | Treat as non-CONUS — disable local view, log silently. |
| Regional image returns 404 | Fall back to national image, disable local view for this session, do not retry until next launch. |

---

## 5. Out of Scope (v1)

- Push notifications for new outlooks or high risks
- Mesoscale Discussions (separate SPC product family)
- Fire weather, winter, marine outlooks
- Historical archive browsing
- Watch/warning polygons
- Tablet-optimized iPad layout (will work, but not specifically tuned)
- Localization (English only; this is a US-only NOAA product anyway)

---

# Implementation Guide

Each step is independently buildable and testable. Don't move to step N+1 until step N's "Verify" criteria pass.

---

## Step 1 — Project Skeleton & Theme

**Goal:** A buildable SwiftUI app with the correct background, font, and color tokens.

**Tasks:**
1. Create a new iOS App project (SwiftUI, iOS 16+).
2. Add `Color+Theme.swift` with the palette from §2.2 as static `Color` extensions.
3. Add `Font+Theme.swift` with helpers like `Font.courier(_ size: CGFloat, weight: Font.Weight = .regular) -> Font` returning `Font.custom("Courier New", size: size).weight(weight)`.
4. Replace the default `ContentView` body with a black background and a single `Text("SPC SEVERE WEATHER OUTLOOK")` rendered using the Courier New bold helper.
5. Set the app to dark mode only (`.preferredColorScheme(.dark)` on root, or in Info.plist).

**Verify:**
- App launches to a pure black screen with the title in white Courier New bold.
- Font is genuinely Courier New, not the system fallback (zoom in and confirm the distinctive serifs).

---

## Step 2 — Static Layout with Mock Data

**Goal:** Build the entire UI layout with hardcoded placeholder values. No networking yet.

**Tasks:**
1. Create all view files listed in §3.2 under `Views/`. Each takes static data via initializer for now.
2. Compose them in `ContentView` inside a `ScrollView` with the spacing/margins from §2.3.
3. Use a placeholder image asset for `OutlookImageView` (a screenshot of a real SPC map dropped into Assets.xcassets).
4. Mock the discussion text with the example from §1.3.
5. Build the day thumbnails strip with 8 cells, faking the unselected ones with reduced opacity.
6. Wire up `@State` for `selectedDay`, `selectedRisk`, `isLocalView` in `ContentView`, even though they only affect appearance for now.

**Verify:**
- The screenshot from this spec is reproducible side-by-side with the running app at a glance.
- Tapping a different day visibly changes which thumbnail is highlighted.
- Tapping TORNADO/HAIL/WIND visibly changes which tab is highlighted.
- Tapping the map toggles a flag (add a temporary debug overlay to confirm).
- Scrolling Day 4–8 into view works horizontally in the day strip.

---

## Step 3 — SPC Endpoint Catalog

**Goal:** A pure, no-side-effects module that produces all the URLs the app needs.

**Tasks:**
1. Create `SPCEndpoints.swift` with static functions: `categoricalImage(day:)`, `probabilisticImage(day:risk:)`, `geoJSON(day:risk:)`, `discussionText(day:)`.
2. Encode the matrix from §1.1 and §1.2. For unsupported combinations (Day 3 TORNADO, Day 4–8 categorical), return `nil`.
3. Add unit tests covering: every supported day, every risk type, every unsupported combination returns `nil`.

**Verify:**
- All test cases pass.
- Manually paste a few returned URLs into a browser — they load real SPC content.

---

## Step 4 — Network Service & Image Fetch

**Goal:** Fetch real SPC images and render them in `OutlookImageView`.

**Tasks:**
1. Create `SPCNetworkService.swift` with async functions: `fetchImage(from: URL) async throws -> UIImage` and `fetchData(from: URL) async throws -> Data`.
2. Configure `URLCache.shared` at app launch (50MB mem / 200MB disk).
3. In `OutlookViewModel`, add `@Published var outlookImage: UIImage?` and a `loadCategorical(day:)` async method that calls the service.
4. In `ContentView`, call `.task { await viewModel.loadCategorical(day: .one) }` on appear.
5. Update `OutlookImageView` to render `viewModel.outlookImage` via `Image(uiImage:)` with a `ProgressView` placeholder while nil.

**Verify:**
- Cold-launching the app shows a spinner briefly, then the real current SPC Day 1 categorical outlook.
- Killing the app and relaunching shows the image faster (cache hit). Confirm via a print statement on a custom `URLSessionDataDelegate` or via Instruments.
- Airplane mode launch: previously cached image still renders.

---

## Step 5 — Day Selector Wiring

**Goal:** Selecting a day fetches and displays that day's categorical image.

**Tasks:**
1. In `OutlookViewModel`, replace `loadCategorical(day:)` with a more general `load(day:risk:)` that resolves the URL via `SPCEndpoints`.
2. Re-trigger the load whenever `selectedDay` or `selectedRisk` changes (use `onChange` in the view, or `Combine`/`@Observable` reactions).
3. Fetch each day's *thumbnail* image (use the same categorical image, scaled down) for the day strip. Cache aggressively.
4. Handle the Days 4–8 case: regardless of which of 4/5/6/7/8 is selected, fetch `day48probotlk.gif`.

**Verify:**
- Tapping Day 2 loads the Day 2 categorical image. Same for Days 3–8.
- Tapping any of Days 4–8 loads the same combined image.
- The day strip thumbnails show the real SPC images at low fidelity.

---

## Step 6 — Risk Tab Wiring

**Goal:** Tabs switch between general (categorical) and probabilistic outlooks.

**Tasks:**
1. Wire `selectedRisk` into the `load(day:risk:)` call.
2. Disable TORNADO/HAIL/WIND when `selectedDay == .three` or any of `.four` through `.eight`. Render them in `text.tertiary` and ignore taps.
3. Reset `selectedRisk` back to `.general` when changing to an incompatible day.

**Verify:**
- On Day 1, tapping TORNADO loads the tornado probabilistic image. Same for HAIL, WIND.
- On Day 3, TORNADO/HAIL/WIND are visually disabled and unresponsive.
- Switching from Day 1 TORNADO to Day 3 snaps back to GENERAL and loads the Day 3 categorical image.

---

## Step 7 — Discussion Text Fetch & Parse

**Goal:** Display the real SPC forecast discussion under the map.

**Tasks:**
1. Add `fetchDiscussion(day:) async throws -> String` to `SPCNetworkService`.
2. Create `DiscussionParser.swift` that takes the raw text and returns a struct:
   ```swift
   struct ParsedDiscussion {
       let headline: String      // "THERE IS A SLIGHT RISK..."
       let issuance: Date?       // parsed from header
       let sections: [Section]   // [Section(title: "SUMMARY", body: "...")]
   }
   ```
3. Parser rules from §1.3: strip WMO header, capture `...HEADLINE...` between triple-dots until next blank line, then capture each `...SECTION...` block until `&&`.
4. Re-flow paragraphs: replace single `\n` within a paragraph with a space; preserve double `\n` as paragraph breaks.
5. Render in `DiscussionView`: headline centered bold, sections as bold title + body.

**Verify:**
- Discussion text matches what's shown on `spc.noaa.gov/products/outlook/day1otlk.html` (modulo formatting).
- Switching days loads the corresponding discussion.
- For Day 4–8, the combined Day 4–8 discussion appears.
- Issuance timestamp is correctly parsed (log it; verify against the SPC page).

---

## Step 8 — Issuance Schedule & Header Timestamps

**Goal:** The "Last Updated: X (next Y)" line is real.

**Tasks:**
1. Create `IssuanceSchedule.swift` with the table from §1.4 as UTC `(hour, minute)` tuples per day product.
2. Add `nextIssuance(for product:, after now: Date) -> Date` that returns the next scheduled UTC time, rolled to tomorrow if needed.
3. In the ViewModel, expose `lastUpdatedString` and `nextIssuanceString` formatted as `h:mm a` in the user's local timezone.
4. Render in `HeaderView`.

**Verify:**
- Header reads e.g. `Last Updated: 3:56 PM (next 8:00 PM)` and matches the SPC schedule when you spot-check against the website's "Issued at" line.
- After local clock crosses the next issuance time, the strings update (manually advance the device clock to confirm).

---

## Step 9 — Manual Refresh Button

**Goal:** Tapping refresh re-fetches and updates state.

**Tasks:**
1. Wire the refresh button to call `viewModel.refresh()`.
2. `refresh()` should issue HEAD requests on the categorical image first, compare `Last-Modified` to stored `lastSeenIssuanceAt`, and only do the full re-download if newer (or if forced — make the manual refresh always force).
3. Animate the refresh icon rotating during the in-flight period (`ProgressView` swap, or `.rotationEffect` driven by a `@State` Bool).
4. Show a transient toast on completion: either "Updated" or "No new outlook yet".

**Verify:**
- Tap refresh — icon spins, "Last Updated" timestamp refreshes.
- Tap refresh again quickly — toast says "No new outlook yet".
- Throttle network in Charles/Instruments to simulate slow connection; confirm the UI doesn't lock up.

---

## Step 10 — Location Services & WFO Resolution

**Goal:** Get the user's `(lat, lon)` and resolve it to their NWS Weather Forecast Office code.

**Tasks:**
1. Add `NSLocationWhenInUseUsageDescription` to Info.plist: "Used to show severe weather risks at your location."
2. Create `LocationService.swift`, a thin `CLLocationManager` wrapper exposing `@Published var coordinate: CLLocationCoordinate2D?` and async `requestLocation()`.
3. Use `kCLLocationAccuracyKilometer` (or coarser) — we don't need precision better than ~10km for risk polygons.
4. On first launch, request `whenInUse` authorization. On subsequent launches with permission already granted, just request location.
5. Create `WFOResolver.swift`:
   - `func resolve(coordinate: CLLocationCoordinate2D) async throws -> String` — calls `https://api.weather.gov/points/{lat},{lon}`, parses `properties.cwa`, returns the 3-letter code.
   - Set `User-Agent: "SPCOutlookApp/1.0 (contact@example.com)"` on every request (NWS API requirement).
   - Cache the resolved WFO code in `UserDefaults` along with the coordinate it was resolved for. Skip re-resolution if the user has moved less than 50 km from the cached coordinate.
   - On failure (network, missing `cwa`, non-CONUS office), return `nil` and let the caller fall back.
6. Inject both services into the ViewModel. Expose `@Published var wfo: String?` on the ViewModel.

**Verify:**
- On first launch, the permission prompt appears.
- After granting, `viewModel.userCoordinate` is non-nil within a few seconds.
- Shortly after, `viewModel.wfo` is set to a 3-letter code (e.g., `"BOX"` from a Boston location in the simulator).
- Force-quit and relaunch: WFO is hydrated from `UserDefaults` without a new API call (verify via Charles or print logging).
- Override simulator location to somewhere in Hawaii or international waters: `viewModel.wfo` stays nil or resolves to a non-CONUS office; either way the app continues to function.
- Denying location permission: both `userCoordinate` and `wfo` remain nil; the app continues to function.

---

## Step 11 — Local Risk Calculation (PIP)

**Goal:** Local Risks panel shows real percentages based on user coordinates.

**Tasks:**
1. Create `GeoJSON.swift` with `Codable` structs for `FeatureCollection`, `Feature`, `Geometry` (Polygon and MultiPolygon).
2. Create `LocalRiskCalculator.swift`:
   - `func calculate(at coordinate: CLLocationCoordinate2D, day: OutlookDay) async throws -> LocalRisks`
   - Fetches the three GeoJSON files for tornado/hail/wind in parallel via `async let`.
   - For each layer, sorts features by probability tier descending, runs PIP on each polygon, returns the first match.
3. PIP implementation: ray-casting algorithm in pure Swift. Polygons are small (a few thousand vertices total per file) — performance is a non-issue. Or use `MKPolygon` constructed from the coordinates and call `.contains(_:)` after converting via `MKMapPoint`.
4. The "SIGN" / significant feature should be tracked separately as a boolean flag per hazard for future use, but the displayed percentage stays the underlying tier (`10%`, `15%`, etc.).
5. Wire into the ViewModel: when `selectedDay == .one` and `userCoordinate != nil`, recompute on day change and after each refresh.
6. The Flood row: in v1, hardcode `--%` (or fetch from WPC if implementing §1.7 now).

**Verify:**
- Place a fake user location inside a known risk polygon (e.g., the current Day 1 slight risk area — find one from spc.noaa.gov) by overriding the location in the simulator's debug menu.
- Local Risks panel should show the corresponding percentages.
- Move the fake location outside any polygons → percentages all read `0%`.
- Confirm percentages match by visually inspecting the published probabilistic outlook image for that lat/lon.

---

## Step 12 — Tap-to-Local-View (Regional Image Swap)

**Goal:** Tapping the map swaps the displayed image to SPC's pre-rendered regional outlook for the user's WFO. Tapping again swaps back to the national CONUS image.

**Tasks:**
1. Extend `SPCEndpoints` with `regionalImage(day:risk:wfo:)` returning the URL pattern from §1.5. Return `nil` if either `wfo` is missing or the (day, risk) combination isn't supported regionally.
2. Add `@Published var isLocalView: Bool` to `OutlookViewModel`. Add a `currentImageURL` computed property that returns the regional URL when `isLocalView && wfo != nil`, otherwise the national URL.
3. Wire the tap gesture on `OutlookImageView` to toggle `isLocalView`. Disable the gesture (and grey out a "Tap for local view" hint) when `wfo == nil`.
4. When the regional image fetch returns a 404 or any error, fall back to the national image, set a session flag to disable further local-view toggling, and surface a small one-time toast: "Regional outlook not available for your area."
5. Animate the swap with a crossfade (`.transition(.opacity)` on the `Image`).
6. Update the helper text under the day strip:
   - National view + Days 1–3: `Tap for local view, swipe for Day {N+1}`
   - National view + Days 4–8: `Days 4–8 share a combined outlook`
   - Local view + any day: `Showing {WFO} region — tap to return`

**Verify:**
- Simulator location set to Boston: tapping the map shows the BOX regional severe weather outlook (the highlighted-area graphic with Boston, Worcester, Providence, etc. labeled). Tapping again returns to the national image.
- Switching to Day 4 while in local view shows the per-day BOX regional Day 4 image (different from Day 5).
- Override simulator location to Hawaii: tap gesture does nothing, "Tap for local view" hint is greyed out.
- Force a 404 (point at a known-bad WFO via a debug override): app crossfades back to the national image with the toast shown once, then the toggle is disabled for the rest of the session.

---

## Step 13 — Swipe to Change Day

**Goal:** Horizontal swipe on the main image advances/retreats the selected day.

**Tasks:**
1. Add `DragGesture(minimumDistance: 30)` to `OutlookImageView`.
2. On `.onEnded`, if horizontal translation > 50pt and dominant axis is horizontal, decrement `selectedDay`; if < -50pt, increment. Clamp to Day 1–8.
3. Coordinate with `isLocalView` — swipe still changes day; the swap fetches the regional version of the new day's image.

**Verify:**
- Swipe left on Day 1 image → advances to Day 2.
- Swipe right on Day 2 → back to Day 1.
- Bounds clamp correctly (can't go below 1 or above 8).

---

## Step 14 — Settings Page (Placeholder)

**Goal:** Settings button leads to an empty navigation destination.

**Tasks:**
1. Wrap the root in `NavigationStack`.
2. Settings button uses a `NavigationLink` to `SettingsView`.
3. `SettingsView` is just `Text("Settings").foregroundStyle(.secondary)` for now, with a proper navigation title.

**Verify:**
- Tap settings → pushes to a near-empty screen with "< Back" in the nav bar.
- Tap back → returns cleanly to the main view, preserving all state (selected day, risk, scroll position).

---

## Step 15 — Persistence & Cold-Launch UX

**Goal:** App launches instantly showing the last-seen state, then quietly updates.

**Tasks:**
1. Persist last fetched `(selectedDay, selectedRisk, lastUpdatedAt, localRisks, parsedDiscussion)` to `UserDefaults` (encode via JSON).
2. Persist the categorical image to a file under `Caches/spc/`.
3. On launch, hydrate the ViewModel from this cache *before* any network call.
4. Then kick off a HEAD-based check in the background; if newer, re-fetch silently.

**Verify:**
- Kill the app, relaunch in airplane mode — full UI is visible immediately with stale data.
- Disable airplane mode, wait a moment — the app silently updates without a visible flicker, and "Last Updated" timestamp refreshes.

---

## Step 16 — Error & Edge States

**Goal:** Cover all rows in the §4 table.

**Tasks:**
1. For each row in the edge case table, add a code path or UI state and test it.
2. Add a simple `ToastView` for transient messages (network errors, "No new outlook yet").
3. Add a "no data" empty state for the discussion view.

**Verify:**
- Manually exercise each edge case in §4 (airplane mode, location denied, Day 3 tab disable, etc.) and confirm graceful behavior.

---

## Step 17 — Polish Pass

**Goal:** Match the design pixel-close.

**Tasks:**
1. Side-by-side the design screenshot with the running app at every screen state. Tune padding, font sizes, opacities until they match.
2. Verify the risk percentage colors shift correctly with the tier ramp from §2.2.
3. Add subtle haptic feedback on tab switches and day selection (`UIImpactFeedbackGenerator(style: .light)`).
4. Verify all interactive elements meet the 44×44pt tap target.
5. Test on the smallest supported device (iPhone SE) and verify nothing overflows.

**Verify:**
- A reasonable person comparing the design and the app cannot tell them apart on a phone in hand.

---

## Step 18 — (Optional) WPC Flood Integration

**Goal:** Make the Flood row real.

**Tasks:**
1. Add WPC ERO fetch via the NOAA MapServer GeoJSON endpoint (§1.7).
2. Same PIP logic, just a separate layer.
3. Plug the result into the Flood row.

**Verify:**
- Flood percentage matches the WPC ERO for the user's location, cross-referenced against `wpc.ncep.noaa.gov/qpf/ero.shtml`.

---

## Step 19 — (Optional) Background Refresh

**Goal:** App refreshes its cache around scheduled SPC issuance times.

**Tasks:**
1. Add Background Modes → Background fetch + Background processing capability.
2. Register a `BGAppRefreshTaskRequest` scheduled for the next issuance time.
3. In the handler, run the same HEAD-check + fetch logic as the manual refresh, then re-schedule.

**Verify:**
- Use Xcode's `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"..."]` to simulate the task firing, and confirm the cache updates.

---

## Done

When steps 1–17 pass, you have a v1. Steps 18 and 19 are independent and can be added in any order.