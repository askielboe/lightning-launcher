# Lightning-Fast Application Launcher: SOTA Research & Implementation Plan (2026)

## Executive Summary

This document presents a comprehensive state-of-the-art analysis and
implementation plan for building a macOS application launcher from scratch — one
that delivers **instant application discovery** and **sub-millisecond search**,
eliminating the stale-index problem that plagues Alfred and Spotlight-dependent
launchers.

The key insight from 2025-2026 research: **don't depend on Spotlight/mdutil at
all for application discovery.** Instead, combine real-time filesystem
monitoring (FSEvents + GCD DispatchSource) with an in-memory index and
frecency-based ranking. Raycast proved this viable on macOS, and when they built
for Windows (where no system-wide index exists), they built their own custom
indexer from scratch that "scans files in real-time and delivers instant
results."

---

## 1. Landscape Analysis: How Current Launchers Work

### Alfred (Incumbent)

- Depends entirely on **macOS Spotlight (mdutil)** for file/app indexing
- Maintains its own **application cache** on top of Spotlight
- Cache refresh is manual: user types `reload` to force rescan
- **Root cause of staleness**: FSEvents → Spotlight daemon → Spotlight index →
  Alfred cache poll → result. Multiple layers of indirection with no guaranteed
  latency.

### Raycast (SOTA competitor)

- On macOS: also uses **Spotlight index for file search** but has an independent
  app discovery layer
- On Windows: built a **completely custom real-time indexer** because Windows
  Search didn't meet their standards
- Uses incremental search with predictive ranking
- Extensions built in React/TypeScript (extension ecosystem model)
- Closed-source core

### Verve (Open-source reference)

- **Rust + Tauri + Svelte** — proof that the stack works
- Lightweight, fast binary using OS webview (no Electron)
- Early-stage; basic app enumeration without sophisticated indexing
- AGPL-licensed

### Spotlight / Launchpad (Apple native)

- macOS Tahoe (26) replaced Launchpad with a new "Applications" interface
  integrated into Spotlight
- System-level FSEvents → fseventsd → .Spotlight-V100 database → mdworker
- Can take up to an hour to reindex after corruption
- Spotlight Privacy list trick (add → remove folder) forces reindex of specific
  paths

---

## 2. Core Architecture: The Instant-Update Index

### 2.1 Application Discovery (Bypass Spotlight Entirely)

Instead of waiting for Spotlight to notice new apps, scan directly:

```
Startup:
  1. Enumerate /Applications, /System/Applications, ~/Applications,
     /System/Cryptexes/App, ~/Library/CloudStorage/*/Applications
  2. For each .app bundle: read Info.plist → extract CFBundleName,
     CFBundleIdentifier, CFBundleIconFile/CFBundleIconName
  3. Load into in-memory index (HashMap<String, AppEntry>)
  4. Start FSEvents watchers on all scanned directories

Runtime:
  FSEvents callback fires → diff new state vs cached state →
  update index in-place → UI is immediately current
```

**Key macOS APIs for direct enumeration:**

| API                                                           | Purpose           | Notes                                |
| ------------------------------------------------------------- | ----------------- | ------------------------------------ |
| `FileManager.enumerator(at:)`                                 | Scan .app bundles | Use `.skipsPackageDescendants`       |
| `Bundle(url:)`                                                | Read Info.plist   | Gets bundleIdentifier, executableURL |
| `NSWorkspace.shared.icon(forFile:)`                           | App icons         | Returns NSImage                      |
| `NSWorkspace.shared.urlForApplication(withBundleIdentifier:)` | Resolve app paths | Forward lookups                      |

### 2.2 Real-Time Filesystem Monitoring

Three tiers of monitoring, from cheapest to most powerful:

**Tier 1: GCD DispatchSource (kqueue-based, lowest overhead)**

- Monitors individual directories for write/rename/delete events
- Ideal for `/Applications` (flat, rarely changes)
- No recursive support — monitor top-level only
- Fires within milliseconds of filesystem change
- Use `O_EVTONLY` flag for event-only file descriptors

```swift
let fd = open("/Applications", O_EVTONLY)
let source = DispatchSource.makeFileSystemObjectSource(
    fileDescriptor: fd,
    eventMask: [.write, .rename, .delete],
    queue: DispatchQueue(label: "app-monitor")
)
source.setEventHandler { [weak self] in
    self?.rescanDirectory(URL(fileURLWithPath: "/Applications"))
}
source.resume()
```

**Tier 2: FSEvents (for recursive monitoring)**

- Watches entire directory hierarchies
- Configurable latency (set to 0.1s for near-instant)
- Coalesces events; may miss rapid intermediate states
- Use `kFSEventStreamCreateFlagFileEvents` for per-file granularity (macOS
  10.7+)
- Use for `~/Library/CloudStorage/` and deeper hierarchies

**Tier 3: NSWorkspace notifications (app lifecycle events)**

