# Lightning

A fast macOS application launcher that bypasses Spotlight entirely, using direct filesystem enumeration and real-time monitoring for instant application discovery with sub-millisecond fuzzy search.

## Features

- **Instant search** — Fuzzy matching with typo tolerance across all installed apps
- **Smart ranking** — Frecency tracking (recency + frequency) with adaptive per-query learning
- **Real-time monitoring** — Detects newly installed/removed apps within seconds via kqueue, FSEvents, and NSWorkspace
- **Floating panel** — Non-activating HUD-style overlay, summoned with a global hotkey
- **Lightweight** — No Dock icon, lives in the menu bar, <30MB memory footprint
- **No permissions needed** — Uses Carbon hotkey API (no Accessibility permission required)

## Requirements

- macOS 13.0+
- Swift 5.9+

## Quick Start

```bash
# Build and run
just run

# Run tests
just test

# Create Lightning.app bundle
just bundle
```

## Usage

| Action | Key |
|--------|-----|
| Toggle search panel | Option+Space (configurable) |
| Navigate results | Arrow Up / Arrow Down |
| Launch selected app | Return |
| Dismiss panel | Escape |

The menu bar icon provides access to Settings, where you can:
- Configure the global hotkey
- Set the maximum number of results (4-12)
- Add additional search directories
- Enable launch at login

## Architecture

- **NSPanel** — Pre-warmed floating panel (show/hide, never create/destroy)
- **Direct filesystem scan** — Enumerates `/Applications`, `/System/Applications`, `~/Applications`, and cloud storage
- **5-strategy fuzzy matcher** — Prefix, word-boundary initials, substring, subsequence, edit-distance
- **Frecency + adaptive learning** — Exponential decay with 7-day half-life, per-prefix selection tracking
- **Actor-based icon cache** — Thread-safe async loading at 32x32
- **Triple monitoring** — kqueue for flat dirs, FSEvents for deep hierarchies, NSWorkspace for runtime events

## Project Structure

```
Sources/Lightning/
├── main.swift                  # NSApplication bootstrap
├── LightningApp.swift          # AppDelegate, lifecycle
├── Panel/                      # Floating search panel
├── Views/                      # SwiftUI views + view model
├── HotKey/                     # Global hotkey (Option+Space)
├── Index/                      # App entry, scanner, index
├── Search/                     # Fuzzy matcher, search engine, scoring
├── Ranking/                    # Frecency, adaptive learning, persistence
├── Monitor/                    # Directory, FSEvents, workspace monitors
├── Launch/                     # NSWorkspace app launcher
├── Settings/                   # Settings UI + preferences
└── Icons/                      # Actor-based icon cache
```

## Development

```bash
just build      # Debug build
just release    # Release build
just test       # Run unit tests
just clean      # Clean build artifacts
just resolve    # Resolve dependencies
just bundle     # Create .app bundle
```
