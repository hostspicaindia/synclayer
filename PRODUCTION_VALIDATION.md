# Production Validation Guide

## Purpose

Validate SyncLayer architecture with real-world usage before adding advanced features.

**Critical Rule:** Do NOT add CRDTs, operation logs, WebSocket, or enterprise features until basic sync is rock-solid.

---

## Phase 1: Basic Validation ✅

### Setup (Complete)
- [x] Simple Node.js backend created
- [x] Todo example app created
- [x] Pull sync implemented
- [x] Version auto-increment working
- [x] Hash generation working
- [x] Event emission working

### Test Scenarios

#### 1. Basic Offline → Online
**Goal:** Verify data persists offline and syncs when online

**Steps:**
1. Start backend and app
2. Add 5 todos
3. Stop backend
4. Add 5 more todos (offline)
5. Verify todos visible in UI
6. Start backend
7. Wait for auto-sync (10 seconds)
8. Check backend: `curl http://localhost:3000/debug/todos`

**Expected:**
- All 10 todos in backend
- No data loss
- Versions incremented correctly
- Sync events emitted

**Pass Criteria:**
- ✅ All todos synced
- ✅ No duplicates
- ✅ Correct versions
- ✅ No errors in console

---

#### 2. Two Devices Syncing
**Goal:** Verify pull sync merges remote changes

**Status:** ✅ FIXED - Pull sync now working

**Bug Found:** Pull sync only checked local collections. On fresh Device 2, no local collections existed, so pull sync never ran.

**Fix Applied:**
- Added `collections` parameter to `SyncConfig`
- Modified `_pullSync()` to use configured collections if provided
- Updated todo app to specify `collections: ['todos']`
- Added debug logging to track pull sync behavior

**Steps:**
1. Run app on two devices/emulators
2. Add todo on device 1
3. Wait for sync
4. Check device 2 receives update
5. Add todo on device 2
6. Check device 1 receives update

**Expected:**
- Both devices see all todos
- Pull sync fetches remote changes
- No conflicts (different todos)

**Pass Criteria:**
- ✅ Changes appear on both devices
- ✅ Pull sync working
- ✅ No data loss

**Testing Instructions:**
```bash
# Terminal 1: Start backend
cd backend
npm start

# Terminal 2: Device 1
cd example/todo_app
flutter run -d emulator-5554

# Terminal 3: Device 2
cd example/todo_app
flutter run -d emulator-5556
```

---

#### 3. Conflict Resolution
**Goal:** Verify last-write-wins works correctly

**Steps:**
1. Run app on two devices
2. Turn off wifi on device 1
3. Edit same todo on both devices
4. Turn wifi back on device 1
5. Wait for sync

**Expected:**
- Conflict detected (different versions)
- Last-write-wins resolves conflict
- One version wins, other discarded
- No crash or data corruption

**Pass Criteria:**
- ✅ Conflict detected event emitted
- ✅ Conflict resolved event emitted
- ✅ One version persists
- ✅ No errors

---

#### 4. Rapid Edits
**Goal:** Verify queue handles rapid operations

**Steps:**
1. Add 20 todos as fast as possible
2. Toggle all 20 rapidly
3. Delete 10 rapidly
4. Watch sync events counter

**Expected:**
- All operations queued
- Sync processes in order
- No race conditions
- No data loss

**Pass Criteria:**
- ✅ All operations complete
- ✅ Correct final state
- ✅ No sync lock issues
- ✅ Events emitted correctly

---

#### 5. Network Interruption
**Goal:** Verify resilience to network issues

**Steps:**
1. Add todos while online
2. Turn airplane mode on/off 5 times
3. Add todos during each state
4. Wait for final sync

**Expected:**
- App handles connectivity changes
- Connectivity events emitted
- All data eventually syncs
- No crashes

**Pass Criteria:**
- ✅ Connectivity events working
- ✅ Sync resumes after reconnect
- ✅ All data synced
- ✅ No errors

---

#### 6. Large Dataset
**Goal:** Verify performance with realistic data

**Steps:**
1. Add 100 todos using batch operation
2. Measure sync time
3. Toggle 50 todos
4. Delete 25 todos
5. Check memory usage

**Expected:**
- Sync completes in reasonable time
- UI remains responsive
- Memory usage acceptable
- No performance degradation

**Pass Criteria:**
- ✅ Sync < 30 seconds for 100 items
- ✅ UI smooth (60fps)
- ✅ Memory < 100MB
- ✅ No lag

---

## Phase 2: Edge Cases

### Test 7: App Lifecycle
**Goal:** Verify sync survives app lifecycle

**Steps:**
1. Add todos
2. Background app (home button)
3. Wait 5 minutes
4. Foreground app
5. Verify sync resumes

**Pass Criteria:**
- ✅ Sync resumes on foreground
- ✅ No data loss
- ✅ Timers restart correctly

---

### Test 8: Backend Errors
**Goal:** Verify error handling

