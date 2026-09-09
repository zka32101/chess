# Phase 3: Pre-Testing Readiness Checklist

**Project:** Chess Tactics Master  
**Date:** 2026-09-07  
**Owner:** QA Lead  
**Duration:** 1-2 hours  

---

## ✅ Environment Verification

### Firebase Staging Verification

- [ ] **Firebase Project** `chess-staging` accessible
  - URL: https://console.firebase.google.com/project/chess-staging
  - Credentials: ________________________
  - Access level: Read/Write

- [ ] **Firestore Database**
  - Collections visible: users, games, analytics
  - Rules deployed and active
  - No errors in deployment logs
  - Command: `firebase projects:list | grep chess-staging`

- [ ] **Realtime Database**
  - Database URL accessible
  - Test data writable
  - No permission errors
  - URL: `https://chess-staging-default-rtdb.firebaseio.com`

- [ ] **Cloud Functions**
  - All functions deployed successfully
  - Function logs accessible
  - No errors in logs
  - Verify: `firebase functions:list --project chess-staging`

- [ ] **Analytics**
  - Events receiving (from app testing)
  - Dashboard populated
  - Real-time monitoring active
  - Real-time events visible

- [ ] **Crashlytics**
  - Dashboard accessible
  - Ready to receive crash reports
  - No prior crashes showing

- [ ] **Cloud Storage**
  - Bucket accessible
  - Upload/download permissions verified
  - No errors in logs

---

### RevenueCat Sandbox Verification

- [ ] **RevenueCat Dashboard** accessible
  - Login working: https://dashboard.revenuecat.com
  - Sandbox mode selected
  - Credentials: ________________________

- [ ] **Test Products** all present
  - [ ] basic_monthly_test ($2.99/mo) - Active
  - [ ] basic_annual_test ($19.99/yr) - Active
  - [ ] premium_monthly_test ($4.99/mo) - Active
  - [ ] premium_annual_test ($39.99/yr) - Active
  - [ ] elite_monthly_test ($9.99/mo) - Active
  - [ ] elite_annual_test ($79.99/yr) - Active

- [ ] **Test Users** created
  - [ ] test_user_1@chess.local - 7-day trial enabled
  - [ ] test_user_2@chess.local - 7-day trial enabled
  - [ ] test_user_3@chess.local - 7-day trial enabled

- [ ] **API Keys** configured
  - Public Key (pk_test_...): _____________________
  - Access verified: [ ]
  - In .env.staging: [ ]

- [ ] **Test Purchases** verified
  - Sandbox purchase simulation working
  - Receipt validation working
  - Trial period simulation working

---

### Staging Build Verification

### Android Build (APK)

- [ ] **APK File** present
  - Location: `build/app/outputs/apk/release/app-release.apk`
  - File size: _________ MB
  - MD5: _________________________________
  - Timestamp: ____________________________

- [ ] **APK Installation**
  - [ ] Device 1 (Android Phone): Installation successful
    - Device: ____________________
    - OS Version: ________________
    - App launches: ✓ Yes / ✗ No
    
  - [ ] Device 2 (Android Phone): Installation successful
    - Device: ____________________
    - OS Version: ________________
    - App launches: ✓ Yes / ✗ No
    
  - [ ] Device 3 (Android Tablet - optional): Installation successful
    - Device: ____________________
    - OS Version: ________________
    - App launches: ✓ Yes / ✗ No

- [ ] **APK Signing**
  - Signed with debug keystore: ✓ Yes
  - Signature valid: ✓ Yes
  - No signing warnings: ✓ Yes

---

### iOS Build (IPA)

- [ ] **IPA File** present
  - Location: `Chess.ipa`
  - File size: _________ MB
  - MD5: _________________________________
  - Timestamp: ____________________________

- [ ] **TestFlight Distribution**
  - [ ] Build uploaded to TestFlight: ✓ Yes
  - [ ] Build processing completed: ✓ Yes
  - [ ] Build status: Available / Processing
  
