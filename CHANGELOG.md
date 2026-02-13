# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0-alpha.1] - 2026-02-14

### Initial Alpha Release

**Features:**
- Local-first storage with Isar database
- Push sync (device → backend)
- Pull sync (backend → device) with collection configuration
- Batch operations (`saveAll()`, `deleteAll()`)
- Conflict resolution with last-write-wins strategy
- Auto-sync with configurable intervals
- Event system for sync lifecycle monitoring
- Version tracking and hash generation
- Offline queue with retry logic
- Connectivity monitoring

**Known Issues:**
- Pull sync requires explicit `collections` parameter in `SyncConfig`
- Limited production testing (2 of 10 validation tests completed)
- Example backend uses in-memory storage only
- Basic error handling and retry logic (3 attempts max)
- No built-in authentication or encryption

**Bug Fixes:**
- Fixed pull sync not working on fresh devices (requires collection config)
- Fixed pull sync missing records due to timestamp tracking issue

**Breaking Changes:**
- None (initial release)

**Documentation:**
- README with quick start guide
- API documentation
- Architecture overview
- Example todo app
- Production validation guide

---

## Versioning

This project follows [Semantic Versioning](https://semver.org/):
- **0.x.x** - Pre-release, APIs may change
- **1.0.0** - First stable release
- **x.Y.0** - New features (backward compatible)
- **x.y.Z** - Bug fixes (backward compatible)
