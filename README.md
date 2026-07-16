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
| Launch in a new window (current Space) | Cmd+Return |
| Dismiss panel | Escape |
| Open settings | Cmd+, |

### Launch in a new window (Cmd+Return)

Plain **Return** activates the app, bringing an existing window forward — which,
under focus-following window managers like [AeroSpace](https://github.com/nikitabobko/AeroSpace),
switches you to whatever workspace that window lives in.

**Cmd+Return** instead opens a *new* window of the app in your **current** Space.
The first time you do this for a given app, macOS asks permission for Lightning to
control it (Automation) — approve it once and it works from then on. Apps that
don't support scripted new windows fall back to opening a fresh instance.

## Development

```bash
mise install     # Install dev tools (swiftlint, swiftformat)
just build       # Debug build
just release     # Release build
just test        # Run unit tests
just lint        # Lint Swift sources
just format      # Format Swift sources
just clean       # Clean build artifacts
just bundle      # Create .app bundle
```

## Requirements

- macOS 13.0+
- Swift 5.9+
- [mise](https://mise.jdx.dev) (for dev tools)
