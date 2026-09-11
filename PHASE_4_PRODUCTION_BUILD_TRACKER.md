# Phase 4: Production Build & Submission - Execution Tracker

**Project:** Chess Tactics Master  
**Phase:** 4 - Production Build & App Store Submission  
**Timeline:** 2026-09-09 to 2026-09-11 (2-3 days)  
**Duration:** 16-20 hours across team  
**Owner:** Release Manager / Mobile Lead

---

## 🎯 Phase 4 Objectives

- [ ] **PRIMARY:** Create production-ready builds (APK & IPA) with live configuration
- [ ] **SECONDARY:** Prepare comprehensive app store listings
- [ ] **TERTIARY:** Submit to Google Play Store and Apple App Store
- [ ] **QUATERNARY:** Monitor submissions and respond to rejections

---

## 👥 Team Roles & Assignments

| Role | Name | Responsibility | Status |
|------|------|-----------------|--------|
| **Release Manager** | [Name] | Overall coordination, timeline | ⏳ |
| **Mobile Lead** | [Name] | Build creation, signing, validation | ⏳ |
| **DevOps Lead** | [Name] | Production Firebase config | ⏳ |
| **Marketing Lead** | [Name] | Store listings, screenshots, copy | ⏳ |
| **QA Lead** | [Name] | Final verification on release builds | ⏳ |
| **Legal/Compliance** | [Name] | Privacy policy, ToS, compliance | ⏳ |

---

## 📅 Execution Schedule

### Day 1: Production Setup & Build (2026-09-09)

**Morning Session (3-4 hours)**
- [ ] Production environment configuration (30 min)
- [ ] Firebase production project setup (1-2 hours)
- [ ] Keystore generation and signing config (45 min)
- [ ] Pre-build validation (30 min)

**Afternoon Session (4-5 hours)**
- [ ] Android production APK build (1.5-2 hours)
- [ ] iOS production IPA build (1.5-2 hours)
- [ ] Build signing and optimization (1 hour)
- [ ] Quality verification (45 min)

### Day 2: Store Listing Preparation (2026-09-10)

**Morning Session (4-5 hours)**
- [ ] Store listing content preparation (1.5 hours)
- [ ] Screenshot and graphics preparation (1.5 hours)
- [ ] Privacy policy & ToS finalization (1-2 hours)

**Afternoon Session (3-4 hours)**
- [ ] Content rating questionnaire (1 hour)
- [ ] Store account configuration (1 hour)
- [ ] Pre-submission checklist (1-2 hours)

### Day 3: Submission & Monitoring (2026-09-11)

**Morning Session (2-3 hours)**
- [ ] Final verification (30 min)
- [ ] Google Play Store submission (30 min)
- [ ] Apple App Store submission (1-2 hours)

**Ongoing (24/7)**
- [ ] Monitor submission status
- [ ] Prepare responses to rejection comments
- [ ] Ready for rapid re-submission if needed

---

## 🔨 Production Build Creation

### Step 1: Production Environment Setup (30 min)

**Owner:** DevOps Lead

**Checklist:**
- [ ] Firebase production project created: `yourwish-chess`
- [ ] Production credentials retrieved
- [ ] `.env.production` file created with:
  - [ ] ENVIRONMENT=production
  - [ ] FIREBASE_API_KEY (LIVE key)
  - [ ] REVENUECAT_KEY (LIVE key: pk_live_...)
  - [ ] All Firebase endpoints pointing to production
- [ ] Credentials securely stored
- [ ] No debug flags enabled

**Completion Time:** _____ (Expected: 30 min)  
**Issues:** _____________________________________  
**Sign-off:** _________________ Date: _____

---

### Step 2: Android Production Build (1.5-2 hours)

**Owner:** Mobile Lead

**Substeps:**

**2.1 Keystore Generation** (20 min)
```bash
keytool -genkey -v -keystore ~/chess.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias chess-key
```

- [ ] Keystore file created at: `~/chess.keystore`
- [ ] Keystore password: _________________ (SECURE)
- [ ] Key alias: chess-key
- [ ] Key password: _________________ (SECURE)
- [ ] Validity verified: 10000 days

**Completion Time:** _____ (Expected: 20 min)

---

**2.2 Gradle Signing Configuration** (30 min)