- [ ] **IPA Installation**
  - [ ] Device 1 (iPhone): Installation successful via TestFlight
    - Device: ____________________
    - OS Version: ________________
    - App launches: ✓ Yes / ✗ No
    
  - [ ] Device 2 (iPhone): Installation successful via TestFlight
    - Device: ____________________
    - OS Version: ________________
    - App launches: ✓ Yes / ✗ No
    
  - [ ] Device 3 (iPad - optional): Installation successful via TestFlight
    - Device: ____________________
    - OS Version: ________________
    - App launches: ✓ Yes / ✗ No

- [ ] **Code Signing**
  - Provisioning profiles valid: ✓ Yes
  - Development team configured: ✓ Yes
  - No signing warnings: ✓ Yes

---

## 🔗 App Configuration Verification

### Firebase Configuration Verification

After launching app on test devices, verify in-app configuration:

- [ ] **Firebase Initialization**
  - App Settings → Firebase: Connected ✓
  - Project ID: chess-staging
  - Authentication working: ✓ Yes

- [ ] **Authentication**
  - Email/Password auth available: ✓ Yes
  - Google Sign-In available: ✓ Yes
  - Apple Sign-In available: ✓ Yes

- [ ] **Analytics**
  - Analytics enabled: ✓ Yes
  - Events sending (check Firebase dashboard)
  - Dashboard shows test events: ✓ Yes

- [ ] **Crashlytics**
  - Enabled: ✓ Yes
  - Ready to receive crashes: ✓ Yes

---

### RevenueCat Configuration Verification

After launching app on test devices:

- [ ] **RevenueCat Connection**
  - App Settings → RevenueCat: Connected ✓
  - Paywall loading: ✓ Yes
  - Products displaying: ✓ Yes (all 6 products)

- [ ] **Entitlements**
  - Free tier products visible: ✓ Yes
  - Premium products visible: ✓ Yes
  - Pricing displays correctly: ✓ Yes

- [ ] **Test User Account**
  - Can create test user: ✓ Yes
  - Can login with test user: ✓ Yes
  - Trial period active: ✓ Yes

---

## 🧪 Sanity Test Execution

### Quick Smoke Test (15 minutes)

Run this basic flow to verify everything is working:

**On Android Device:**
```
1. [ ] App launches without crash
2. [ ] Login screen displays
3. [ ] Create test account (email: qa_test_android@test.local)
4. [ ] Email verification (check email)
5. [ ] Login successful
6. [ ] Home screen displays
7. [ ] Tap "Subscribe" button
8. [ ] Paywall displays with 6 products
9. [ ] Tap "Try Free" for basic_monthly_test
10. [ ] Payment processing works
11. [ ] Premium features unlock
12. [ ] Settings available
13. [ ] Logout works
14. [ ] Check Firebase Analytics (should see events)
```

**Status:** ✓ Pass / ✗ Fail / ⏳ In Progress

**Issues Found:** (List any issues encountered)
- Issue 1: _________________________________
- Issue 2: _________________________________

**Sign-off:** _________________ Time: _________

---

**On iOS Device:**
```
1. [ ] App launches without crash
2. [ ] Login screen displays
3. [ ] Create test account (email: qa_test_ios@test.local)
4. [ ] Email verification (check email)
5. [ ] Login successful
6. [ ] Home screen displays
7. [ ] Tap "Subscribe" button
8. [ ] Paywall displays with 6 products
9. [ ] Tap "Try Free" for premium_monthly_test
10. [ ] Payment processing works
11. [ ] Premium features unlock
12. [ ] Settings available
13. [ ] Logout works
14. [ ] Check Firebase Analytics (should see events)
```

**Status:** ✓ Pass / ✗ Fail / ⏳ In Progress

**Issues Found:** (List any issues encountered)
- Issue 1: _________________________________
- Issue 2: _________________________________

**Sign-off:** _________________ Time: _________

---

## 📊 Monitoring Setup

### Firebase Monitoring Dashboard