**Steps:**
1. Stop backend
2. Add todos (queued)
3. Start backend with errors (500 responses)
4. Watch retry logic
5. Fix backend
6. Verify eventual sync

**Pass Criteria:**
- ✅ Retry count increments
- ✅ Max retries respected
- ✅ Failed operations marked
- ✅ Sync succeeds after fix

---

### Test 9: Version Conflicts
**Goal:** Verify version-based detection

**Steps:**
1. Create todo with version 1
2. Manually set local version to 3
3. Backend has version 2
4. Trigger sync
5. Verify conflict detected

**Pass Criteria:**
- ✅ Version mismatch detected
- ✅ Conflict event emitted
- ✅ Resolution applied
- ✅ Final version correct

---

### Test 10: Hash-Based Change Detection
**Goal:** Verify hash prevents unnecessary syncs

**Steps:**
1. Add todo
2. Wait for sync
3. Read same todo (no changes)
4. Trigger sync
5. Verify no push operation

**Pass Criteria:**
- ✅ Hash matches
- ✅ No unnecessary push
- ✅ Bandwidth saved

---

## Issues to Watch For

### Critical Issues (Must Fix)
- [ ] Data loss during offline period
- [ ] Sync lock race conditions
- [ ] Version conflicts causing crashes
- [ ] Memory leaks during long sessions
- [ ] UI freezing during sync

### Important Issues (Should Fix)
- [ ] Slow sync with large datasets
- [ ] Excessive battery drain
- [ ] Network errors not handled gracefully
- [ ] Conflict resolution losing data
- [ ] Events not emitting correctly

### Nice to Fix (Can Wait)
- [ ] Sync progress indicator
- [ ] Better error messages
- [ ] Optimistic UI updates
- [ ] Undo/redo functionality

---

## Success Criteria

### Must Pass (Before Phase 3)
- ✅ All 10 test scenarios pass
- ✅ No critical issues
- ✅ No data loss in any scenario
- ✅ Performance acceptable
- ✅ Error handling works

### Should Pass (Before Publishing)
- ✅ All important issues fixed
- ✅ Tested on iOS and Android
- ✅ Tested with poor network
- ✅ Tested with multiple users
- ✅ Documentation complete

---

## What NOT to Do Yet

❌ **Do NOT add these until validation complete:**
- CRDTs
- Operation logs
- WebSocket sync
- Enterprise encryption
- Advanced conflict resolution
- Multi-tenancy
- Sync dashboard

**Why?** Because you don't yet know where the architecture breaks under real usage.

---

## Next Steps After Validation

### If All Tests Pass
1. Document any issues found
2. Fix critical and important issues
3. Run tests again
4. Publish v0.2.1 to pub.dev
5. Get community feedback
6. THEN consider Phase 3 features

### If Tests Fail
1. Document failure scenarios
2. Identify root cause
3. Fix architecture issues
4. Re-run all tests
5. Do NOT add new features yet

---

## Real-World Friction Points

Based on industry experience, watch for:

### 1. Network Timing
- Sync triggers too frequently
- Sync triggers not frequently enough
- Race conditions on reconnect

### 2. Data Consistency
- Conflicts not detected
- Conflicts detected incorrectly
- Resolution loses data

### 3. Performance
- Slow with large datasets
- Memory leaks
- Battery drain

### 4. Developer Experience
- Confusing error messages
- Hard to debug sync issues
- Events not helpful

---

## Validation Checklist

### Before Starting
- [ ] Backend running
- [ ] App builds successfully
- [ ] Test devices ready
- [ ] Network tools ready (airplane mode, etc.)

### During Testing
- [ ] Document all issues
- [ ] Screenshot errors
- [ ] Save console logs
- [ ] Note performance metrics

### After Testing
- [ ] All tests documented
- [ ] Issues prioritized
- [ ] Fixes planned
- [ ] Decision: publish or iterate

---

## Timeline

### Week 1: Basic Tests (1-6)
- Day 1-2: Setup and basic offline test
- Day 3-4: Two devices and conflicts
- Day 5: Rapid edits and network interruption
- Weekend: Large dataset testing

### Week 2: Edge Cases (7-10)
- Day 1-2: App lifecycle and backend errors
- Day 3-4: Version conflicts and hash detection
- Day 5: Fix critical issues
- Weekend: Re-test everything

### Week 3: Polish
- Day 1-3: Fix important issues
- Day 4-5: Final testing
- Weekend: Documentation

### Week 4: Decision
- Publish if all tests pass
- Or iterate if issues found

---

## Conclusion

**The Goal:** Validate that basic sync works rock-solid in real-world conditions.

**The Rule:** No advanced features until validation complete.

**The Outcome:** Confidence to publish or clarity on what needs fixing.

---

**Status:** Ready to begin validation
**Next Action:** Run Test 1 (Basic Offline → Online)

---

*Remember: You're VERY close to having a publishable SDK. Don't rush into advanced features. Validate first.*