- [ ] `android/app/build.gradle` updated with:
  - [ ] signingConfigs.release configured
  - [ ] Keystore path correct
  - [ ] Environment variables used for passwords
  - [ ] minifyEnabled = true
  - [ ] shrinkResources = true
  - [ ] ProGuard rules applied

**Completion Time:** _____ (Expected: 15 min)

---

**2.3 Build Release APK** (45 min - 1.5 hours)

```bash
source .env.production
flutter clean
flutter pub get
dart run build_runner build
flutter build apk --release \
  --dart-define=ENVIRONMENT=$ENVIRONMENT \
  --dart-define=FIREBASE_PROJECT=$FIREBASE_PROJECT \
  --dart-define=REVENUECAT_KEY=$REVENUECAT_KEY
```

- [ ] Build completed successfully
- [ ] No errors or warnings
- [ ] APK location: `build/app/outputs/apk/release/app-release.apk`
- [ ] APK file size: _________ MB (target: < 100 MB)
- [ ] MD5 hash: _________________________________
- [ ] Build time: _________ seconds

**Completion Time:** _____ (Expected: 1-1.5 hours)

---

**2.4 APK Verification** (15 min)

```bash
jarsigner -verify -verbose build/app/outputs/apk/release/app-release.apk
zipalign -v 4 build/app/outputs/apk/release/app-release.apk \
  build/app/outputs/apk/release/app-release-aligned.apk
```

- [ ] Signature verified
- [ ] Alignment verified
- [ ] APK ready for upload

**Completion Time:** _____ (Expected: 15 min)

---

### Step 3: iOS Production Build (1.5-2 hours)

**Owner:** Mobile Lead

**Substeps:**

**3.1 Code Signing Setup** (20 min)

- [ ] Xcode team ID configured
- [ ] Distribution certificate installed
- [ ] Provisioning profile current and valid
- [ ] Bundle ID verified: `com.yourwish.chess`
- [ ] No code signing errors

**Completion Time:** _____ (Expected: 20 min)

---

**3.2 Build Release IPA** (45 min - 1.5 hours)

```bash
source .env.production
flutter clean
flutter pub get
dart run build_runner build
flutter build ios --release \
  --dart-define=ENVIRONMENT=$ENVIRONMENT \
  --dart-define=FIREBASE_PROJECT=$FIREBASE_PROJECT \
  --dart-define=REVENUECAT_KEY=$REVENUECAT_KEY

cd build/ios/iphoneos
mkdir -p Payload
cp -r Runner.app Payload/
zip -r Chess.ipa Payload/
cp Chess.ipa ../../../
cd ../../../
```

- [ ] Build completed successfully
- [ ] No errors or warnings
- [ ] IPA location: `Chess.ipa`
- [ ] IPA file size: _________ MB (target: < 150 MB)
- [ ] MD5 hash: _________________________________
- [ ] Build time: _________ seconds

**Completion Time:** _____ (Expected: 1-1.5 hours)

---

**3.3 IPA Validation** (15 min)

```bash
xcrun altool --validate-app -f Chess.ipa -t ios \
  -u "YOUR_APPLE_ID" -p "APP_SPECIFIC_PASSWORD"
unzip -l Chess.ipa | head -20
```

- [ ] IPA validation passed
- [ ] Package structure verified
- [ ] Ready for App Store upload

**Completion Time:** _____ (Expected: 15 min)

---

### Step 4: Build Quality Verification (45 min)

**Owner:** QA Lead

**Performance Baseline on Release Build:**

```bash
# Run on physical device
flutter run --release

# Measure and record:
```

**Android Device:**
- [ ] Device: _______________
- [ ] OS Version: _______________
- [ ] Startup time: _________ seconds (target: < 3 sec)
- [ ] Memory usage: _________ MB (target: < 200 MB)
- [ ] Battery impact (1 hour): _________% (target: < 10%)

**iOS Device:**
- [ ] Device: _______________
- [ ] OS Version: _______________
- [ ] Startup time: _________ seconds (target: < 3 sec)
- [ ] Memory usage: _________ MB (target: < 200 MB)
- [ ] Battery impact (1 hour): _________% (target: < 10%)

**Verification:**
- [ ] APK size acceptable (< 100 MB)
- [ ] IPA size acceptable (< 150 MB)
- [ ] Startup times within target
- [ ] Memory usage acceptable
- [ ] Battery impact acceptable
- [ ] No crashes in release build

**Issues Found:** _________________________________  
**Completion Time:** _____ (Expected: 45 min)  
**Sign-off:** _________________ Date: _____