- `NSWorkspace.didLaunchApplicationNotification` — app launched
- `NSWorkspace.didTerminateApplicationNotification` — app quit
- Useful for tracking running state, not discovery per se

**Recommended combination:**

- DispatchSource on `/Applications`, `/System/Applications`, `~/Applications`
- FSEvents on `~/Library/CloudStorage/` and any user-added search paths
- NSWorkspace notifications for running-app awareness
- Periodic full rescan every 5 minutes as a safety net

### 2.3 In-Memory Index Structure

```
AppEntry {
    name: String           // CFBundleName / display name
    bundle_id: String      // com.example.app
    path: URL              // /Applications/Foo.app
    icon: NSImage          // cached icon
    keywords: [String]     // name tokens, bundle_id tokens
    frecency_score: f64    // combined frequency + recency
    last_launched: Date?
    launch_count: u32
}

Index {
    apps: HashMap<String, AppEntry>          // bundle_id → entry
    trigram_index: HashMap<String, Vec<String>>  // "chr" → ["com.google.Chrome", ...]
    prefix_tree: Trie<AppEntry>              // for prefix matching
}
```

---

## 3. Search & Ranking

### 3.1 Fuzzy Matching Algorithm

For a launcher with ~200-2000 entries, linear scan with a good scoring function
is fast enough (sub-millisecond on Apple Silicon). No need for inverted indexes
at this scale.

**Recommended: Modified Sellers / Damerau-Levenshtein with positional bonuses**

Scoring factors (ordered by importance):

1. **Exact prefix match** (highest): query "chr" matches "Chrome" → score 1.0
2. **Word-boundary match**: query "vs" matches "Visual Studio Code" (initials) →
   score 0.9
3. **Substring match**: query "ome" matches "Chrome" → score 0.7
4. **Fuzzy/typo-tolerant**: query "chrom" matches "Chrome" with edit distance
   0-1 → score 0.5-0.8
5. **Frecency boost**: multiply by frecency factor (0.5-2.0x)

**Word-boundary / camelCase splitting is critical.** Users type "gc" and expect
"Google Chrome", or "vs" for "VS Code". Split app names on spaces, hyphens,
dots, and camelCase boundaries, then match query characters against the
initials.

### 3.2 Frecency Ranking

Frecency (frequency + recency) is the SOTA ranking heuristic for launchers.
Mozilla formalized this for Firefox's AwesomeBar; it's now standard in fzf,
zoxide, and every serious launcher.

**Algorithm (exponential decay model):**

```
score(app) = Σ weight(launch_i) * e^(-λ * (t_now - t_launch_i))

where:
  λ = ln(2) / half_life
  half_life = 7 days (configurable)
  weight = 1.0 for keyboard launch, 0.5 for other
```

**Simplified rolling average (recommended for simplicity):**

```
On each launch of app:
    app.frecency = app.frecency * decay_factor + boost
    app.last_launched = now

On each query:
    effective_score = app.frecency * e^(-λ * days_since_last_launch)
```

**Persistence:** Store frecency data in a simple JSON or SQLite file in
`~/Library/Application Support/YourLauncher/frecency.json`. Load at startup,
flush periodically.

### 3.3 Adaptive Learning

Track which result the user selects for a given query prefix. Over time, for
query "ch" → if user always picks Chrome over Chess, promote Chrome for that
prefix. This is a lightweight per-prefix frequency table.

---

## 4. Technology Stack Decision

### Option A: Native Swift + SwiftUI (Recommended)

| Pros                                   | Cons                                   |
| -------------------------------------- | -------------------------------------- |
| Direct access to all macOS APIs        | macOS-only                             |
| Best performance (no webview overhead) | SwiftUI still maturing for complex UIs |
| NSPanel for borderless floating window | Larger binary than Tauri               |
| Accessibility support built-in         |                                        |
| Xcode tooling, Instruments profiling   |                                        |

### Option B: Rust + Tauri v2 + Svelte/Solid

| Pros                                      | Cons                             |
| ----------------------------------------- | -------------------------------- |
| Cross-platform potential                  | Webview adds latency (~5-10ms)   |
| Rust for core indexer (memory-safe, fast) | macOS API access requires FFI    |
| Tiny binaries (uses OS webview)           | Two-language bridge (Rust ↔ JS) |
| Verve proves the architecture works       |                                  |

### Option C: Hybrid (Rust core + Swift UI)

| Pros                                                  | Cons                 |
| ----------------------------------------------------- | -------------------- |
| Best of both: Rust performance for indexer, native UI | Complex build system |
| Can share Rust core cross-platform later              | Bridging overhead    |
| Ockam/Portals proved this works in production         |                      |

**Recommendation:** Start with **pure Swift/SwiftUI** for fastest time-to-value
on macOS. The app list is small enough that Swift's performance is more than
adequate. If cross-platform becomes a goal later, extract the indexer into Rust.

---

## 5. UI Architecture

### 5.1 Window Management

Use `NSPanel` (not `NSWindow`) for a launcher:

