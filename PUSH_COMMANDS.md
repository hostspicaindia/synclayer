# Push Commands Reference

Quick reference for pushing the database adapter changes.

## Pre-Push Verification

```bash
# Run adapter tests
flutter test test/adapters_test_suite.dart

# Expected output:
# 00:09 +60: All tests passed!
```

## Git Commands

### 1. Check Status
```bash
git status
```

### 2. Add All Changes
```bash
git add .
```

### 3. Commit with Message
```bash
git commit -m "feat: Add support for 10+ new database adapters

Add comprehensive database adapter support:
- SQL: PostgreSQL, MySQL, MariaDB, SQLite
- NoSQL: MongoDB, CouchDB, Redis, DynamoDB, Cassandra
- API: GraphQL

Features:
- 10 new database adapters
- Optional dependencies (install only what you need)
- Comprehensive documentation and guides
- 60+ tests (all passing)
- Easy database switching

Total database support: 14+ (from 4 to 14+)

BREAKING CHANGE: Firebase, Supabase, and Appwrite are now optional.
Users must add these packages to pubspec.yaml if needed."
```

### 4. Push to Repository
```bash
# Push to main branch
git push origin main

# Or push to feature branch
git push origin feature/database-adapters
```

## Alternative: Create Pull Request

### 1. Create Feature Branch
```bash
git checkout -b feature/database-adapters
```

### 2. Add and Commit
```bash
git add .
git commit -m "feat: Add support for 10+ new database adapters"
```

### 3. Push Branch
```bash
git push origin feature/database-adapters
```

### 4. Create PR on GitHub
- Go to repository on GitHub
- Click "Pull Requests"
- Click "New Pull Request"
- Select your branch
- Add description
- Create PR

## Files to Push

### New Files (25)
```
lib/adapters.dart
lib/adapters/postgres_adapter.dart
lib/adapters/mysql_adapter.dart
lib/adapters/mariadb_adapter.dart
lib/adapters/sqlite_adapter.dart
lib/adapters/mongodb_adapter.dart
lib/adapters/couchdb_adapter.dart
lib/adapters/redis_adapter.dart
lib/adapters/dynamodb_adapter.dart
lib/adapters/cassandra_adapter.dart
lib/adapters/graphql_adapter.dart
lib/adapters/ADAPTER_GUIDE.md
DATABASE_SUPPORT.md
DATABASE_COMPARISON.md
INSTALLATION.md
QUICK_START.md
ADAPTER_INTEGRATION_SUMMARY.md
test/unit/adapters/adapter_interface_test.dart
test/unit/adapters/mock_adapter_test.dart
test/unit/adapters/adapter_validation_test.dart
test/integration/adapter_integration_test.dart
test/adapters_test_suite.dart
test/ADAPTER_TESTING.md
TEST_RESULTS.md
PRE_PUSH_CHECKLIST.md
FINAL_SUMMARY.md
```

### Modified Files (3)
```
pubspec.yaml
lib/synclayer.dart
lib/adapters/adapters.dart
lib/adapters/README.md
```

## Verification After Push

### 1. Check GitHub
- Verify all files are pushed
- Check commit message
- Verify no errors

### 2. Clone Fresh Copy (Optional)
```bash
git clone <repository-url> test-clone
cd test-clone
flutter pub get
flutter test test/adapters_test_suite.dart
```

### 3. Verify Tests Pass
```bash
# Should see:
# 00:09 +60: All tests passed!
```

## Next Steps After Push

### 1. Update CHANGELOG.md
```markdown
## [0.2.0-beta.6] - 2024-02-XX

### Added
- PostgreSQL adapter
- MySQL adapter
- MariaDB adapter
- SQLite adapter
- MongoDB adapter
- CouchDB adapter
- Redis adapter
- DynamoDB adapter
- Cassandra adapter
- GraphQL adapter
- Comprehensive adapter documentation
- 60+ adapter tests

### Changed
- Made Firebase, Supabase, and Appwrite optional dependencies

### Breaking Changes
- Firebase, Supabase, and Appwrite packages must now be added manually
```

### 2. Update README.md
Add database support section:
```markdown
## Supported Databases

SyncLayer supports 14+ databases:

- **BaaS:** Firebase, Supabase, Appwrite
- **SQL:** PostgreSQL, MySQL, MariaDB, SQLite
- **NoSQL:** MongoDB, CouchDB, Redis, DynamoDB, Cassandra
- **API:** REST, GraphQL

See [DATABASE_SUPPORT.md](DATABASE_SUPPORT.md) for details.
```

### 3. Create GitHub Release
- Go to Releases
- Click "Create new release"
- Tag: v0.2.0-beta.6
- Title: "Database Adapter Support"
- Description: Copy from FINAL_SUMMARY.md
- Publish release

### 4. Publish to pub.dev
```bash
flutter pub publish --dry-run  # Test first
flutter pub publish            # Actual publish
```

## Troubleshooting

### If Tests Fail
```bash
# Run specific test
flutter test test/adapters_test_suite.dart -v

# Check for errors
flutter analyze
```

### If Push Fails
```bash
# Pull latest changes
git pull origin main

# Resolve conflicts if any
# Then push again
git push origin main
```

### If Need to Undo
```bash
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1
```

## Quick Push (All-in-One)

```bash
# Run tests
flutter test test/adapters_test_suite.dart && \
# Add all changes
git add . && \
# Commit
git commit -m "feat: Add support for 10+ new database adapters" && \
# Push
git push origin main
```

## Status Check

Before pushing, verify:
- ✅ All tests pass (60/60)
- ✅ No syntax errors
- ✅ Documentation complete
- ✅ Commit message ready
- ✅ Ready to push

## 🚀 Ready!

All commands are ready. Just run them in order and you're good to go!
