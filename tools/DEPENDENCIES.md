# Dependencies Allowlist & Review

This document tracks third-party dependencies and the review checklist.

## Allowlist (current)
- flutter_riverpod: State management (active maintenance, permissive license)
- window_manager: Desktop window controls
- cached_network_image: Image caching (planned/if used)
- go_router: Routing (planned/if adopted)

## Review Checklist (must be filled in PR)
- Necessity: Why is this needed vs official API?
- Size & cold start impact
- Maintenance activity and bus factor
- License and compatibility
- Alternatives considered and trade-offs
- Removal strategy and migration cost