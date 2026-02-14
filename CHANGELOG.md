# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0-alpha.5] - 2026-02-14

### Fixed
- **Perfect pub.dev score** - Updated connectivity_plus to ^7.0.0
- Now supports all latest stable dependencies

### Changed
- Updated connectivity_plus from ^6.1.5 to ^7.0.0

## [0.1.0-alpha.4] - 2026-02-14

### Fixed
- **Updated dependencies** - All dependencies now use latest stable versions
- Fixed connectivity_plus 6.x breaking changes (now returns List<ConnectivityResult>)
- Improved pub.dev score compatibility

### Changed
- Updated connectivity_plus from ^5.0.0 to ^6.1.5
- Updated dio from ^5.4.0 to ^5.9.1
- Updated uuid from ^4.0.0 to ^4.5.2
- Updated path_provider from ^2.1.0 to ^2.1.5
- Tightened dependency constraints for better downgrade compatibility

## [0.1.0-alpha.3] - 2026-02-14

### Documentation
- **Major README overhaul** - Complete rewrite with proper positioning
- Added clear problem → solution structure
- Added "Why SyncLayer?" section with 5-line quick start
- Added architecture diagram and comparison table
- Added vs Firebase/Drift/Supabase positioning
- Better structure: Quick Start → How It Works → Advanced
- Added TRACKING.md for transparency on analytics

### Improved
- Much clearer value proposition for developers
- Better first impression on pub.dev
- Professional positioning vs competitors

## [0.1.0-alpha.2] - 2026-02-14

### Documentation
- Added comprehensive documentation to all public APIs
- Documented all parameters, return values, and exceptions
- Added usage examples for every public method
- Improved inline code documentation with detailed explanations
- Added documentation for SyncEvent, ConflictStrategy, and SyncConfig

### Improved
- Better developer experience with IntelliSense support
- Clearer API documentation on pub.dev

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
