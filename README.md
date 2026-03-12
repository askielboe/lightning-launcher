# Lightning

A fast macOS application launcher.

![Search](screenshots/search.png)

## Features

- **Instant search** — Fuzzy matching with typo tolerance across all installed apps
- **Smart ranking** — Frecency tracking with adaptive per-query learning
- **Real-time monitoring** — Detects newly installed/removed apps within seconds
- **Lightweight** — No Dock icon, lives in the menu bar

## Screenshots

| Search | Settings |
|--------|----------|
| ![Search](screenshots/search.png) | ![Settings](screenshots/settings.png) |

## Quick Start

```bash
# Build and run
just run

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
| Open settings | Cmd+, |

## Development

```bash
just build      # Debug build
just release    # Release build
just test       # Run unit tests
just clean      # Clean build artifacts
just bundle     # Create .app bundle
```

## Requirements

- macOS 13.0+
- Swift 5.9+