---

## 📱 App Store Listing Preparation

### Step 5: Store Listing Content (1.5-2 hours)

**Owner:** Marketing Lead

**5.1 Application Assets**
- [ ] App icon (1024x1024 PNG): Location: _________________
- [ ] Feature graphic (1024x500): Location: _________________
- [ ] Screenshots (1080x1920, 5-8 total):
  - [ ] Screenshot 1: _________________
  - [ ] Screenshot 2: _________________
  - [ ] Screenshot 3: _________________
  - [ ] Screenshot 4: _________________
  - [ ] Screenshot 5: _________________
  - [ ] Screenshot 6: _________________
  - [ ] Screenshot 7: _________________
  - [ ] Screenshot 8: _________________

**Completion Time:** _____ (Expected: 1-1.5 hours)

---

**5.2 Descriptive Copy**

- [ ] App name: "Chess Tactics Master"
- [ ] Short description (max 80 characters):
  ```
  _________________________________________________________________
  ```

- [ ] Full description (max 4000 characters):
  ```
  _________________________________________________________________
  _________________________________________________________________
  ```

- [ ] Category: Games > Puzzle / Strategy

- [ ] Keywords: Chess, Puzzles, Learning, Tactics, Strategy

- [ ] Tagline/Subtitle:
  ```
  _________________________________________________________________
  ```

**Completion Time:** _____ (Expected: 30 min)

---

**5.3 Privacy & Legal**

- [ ] Privacy Policy URL: _______________________
  - [ ] Published and publicly accessible
  - [ ] Includes Firebase Analytics data usage
  - [ ] Includes RevenueCat data usage
  - [ ] Includes GDPR/CCPA compliance info

- [ ] Terms of Service URL: _______________________
  - [ ] Published and publicly accessible
  - [ ] Includes subscription terms
  - [ ] Includes cancellation instructions
  - [ ] Includes refund policy

- [ ] Support URL: _______________________

- [ ] Developer Website: _______________________

**Completion Time:** _____ (Expected: 30 min)

---

### Step 6: Content Rating (1 hour)

**Owner:** Legal/Compliance

**Google Play Store - IARC Rating:**

Complete questionnaire:
- [ ] IARC account created
- [ ] Questionnaire completed with ratings
- [ ] Rating certificate obtained: _______________________
- [ ] Age rating: [E / T / M / AO]

---

**Apple App Store - Age Rating:**

Complete age rating:
- [ ] Violence: [None / Infrequent/Mild / Frequent/Intense]
- [ ] Sexual content: [None / Infrequent/Mild / Frequent/Intense]
- [ ] Profanity: [None / Infrequent/Mild / Frequent/Intense]
- [ ] Substances: [None / Infrequent/Mild / Frequent/Intense]
- [ ] Gambling: [None / Infrequent/Mild / Frequent/Intense]

---

**Rating Verification:**
- [ ] Both content ratings completed
- [ ] Ratings justified and appropriate
- [ ] Certificates stored securely

**Completion Time:** _____ (Expected: 1 hour)

---

## 📊 Pre-Submission Verification

### Step 7: Final Checklist (1-2 hours)

**Owner:** Release Manager

**Android (Google Play):**
- [ ] Package name verified: `com.yourwish.chess`
- [ ] Version code: 1 (increment for updates)
- [ ] Version name: 1.0.0
- [ ] Minimum API level: 21 (Android 5.0)
- [ ] Target API level: 34 (Android 14)
- [ ] APK size verified: _________ MB
- [ ] APK signed and verified
- [ ] Store listing complete
- [ ] Privacy policy published
- [ ] Content rating obtained
- [ ] No test data or debug builds

**iOS (Apple App Store):**
- [ ] Bundle identifier verified: `com.yourwish.chess`
- [ ] Version: 1.0.0
- [ ] Build number: 1
- [ ] Minimum iOS: 14.0
- [ ] Supported devices: iPhone + iPad
- [ ] IPA size verified: _________ MB
- [ ] IPA validated and verified
- [ ] Store listing complete
- [ ] Privacy policy published
- [ ] Age rating completed
- [ ] No test data or debug builds

**Completion Time:** _____ (Expected: 1-2 hours)

---

## 📤 Store Submission

### Step 8: Google Play Store Submission (30 min)

**Owner:** Mobile Lead

