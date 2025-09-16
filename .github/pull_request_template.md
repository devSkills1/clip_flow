# Pull Request Template

## Summary
- [ ] Purpose and scope of this PR
- [ ] Related issues/links

## Checklists
- [ ] Lint passed (flutter analyze)
- [ ] Formatted and fixes applied (dart format --fix && dart fix --apply)
- [ ] Tests passed and coverage threshold met (global ≥70%, core ≥80%)
- [ ] No deprecated API used
- [ ] No hard-coded secrets or magic numbers (moved to constants/tokens)
- [ ] Dependency review (if applies)
- [ ] i18n: Strings from ARB (no hard-coded strings)

## Dependency Review (fill if adding/upgrading deps)
- Necessity and alternatives:
- Size & cold start impact:
- Maintenance activity & bus factor:
- License compatibility:
- Removal strategy & migration cost:

## Performance & Observability
- [ ] Perf impact evaluated (DevTools/frames)
- [ ] Logs minimal and sanitized
- [ ] APM/metrics updated if needed

## Security & Migration
- [ ] Security impact assessed (storage/network)
- [ ] Migrations documented and reversible
- [ ] Rollback strategy provided

## Screenshots/Notes