# ⚡️ Lightning Launcher

A fast macOS application launcher.

<img width="726" height="459" alt="image" src="https://github.com/user-attachments/assets/e0098a45-103b-4f6c-97db-ffe4d3d59ac0" />

## Features

- **Instant search** — Fuzzy matching with typo tolerance across all installed apps
- **Smart ranking** — Frecency tracking with adaptive per-query learning
- **Real-time monitoring** — Detects newly installed/removed apps within seconds
- **Configurable** — Custom search paths

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