- `.nonActivating` style — doesn't steal focus from current app
- Level: `.floating` or `.popUpMenu`
- `NSVisualEffectView` for vibrancy/blur background
- Dismiss on deactivation (`hidesOnDeactivate = true`)

### 5.2 Hotkey Registration

Use `CGEvent.tapCreate()` or the `MASShortcut` / `HotKey` library for global
hotkey registration. The default should be `⌥ Space` (Option+Space) — the de
facto standard.

### 5.3 Rendering

- **Input field**: `NSTextField` with custom styling, large font (18-22pt)
- **Results list**: `NSTableView` or SwiftUI `List` — max 6-8 visible results
- **Icons**: Pre-cached at 32×32 or 48×48 from
  `NSWorkspace.shared.icon(forFile:)`
- **Animate**: Subtle fade-in on show, immediate dismiss on selection

### 5.4 Performance Targets

| Metric               | Target  | How                                   |
| -------------------- | ------- | ------------------------------------- |
| Hotkey to visible    | < 50ms  | Pre-warm window, just show/hide       |
| Keystroke to results | < 5ms   | In-memory index, main thread          |
| New app discovery    | < 1s    | DispatchSource → rescan → update      |
| Cold start           | < 200ms | Lazy icon loading, async index build  |
| Memory footprint     | < 30MB  | Only index metadata, not file content |

---

## 6. Implementation Roadmap

### Phase 1: Core (Week 1-2)

- [ ] Swift project setup, NSPanel floating window, global hotkey
- [ ] Application scanner: enumerate all .app bundles from standard paths
- [ ] In-memory index with prefix matching
- [ ] Basic NSTextField input → live-filtered results list
- [ ] DispatchSource watchers on /Applications, ~/Applications
- [ ] Launch selected app via NSWorkspace.open()

### Phase 2: Smart Ranking (Week 3)

- [ ] Frecency tracking: persist launch history, decay-weighted scoring
- [ ] Fuzzy matching: Damerau-Levenshtein with word-boundary bonuses
- [ ] Adaptive per-prefix learning
- [ ] Icon caching and async loading

### Phase 3: Polish (Week 4)

- [ ] Visual design: vibrancy, smooth animations, dark/light mode
- [ ] Settings panel: custom search paths, hotkey configuration
- [ ] Homebrew Cask integration (detect brew-installed apps)
- [ ] Login item configuration (launch at startup)
- [ ] Error handling, crash resilience, edge cases

### Phase 4: Extensions (Month 2+)

- [ ] Calculator inline
- [ ] System commands (sleep, lock, restart, empty trash)
- [ ] File search (optional Spotlight integration for files, not apps)
- [ ] Clipboard history
- [ ] Plugin architecture (Swift Package-based or script commands)

---

## 7. Open-Source References

| Project            | Stack             | Stars | Notes                                              |
| ------------------ | ----------------- | ----- | -------------------------------------------------- |
| **Verve**          | Rust/Tauri/Svelte | ~730  | Closest reference architecture                     |
| **Cling**          | Swift             | —     | "Instant fuzzy find any file"                      |
| **LaunchpadPlus**  | Swift/SwiftUI     | ~110  | Modern Launchpad replacement                       |
| **fre**            | Rust              | —     | Frecency CLI, excellent algorithm reference        |
| **fast-fuzzy**     | TypeScript        | —     | Modified Sellers algorithm, good scoring reference |
| **dmenu-frecency** | Python            | —     | Simple frecency launcher for X11/Wayland           |
| **Witness**        | Swift             | —     | FSEvents wrapper for Swift                         |

---

## 8. Key Technical Risks & Mitigations

**Risk: macOS sandboxing restrictions** Some app directories may require Full
Disk Access. Mitigation: Request minimal permissions, fall back gracefully if
directories are inaccessible.

**Risk: FSEvents coalescing misses rapid install/uninstall** Mitigation:
Periodic full rescan (every 5 min) as safety net. Also catch NSWorkspace
app-launch notifications as a secondary signal.

**Risk: App relocation (e.g., App Store updates change app paths)** Mitigation:
Key index by bundle identifier, not path. Re-resolve paths on each scan.

**Risk: Performance on machines with thousands of .app bundles** Mitigation: At
10,000 apps (extreme case), linear scan with Damerau-Levenshtein is still < 1ms
on M1. If needed, add trigram index.

---

## 9. Conclusion

The path to an instant-update launcher is clear: **bypass Spotlight for
application discovery entirely.** Use direct filesystem enumeration at startup,
real-time DispatchSource/FSEvents monitoring for changes, and an in-memory index
with frecency-weighted fuzzy matching. This architecture eliminates every layer
of indirection that makes Alfred feel sluggish when discovering new apps.

The recommended stack is **native Swift + SwiftUI**, targeting a working
prototype in 2-4 weeks. The core insight — that you only need to index a few
hundred .app bundles, not the entire filesystem — means the entire index fits
comfortably in memory and can be rebuilt from scratch in under 100ms.