- [ ] **Real-time Dashboard**
  - URL: https://console.firebase.google.com/project/chess-staging
  - Analytics tab open and monitoring
  - Crashlytics tab open
  - Performance monitoring active

- [ ] **Alert Configuration** (Optional)
  - Crash spike alerts configured: ✓ Yes / No
  - Performance threshold alerts: ✓ Yes / No
  - Error rate alerts: ✓ Yes / No

### RevenueCat Monitoring

- [ ] **Revenue Dashboard**
  - URL: https://dashboard.revenuecat.com
  - Sandbox mode active
  - Transaction log accessible
  - Real-time events visible

### Test Device Monitoring

- [ ] **Device 1 - Monitoring**
  - Device ready: ✓ Yes
  - Battery > 50%: ✓ Yes
  - Storage space available: ✓ Yes
  - Connected to WiFi: ✓ Yes / No (OK if no)

- [ ] **Device 2 - Monitoring**
  - Device ready: ✓ Yes
  - Battery > 50%: ✓ Yes
  - Storage space available: ✓ Yes
  - Connected to WiFi: ✓ Yes / No (OK if no)

- [ ] **Device 3 - Monitoring** (Optional)
  - Device ready: ✓ Yes
  - Battery > 50%: ✓ Yes
  - Storage space available: ✓ Yes
  - Connected to WiFi: ✓ Yes / No (OK if no)

---

## 👥 Team Readiness

### Team Communication

- [ ] **Test Team Briefing** completed
  - [ ] QA Tester 1 briefed on assignments
  - [ ] QA Tester 2 briefed on assignments
  - [ ] QA Tester 3 briefed on assignments
  - [ ] QA Lead briefed on coordination
  - [ ] Release Manager notified of timeline

- [ ] **Daily Standup** scheduled
  - Time: _________ UTC
  - Location: ________________________
  - Attendees confirmed: [ ]

- [ ] **Issue Escalation** procedure communicated
  - Critical issue contact: ________________
  - Escalation time: Within 15 minutes
  - Slack channel: ________________________

### Support Team Ready

- [ ] **Technical Support** available
  - Firebase/RevenueCat issues: ________________
  - Mobile/device issues: ________________
  - Network issues: ________________

- [ ] **Documentation** available to team
  - [ ] STAGING_E2E_TESTS.md (350+ test procedures)
  - [ ] PHASE_3_E2E_EXECUTION_TRACKER.md
  - [ ] Issue template document
  - [ ] Contact list

---

## 🎯 Final Sign-Off

### Pre-Testing Verification Complete

- [ ] **All checks passed:** Yes / No

- [ ] **Outstanding issues:** 
  - Count: _____
  - Severity: 🔴 None / 🟡 Low / 🟢 Medium

- [ ] **Ready to begin testing:** Yes / No

**If any checks failed or issues found:**
- [ ] Issues documented
- [ ] Plan to resolve before testing
- [ ] Timeline impact assessed

---

## ✅ Phase 3 Ready Checklist

- [ ] Firebase staging fully configured and verified
- [ ] RevenueCat sandbox configured with 6 products
- [ ] Android APK built, signed, and installed on 2+ devices
- [ ] iOS IPA built and distributed via TestFlight
- [ ] All test devices prepared and ready
- [ ] Smoke test passed on both Android and iOS
- [ ] Firebase Analytics receiving events
- [ ] RevenueCat sandbox transactions working
- [ ] Monitoring dashboards open and active
- [ ] Team briefed and ready
- [ ] Support structure in place
- [ ] Issue tracking system ready

---

## 🚀 Phase 3 Kickoff

**All systems verified and ready for Phase 3 E2E Testing execution.**

**Phase 3 Start Time:** _____________  
**Expected Completion:** 2026-09-08 by 6:00 PM UTC  
**Phase 3 Owner:** QA Lead  

**Approved by:**
- QA Lead: _________________ Date: _____
- Release Manager: _________________ Date: _____

---

**Document Version:** 1.0  
**Created:** 2026-09-07  
**Status:** Ready for team sign-off
