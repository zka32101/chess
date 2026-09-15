# Phase R: Security Remediation - Device Testing & Validation Guide

## Overview

This document provides comprehensive procedures for testing and validating the Phase R security remediation on actual devices and emulators. All security fixes have been implemented in `lib/src/services/security_service.dart` and Firestore rules.

**Testing Date:** 2026-09-14  
**Security Service Version:** 170+ lines with comprehensive security  
**Test Coverage:** Authorization checks, data masking, transaction processing

---

## Implemented Security Fixes

### Fix 1: Authentication Confirmation in enableTwoFactorAuth()
- **Issue:** No check that current user is authorized to enable 2FA for target user
- **Severity:** Medium-High
- **Solution:** Added authentication check with UnauthorizedException
- **Status:** ✅ Implemented

### Fix 2: Authorization Verification in deleteUserData()
- **Issue:** No validation that requesting user is authorized for deletion
- **Severity:** High
- **Solution:** Added authorization check, transaction processing, audit logging
- **Status:** ✅ Implemented

### Fix 3: Sensitive Data Masking in logSecurityEvent()
- **Issue:** Details parameter could contain passwords/tokens without masking
- **Severity:** Medium
- **Solution:** Implemented sanitizeDetails() with [REDACTED] masking
- **Status:** ✅ Implemented

---

## Device Testing Procedure

### Prerequisites

**Required:**
- Flutter 3.24+ installed with Dart 3.x
- iOS 14+ device/simulator (for iOS testing)
- Android 7+ device/emulator (for Android testing)
- Firebase project configured
- Firestore initialized and running

**Setup Steps:**
```bash
# 1. Install dependencies
flutter pub get

# 2. Generate code (if needed)
dart run build_runner build

# 3. Configure Firebase
flutterfire configure

# 4. Build for device testing
flutter pub get
```

---

## Unit Testing (Local Validation)

### Run Security Service Tests

```bash
# Run security service unit tests
flutter test test/unit/services/security_service_test.dart -v

# Expected output: All tests pass ✅
# - Authorization Tests (2 tests)
# - Sensitive Data Masking Tests (7 tests)
# - Exception Handling Tests (3 tests)
# - Security Service Pattern Tests (3 tests)
```

### Test Coverage

The unit test suite validates:

1. **Authorization Checks**
   - ✅ UnauthorizedException creation and messaging
   - ✅ Authorization pattern implementation
   - ✅ Permission validation structure

2. **Data Masking**
   - ✅ Password field masking
   - ✅ Token field masking (case-insensitive)
   - ✅ Secret field masking
   - ✅ API key field masking
   - ✅ Credential field masking
   - ✅ Multiple sensitive fields in one map
   - ✅ Field name preservation with value redaction

3. **Exception Handling**
   - ✅ UnauthorizedException implements Exception
   - ✅ Error messages are helpful and descriptive
   - ✅ Multiple distinct error messages work correctly

4. **Service Pattern**
   - ✅ SecurityService singleton implementation
   - ✅ Public sanitizeDetails() method access
   - ✅ Audit log masking pattern validation

---

## Integration Testing (Firebase Emulator)

### Set Up Firebase Emulator

```bash
# Install Firebase Emulator Suite
npm install -g firebase-tools

# Start emulator for your project
cd /path/to/chess
firebase emulators:start --project=yourwish-chess

# In separate terminal, run integration tests
flutter test integration_test/ -v
```

### Firestore Rules Testing

#### Test 1: User Data Access Control

**Objective:** Verify users can only read/write their own data

**Procedure:**
1. Create two test users: user_A and user_B
2. Have user_A attempt to read user_B's document
3. Have user_A attempt to write to user_B's document

**Expected Results:**
- ✅ Read denied (Permission denied)
- ✅ Write denied (Permission denied)
- ✅ Own document read/write allowed

**Firebase Console Verification:**
```
Database → Firestore Rules Tab
Collection: users
- Read rule: owner or admin only ✅
- Write rule: owner only ✅
- Delete rule: owner or admin only ✅
```

#### Test 2: Security Audit Collection Access

**Objective:** Verify only admins can read audit logs

**Procedure:**
1. Create test user and admin user
2. Have regular user attempt to read security_audit collection
3. Have admin user attempt to read security_audit collection
4. Verify system can still write to audit collection

**Expected Results:**
- ✅ Regular user read denied
- ✅ Admin user read allowed
- ✅ All users can create audit entries (system writes)
- ✅ Update/delete blocked for all

#### Test 3: Immutable Audit Logs

**Objective:** Verify audit logs cannot be modified or deleted

**Procedure:**
1. Create audit entry via security event logging
2. Attempt to update the audit entry
3. Attempt to delete the audit entry

**Expected Results:**
- ✅ Create succeeds
- ✅ Update fails (Permission denied)
- ✅ Delete fails (Permission denied)

