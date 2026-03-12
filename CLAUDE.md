# Lightning Launcher

## Performance is the #1 priority

Performance is ALWAYS the number 1 priority, far above anything else. This is a launcher app — every millisecond of latency is felt by the user.

- ALWAYS review ANY code change for performance impact before considering it done.
- Identify the hot path (keystroke -> search -> render) and never add unnecessary work to it.
- Avoid allocations in loops (pre-compute, cache, snapshot).
- Avoid lock acquisition per-entry (snapshot once, iterate lock-free).
- Avoid reading UserDefaults, spawning processes, or doing I/O on the hot path unless proven negligible.
- Avoid SwiftUI structural view changes (conditional `if` adding/removing views) on every keystroke.
- When adding any feature, ask: "Does this touch the search hot path? If so, what's the per-keystroke cost?"
