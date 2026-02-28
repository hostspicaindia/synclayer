# Publishing Guide - SyncLayer v1.7.2

Quick reference for publishing SyncLayer to pub.dev and GitHub.

---

## Quick Start (Automated)

### Option 1: PowerShell Script (Recommended)

```powershell
# Dry-run (test without publishing)
.\release.ps1 -DryRun

# Full release
.\release.ps1

# Skip tests (if already run)
.\release.ps1 -SkipTests

# Skip git operations (if already committed)
.\release.ps1 -SkipGit
```

### Option 2: Manual Steps

See detailed steps below.

---

## Manual Publishing Steps

### 1. Pre-Flight Checks

```bash
# Verify version is updated
grep "version:" pubspec.yaml
# Should show: version: 1.7.2

# Verify CHANGELOG is updated
head -n 20 CHANGELOG.md
# Should show v1.7.2 entry

# Clean and get dependencies
flutter clean
flutter pub get
```

### 2. Run Tests (Optional but Recommended)

```bash
# Run all tests
flutter test

# Or run specific test suites
flutter test test/unit/
flutter test test/integration/
flutter test test/stress/
```

### 3. Validate Package

```bash
# Dry-run to check for issues
flutter pub publish --dry-run
```

**Check for:**
- ✅ No warnings or errors
- ✅ Package size < 1 MB
- ✅ All required files included
- ✅ No sensitive files included

### 4. Commit and Tag

```bash
# Commit changes
git add .
git commit -m "Release v1.7.2 - Test Suite Enhancements & Quality Improvements"

# Create tag
git tag v1.7.2

# Push to GitHub
git push origin main
git push origin v1.7.2
```

### 5. Publish to pub.dev

```bash
# Publish package
flutter pub publish
```

**You will be prompted:**
1. Review package contents
2. Confirm publication
3. Type 'y' to confirm

**After publishing:**
- Package will be available at https://pub.dev/packages/synclayer
- May take a few minutes to appear
- Pub.dev will run analysis and assign score

### 6. Create GitHub Release

1. Go to: https://github.com/hostspicaindia/synclayer/releases/new

2. Fill in details:
   - **Tag**: `v1.7.2` (select existing tag)
   - **Title**: `v1.7.2 - Test Suite Enhancements & Quality Improvements`
   - **Description**: Copy from `RELEASE_NOTES_v1.7.2.md`

3. Click "Publish release"

### 7. Verify Publication

```bash
# Test installation
flutter pub add synclayer

# Check version
flutter pub deps | grep synclayer
# Should show: synclayer 1.7.2
```

**Verify on pub.dev:**
- Package page: https://pub.dev/packages/synclayer
- Score should be 160/160
- Changelog should show v1.7.2
- Documentation should be up to date

---

## Troubleshooting

### Issue: "Package validation failed"

**Solution:**
```bash
# Check for issues
flutter pub publish --dry-run

# Common fixes:
# 1. Update pubspec.yaml version
# 2. Check .pubignore excludes test files
# 3. Remove large files
# 4. Fix any static analysis warnings
```

### Issue: "Git tag already exists"

**Solution:**
```bash
# Delete local tag
git tag -d v1.7.2

# Delete remote tag
git push origin :refs/tags/v1.7.2

# Recreate tag
git tag v1.7.2
git push origin v1.7.2
```

### Issue: "Authentication failed"

**Solution:**
```bash
# Login to pub.dev
flutter pub login

# Or use token
flutter pub token add https://pub.dev
```

### Issue: "Package already published"

**Solution:**
- Cannot republish same version
- Must increment version number
- Update to v1.7.3 and try again

---

## Post-Publication Checklist

### Immediate (First Hour)
- [ ] Verify package on pub.dev
- [ ] Check pub.dev score (should be 160/160)
- [ ] Test installation: `flutter pub add synclayer`
- [ ] Verify GitHub release created
- [ ] Check documentation renders correctly

### First Day
- [ ] Monitor GitHub issues
- [ ] Check pub.dev downloads
- [ ] Respond to user feedback
- [ ] Update website (if applicable)

### First Week
- [ ] Review pub.dev analytics
- [ ] Address any reported issues
- [ ] Plan next release
- [ ] Update roadmap

---

## Rollback Procedure

### If Critical Issue Found

**Option 1: Quick Fix (Preferred)**
1. Fix the issue immediately
2. Release v1.7.3 with fix
3. Mark v1.7.2 as deprecated in CHANGELOG

**Option 2: Retract Version (Last Resort)**
1. Contact pub.dev support
2. Request version retraction
3. Only for critical security issues
4. Users will be warned about retracted version

---

## Version Numbering

SyncLayer follows semantic versioning (semver):

- **Major** (x.0.0): Breaking changes
- **Minor** (1.x.0): New features, backward compatible
- **Patch** (1.7.x): Bug fixes, backward compatible

**v1.7.2 is a patch release:**
- Test improvements
- No breaking changes
- Fully backward compatible

---

## Communication

### Announcement Template

**For GitHub Discussions:**
```markdown
# SyncLayer v1.7.2 Released 🎉

We're excited to announce SyncLayer v1.7.2 with major testing improvements!

## What's New
- 159 new tests added (90% coverage)
- Query Builder tests fixed (37/37 passing)
- Multi-device simulation validated
- Production readiness: 95/100

## Test Results
- 183/207 tests passing (88%)
- Unit tests: 88% pass rate
- Integration tests: 88% pass rate
- Stress tests: 100% pass rate

## Installation
\`\`\`yaml
dependencies:
  synclayer: ^1.7.2
\`\`\`

## Links
- Package: https://pub.dev/packages/synclayer
- Changelog: https://github.com/hostspicaindia/synclayer/blob/main/CHANGELOG.md
- Release Notes: https://github.com/hostspicaindia/synclayer/blob/main/RELEASE_NOTES_v1.7.2.md
```

---

## Support

If you encounter issues during publication:

1. Check [RELEASE_CHECKLIST_v1.7.2.md](RELEASE_CHECKLIST_v1.7.2.md)
2. Review [pub.dev publishing guide](https://dart.dev/tools/pub/publishing)
3. Contact pub.dev support: support@pub.dev
4. Open GitHub issue: https://github.com/hostspicaindia/synclayer/issues

---

**Good luck with the release! 🚀**