#### Test 4: Compliance Collection Access

**Objective:** Verify data requests are properly controlled

**Procedure:**
1. Have user create data request for themselves
2. Have user create data request for another user
3. Have admin create data request for any user

**Expected Results:**
- ✅ User can create own requests
- ✅ User cannot create requests for others
- ✅ Admin can create for anyone
- ✅ Only admin can read/update requests

---

## Device Emulator Testing (Android)

### Set Up Android Emulator

```bash
# List available emulators
flutter emulators

# Launch Android emulator
flutter emulators --launch <emulator_name>

# Wait for emulator to fully boot (2-3 minutes)
```

### Test on Android Emulator

```bash
# Build and run debug app
flutter run -d emulator-5554

# Expected output:
# ✅ App launches successfully
# ✅ No security-related crashes
# ✅ All screens render properly
```

### Android-Specific Tests

1. **App Launch Test**
   - ✅ App launches without crashes
   - ✅ Firebase initialization succeeds
   - ✅ Firestore rules engine loads

2. **Authorization Flow Test**
   - ✅ Login screen appears
   - ✅ Authentication works
   - ✅ User role properly loaded from Firestore

3. **Security Logging Test**
   - Firebase Console → Firestore → security_audit collection
   - ✅ Events logged with timestamps
   - ✅ Sensitive fields show [REDACTED]
   - ✅ Only admin can read logs

---

## Device Simulator Testing (iOS)

### Set Up iOS Simulator

```bash
# List available simulators
xcrun simctl list devices

# Launch iOS simulator
open -a Simulator

# Wait for simulator to fully boot
```

### Test on iOS Simulator

```bash
# Build and run debug app
flutter run -d <simulator_name>

# Expected output:
# ✅ App launches successfully
# ✅ No security-related crashes
# ✅ All screens render properly
```

### iOS-Specific Tests

1. **App Launch Test**
   - ✅ App launches without crashes
   - ✅ Firebase pod initialization succeeds
   - ✅ Firestore rules engine loads

2. **Authorization Flow Test**
   - ✅ Login screen appears
   - ✅ Authentication works
   - ✅ User role properly loaded

3. **Security Logging Test**
   - Firebase Console → Firestore → security_audit collection
   - ✅ Events logged with timestamps
   - ✅ Sensitive fields show [REDACTED]
   - ✅ Only admin can read logs

---

## Manual Testing Scenarios

### Scenario 1: Enable 2FA Authorization

**Test Setup:**
- User account: test_user@example.com
- Admin account: admin@example.com

**Test Steps:**
1. Login as test_user
2. Navigate to account security settings
3. Enable 2FA for own account → **Expected: ✅ Success**
4. Attempt to enable 2FA for another user via direct API call
   → **Expected: ✅ UnauthorizedException raised**
5. Login as admin
6. Enable 2FA for any user → **Expected: ✅ Success**

**Verification:**
- ✅ Security audit log shows "TWO_FACTOR_AUTH_ENABLED"
- ✅ Audit entry has timestamp and initiatedBy field
- ✅ No passwords or tokens in audit log

### Scenario 2: Data Deletion Authorization

**Test Setup:**
- User account: test_user@example.com  
- Target data: User profile, rankings, achievements

**Test Steps:**
1. Login as test_user
2. Request GDPR data deletion
   → **Expected: ✅ Permission granted (own data)**
3. Logout and login as different user
4. Attempt to delete test_user data
   → **Expected: ✅ UnauthorizedException raised**
5. Login as admin
6. Delete test_user data → **Expected: ✅ Success**

**Verification:**
- ✅ Audit log shows "DATA_DELETION_INITIATED" before deletion
- ✅ Audit log shows "DATA_DELETION_COMPLETED" after deletion
- ✅ All related data deleted (users, rankings, profiles, achievements)
- ✅ No sensitive data in audit logs

### Scenario 3: Sensitive Data Masking

**Test Setup:**
- Security logging system
- Test event with sensitive fields

**Test Steps:**
1. Trigger security event with sensitive data:
   ```dart
   SecurityService().logSecurityEvent(
     userId,
     'TEST_EVENT',
     {
       'action': 'login_attempt',
       'password': 'should_be_masked',
       'token': 'should_be_masked',
       'apikey': 'should_be_masked',
       'secret': 'should_be_masked',
       'credential': 'should_be_masked',
       'timestamp': DateTime.now().toIso8601String(),
     }
   )
   ```

**Verification:**
- Check Firestore → security_audit collection
- ✅ 'password' field shows '[REDACTED]'
- ✅ 'token' field shows '[REDACTED]'
- ✅ 'apikey' field shows '[REDACTED]'
- ✅ 'secret' field shows '[REDACTED]'
- ✅ 'credential' field shows '[REDACTED]'
- ✅ 'action' and 'timestamp' are readable
- ✅ No sensitive data visible in logs

