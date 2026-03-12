# Lightning - macOS Application Launcher

default:
    @just --list

# Build in debug mode
build:
    swift build

# Build in release mode
release:
    swift build -c release

# Run the app in debug mode
run:
    swift build && .build/debug/Lightning

# Run tests
test:
    swift test

# Clean build artifacts
clean:
    swift package clean
    rm -rf .build

# Create Lightning.app bundle from release build
bundle:
    bash Scripts/bundle.sh

# Resolve package dependencies
resolve:
    swift package resolve