**Submission Procedure:**
1. [ ] Go to https://play.google.com/console
2. [ ] Sign in with appropriate Google account
3. [ ] Navigate to app: "Chess Tactics Master"
4. [ ] Click "Create new release"
5. [ ] Select "Production" track
6. [ ] Upload `app-release.apk`
7. [ ] Fill in release notes:
   ```
   _________________________________________________________________
   _________________________________________________________________
   ```
8. [ ] Review all information on store listing page
9. [ ] Verify content rating certificate
10. [ ] Accept declaration: "I confirm..."
11. [ ] Click "Submit for review"

**Submission Details:**
- [ ] APK uploaded successfully
- [ ] Submission date/time: _________________________
- [ ] Expected review time: 1-3 hours
- [ ] Confirmation email received: ✓ Yes / ✗ No

**Status Tracking:**
- [ ] Review started: _________ (date/time)
- [ ] Policy review: _________ (date/time)
- [ ] Approved: _________ (date/time)
- [ ] Live in store: _________ (date/time)

**Completion Time:** _____ (Expected: 30 min)

---

### Step 9: Apple App Store Submission (1-2 hours)

**Owner:** Mobile Lead

**Submission Procedure:**
1. [ ] Go to https://appstoreconnect.apple.com
2. [ ] Sign in with Apple Developer account
3. [ ] Navigate to app: "Chess Tactics Master"
4. [ ] Click "Version or Platform" → "iOS"
5. [ ] Enter version information (1.0.0)
6. [ ] Upload IPA:
   - [ ] Via Xcode (Organizer) OR
   - [ ] Via Transporter app
7. [ ] Wait for build processing (~10-15 minutes)
8. [ ] Complete app information:
   - [ ] App name
   - [ ] Subtitle
   - [ ] Primary category
   - [ ] Keywords
   - [ ] Description
   - [ ] Support URL
   - [ ] Privacy policy URL
9. [ ] Add screenshots and previews
10. [ ] Complete general app information:
    - [ ] Age rating
    - [ ] Content rights confirmed
    - [ ] IDFA usage: [Yes / No]
11. [ ] Add reviewer notes:
    ```
    _________________________________________________________________
    _________________________________________________________________
    ```
12. [ ] Click "Submit for Review"

**Submission Details:**
- [ ] IPA uploaded successfully
- [ ] Build processing complete: _________ (date/time)
- [ ] App information complete: ✓ Yes
- [ ] Submission date/time: _________________________
- [ ] Expected review time: 1-2 days
- [ ] Confirmation email received: ✓ Yes / ✗ No

**Status Tracking:**
- [ ] In Review: _________ (date/time)
- [ ] Approved: _________ (date/time)
- [ ] Live in store: _________ (date/time)

**Completion Time:** _____ (Expected: 1-2 hours)

---

## 🚨 Rejection Handling

### If App Rejected

**Step 1: Document Issue**
- [ ] Rejection reason recorded: _______________________
- [ ] Full rejection message saved: _______________________
- [ ] Screenshots of rejection: ✓ Yes
- [ ] Date received: _________________________

**Step 2: Root Cause Analysis**
- [ ] Is it code-related? (Yes / No)
- [ ] Is it content/metadata? (Yes / No)
- [ ] Is it policy/compliance? (Yes / No)
- [ ] Required fix: _________________________________

**Step 3: Create Fix**

**For Code Issues:**
- [ ] Bug identified and fixed
- [ ] Fix tested on release build
- [ ] Code review completed
- [ ] Merged to main branch

**For Content/Metadata Issues:**
- [ ] Description/copy updated
- [ ] Screenshot replaced/added
- [ ] Privacy policy updated
- [ ] Content rating adjusted

**Step 4: Re-submission**
- [ ] Increment build number/version code
- [ ] Rebuild and re-sign
- [ ] Re-upload to store
- [ ] Add explanation to reviewer notes:
  ```
  _________________________________________________________________
  _________________________________________________________________
  ```
- [ ] Submit for review

**Resubmission Tracking:**
- [ ] Resubmission date: _________________________
- [ ] Expected re-review time: 1-2 days
- [ ] Status: ⏳ Pending / ✓ Approved / ✗ Rejected Again

---

## 📊 Overall Progress