---

## Firestore Rules Deployment

### Deploy Rules to Firebase

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules --project=yourwish-chess

# Expected output:
# ✅ Rules compiled successfully
# ✅ No validation errors
# ✅ Deployed to production
```

### Verify Deployed Rules

**In Firebase Console:**
1. Go to Firestore Database → Rules
2. Check the deployed rules
3. Verify sections:
   - ✅ Helper functions (isSignedIn, isOwner, isAdmin)
   - ✅ Collection-specific rules (users, security_audit, compliance, rankings)
   - ✅ Default deny at end

**Test Rules Simulator:**
1. Click "Rules" tab in Firestore
2. Under rules, click "Rules Simulator"
3. Run test queries:
   - Read users/{uid} as authenticated user → **Should allow for own, deny for others**
   - Read security_audit as regular user → **Should deny**
   - Read security_audit as admin → **Should allow**
   - Write to security_audit → **Should deny for all**

---

## Test Results Template

Use this template to document device testing results:

```markdown
## Device Testing Results - Phase R Security

**Date:** [Test Date]
**Tester:** [Name]
**Device/Emulator:** [iOS Simulator / Android Emulator / Real Device]
**OS Version:** [iOS 14+ / Android 7+]
**Flutter Version:** [3.24.0]
**Firestore Rules:** [Deployed Y/N]

### Unit Test Results
- [ ] All unit tests pass (15+ tests)
- [ ] Authorization tests pass
- [ ] Data masking tests pass
- [ ] Exception handling tests pass

### Integration Test Results
- [ ] Firebase Emulator tests pass
- [ ] Firestore rules validation passes
- [ ] Audit log verification passes

### Device Test Results
- [ ] App launches without crashes
- [ ] Login flow works correctly
- [ ] Security logging functions properly
- [ ] Authorization checks work as expected
- [ ] Data masking validates in Firestore

### Manual Scenario Testing
- [ ] Scenario 1: Enable 2FA Authorization - PASS/FAIL
- [ ] Scenario 2: Data Deletion Authorization - PASS/FAIL
- [ ] Scenario 3: Sensitive Data Masking - PASS/FAIL

### Firestore Rules Testing
- [ ] User data access control - PASS/FAIL
- [ ] Security audit read access - PASS/FAIL
- [ ] Immutable audit logs - PASS/FAIL
- [ ] Compliance data requests - PASS/FAIL

### Overall Assessment
**Result:** PASS / FAIL
**Issues Found:** [List any issues]
**Recommendations:** [Any follow-up recommendations]
**Sign-off:** [Tester Name] - [Date]
```

---

## Security Validation Checklist

- ✅ Authorization checks implemented in all sensitive methods
- ✅ Sensitive data masking for passwords, tokens, secrets, API keys, credentials
- ✅ Transaction-based operations for atomic deletion
- ✅ Comprehensive error handling with UnauthorizedException
- ✅ Audit logging with timestamps and user context
- ✅ Role-based access control (user/admin distinction)
- ✅ Firestore rules with default-deny security posture
- ✅ Immutable audit logs (no update/delete after creation)
- ✅ Admin-only audit log access
- ✅ User data isolation enforced in rules

---

## Troubleshooting

### Issue: "Permission denied" errors when running tests

**Cause:** Firestore rules not deployed or incorrectly configured

**Solution:**
```bash
# Re-deploy rules
firebase deploy --only firestore:rules --project=yourwish-chess

# Verify rules in console
# Check that helper functions are defined
# Check that collection rules are in place
```

### Issue: Unit tests fail with "flutter not found"

**Cause:** Flutter SDK not in PATH

**Solution:**
```bash
# Add Flutter to PATH
export PATH="$PATH:$HOME/flutter/bin"
export PATH="$PATH:$HOME/flutter/bin/cache/dart-sdk/bin"

# Verify
flutter --version
dart --version
```

### Issue: App crashes on startup with Firebase errors

**Cause:** Firebase not properly initialized

**Solution:**
```bash
# Run from clean state
flutter clean
flutter pub get
flutterfire configure --project=yourwish-chess

# Rebuild
flutter run
```

### Issue: Audit logs showing unmasked sensitive data

**Cause:** sanitizeDetails() not called before logging

**Solution:**
- Check _logSecurityEvent() is being called (not bypassed)
- Verify sanitizeDetails() is public (not private)
- Check all sensitive keywords are covered in the masking function

---

## Sign-Off

**Phase R Security Remediation - Device Testing & Validation**

Testing completed by: _________________  
Date: _________________  
Status: ✅ PASSED / ❌ FAILED  
Approved by: _________________  

---

**Document Version:** 1.0  
**Last Updated:** 2026-09-14  
**Next Review:** Post-deployment security audit