| Task | Owner | Status | Start | End | Issues |
|------|-------|--------|-------|-----|--------|
| Prod Env Setup | DevOps | ⏳ | / | / | |
| Android Build | Mobile | ⏳ | / | / | |
| iOS Build | Mobile | ⏳ | / | / | |
| QA Verification | QA | ⏳ | / | / | |
| Store Listings | Marketing | ⏳ | / | / | |
| Legal/Compliance | Legal | ⏳ | / | / | |
| Google Play Submit | Mobile | ⏳ | / | / | |
| Apple App Submit | Mobile | ⏳ | / | / | |
| Monitor Submissions | Release Mgr | ⏳ | / | / | |

---

## 📋 Daily Standups

### Day 1 (2026-09-09)

**Standup Time:** 9:00 AM UTC

**Morning Status:**
- [ ] Team roles confirmed
- [ ] Credentials prepared and secured
- [ ] Hardware/infrastructure ready
- [ ] All tools available and working

**Progress by Noon:**
- Builds completed: _____
- Issues found: _____
- On track: Yes / No

**Afternoon Update (3:00 PM):**
- Build verification complete: Yes / No
- Quality checks passed: Yes / No / Partial
- Blockers: _____

**End of Day Report (6:00 PM):**
- Day 1 complete: Yes / No
- Builds ready for submission: Yes / No
- Plan for Day 2: _____

---

### Day 2 (2026-09-10)

**Standup Time:** 9:00 AM UTC

**Morning Status:**
- [ ] Builds validated
- [ ] Store listing content ready
- [ ] Privacy policy/ToS finalized
- [ ] Graphics and screenshots ready

**Progress Update (3:00 PM):**
- Store listings complete: Yes / No
- Content ratings obtained: Yes / No
- All information verified: Yes / No

**End of Day Report (6:00 PM):**
- Day 2 complete: Yes / No
- Ready for submission: Yes / No
- Expected submission time: _____

---

### Day 3 (2026-09-11)

**Standup Time:** 9:00 AM UTC

**Submission Status:**
- [ ] Final checks complete
- [ ] Both stores ready
- [ ] Submission procedure reviewed

**Morning Update (10:00 AM):**
- Google Play submitted: Yes / No - Time: _____
- Apple App Store submitted: Yes / No - Time: _____

**Ongoing Monitoring:**
- [ ] Google Play status: _________________ (Last checked: _____  at _____)
- [ ] Apple App Status: _________________ (Last checked: _____ at _____)
- [ ] Issues/feedback: _________________________________

---

## ✅ Phase 4 Completion Checklist

- [ ] Production environment configured
- [ ] Android APK built, signed, and optimized
- [ ] iOS IPA built, signed, and validated
- [ ] Builds tested on release configuration
- [ ] Store listings complete with all metadata
- [ ] Screenshots and graphics prepared
- [ ] Privacy policy published and complete
- [ ] Terms of Service published and complete
- [ ] Content ratings obtained (both stores)
- [ ] Submitted to Google Play Store
- [ ] Submitted to Apple App Store
- [ ] Submission dates documented
- [ ] Monitoring procedures in place
- [ ] Rejection response plan ready

---

## 📞 Support & Escalation

**Release Manager Contact:** ________________  
**Mobile Lead Contact:** ________________  
**DevOps Lead Contact:** ________________  
**Marketing Lead Contact:** ________________  
**Legal/Compliance Contact:** ________________  

**Critical Issue Escalation:**
1. Report to Release Manager immediately
2. Assess impact on submission timeline
3. Emergency meeting if submission blocked
4. Document resolution

---

## 🎯 Phase 4 → Phase 5 Transition

**Phase 4 Complete Date/Time:** _________________

**Final Approval:**
- [ ] All builds created and verified
- [ ] All submissions completed
- [ ] Monitoring procedures active
- [ ] Team ready for next phase

**Signed by:**
- Release Manager: _________________ Date: _____
- Mobile Lead: _________________ Date: _____
- QA Lead: _________________ Date: _____

---

## ➡️ Transition to Phase 5: Phased Rollout & Launch

**Phase 5 Start Date:** Upon approval from both app stores  
**Phase 5 Owner:** Release Manager / Product Lead  
**Phase 5 Duration:** 2-4 weeks

**Phase 5 Activities:**
- Monitor app store approvals
- Prepare phased rollout strategy (10% → 50% → 100%)
- Set up metrics monitoring and alerts
- Prepare release communications
- Coordinate marketing launch

---

**Document Version:** 1.0  
**Last Updated:** 2026-09-09  
**Status:** Ready for team execution
