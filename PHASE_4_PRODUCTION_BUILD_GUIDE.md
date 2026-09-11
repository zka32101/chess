# Phase 4: Production Build & App Store Submission - Complete Guide

**Project:** Chess Tactics Master  
**Phase:** 4 - Production Build & Submission  
**Timeline:** 2026-09-09 to 2026-09-11 (2-3 days)  
**Owner:** Mobile Lead / Release Manager

---

## 🎯 Phase 4 Objectives

- [ ] **PRIMARY:** Create production-ready builds (APK & IPA)
- [ ] **SECONDARY:** Prepare app store listings
- [ ] **TERTIARY:** Submit to Google Play Store and Apple App Store
- [ ] **QUATERNARY:** Track submission progress and address rejections

---

## ✅ Pre-Production Checklist

### Go/No-Go Approval Required

Before starting Phase 4, verify:

- [ ] Phase 3 E2E Testing **COMPLETE**
- [ ] All critical issues **RESOLVED**
- [ ] QA team sign-off obtained
- [ ] Release Manager approval granted
- [ ] Go/No-Go decision: **GO**

**Approval Date/Time:** _________________

---

## 📋 Production Configuration Setup

### 1. Configure Production Environment

Create `.env.production`:

```bash
cat > .env.production << 'EOF'
# Production Environment Configuration

ENVIRONMENT=production
FIREBASE_PROJECT=yourwish-chess

# Firebase Production Configuration
FIREBASE_API_KEY=YOUR_PRODUCTION_API_KEY
FIREBASE_AUTH_DOMAIN=yourwish-chess.firebaseapp.com
FIREBASE_DATABASE_URL=https://yourwish-chess-default-rtdb.firebaseio.com
FIREBASE_PROJECT_ID=yourwish-chess
FIREBASE_STORAGE_BUCKET=yourwish-chess.appspot.com
FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID
FIREBASE_APP_ID=YOUR_APP_ID

# RevenueCat Production Configuration (LIVE KEYS)
REVENUECAT_KEY=pk_live_xxxxxxxxxxxxx

# Production Flags
DEBUG_MODE=false
ANALYTICS_DEBUG=false
VERBOSE_LOGGING=false
EOF
```

**Verification:**
- [ ] .env.production created
- [ ] All values populated from production Firebase project
- [ ] RevenueCat LIVE key configured (not sandbox)
- [ ] Sensitive data not logged

---

### 2. Update pubspec.yaml for Production

```yaml
# Ensure these are set for production:

environment:
  sdk: '>=2.17.0 <4.0.0'

version: 1.0.0+1  # Will be updated per release

# No debug dependencies
dependencies:
  # All production dependencies verified
  # No dev dependencies mixed in
```

**Verification:**
- [ ] Version number correct
- [ ] No debug dependencies
- [ ] All dependencies from pub.dev stable versions

---

## 🔨 Android Production Build

### Step 1: Generate Signing Key

```bash
# Create keystore for production signing
keytool -genkey -v -keystore ~/chess.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias chess-key

# Verify keystore
keytool -list -v -keystore ~/chess.keystore
```

**Keystore Details:**
- [ ] Keystore file created: `~/chess.keystore`
- [ ] Keystore password: _________________ (store in secure location)
- [ ] Key alias: `chess-key`
- [ ] Key password: _________________ (store in secure location)
- [ ] Validity: 10000 days (~27 years)

⚠️ **IMPORTANT:** Back up keystore file securely. Loss of keystore means inability to update app.

---

### Step 2: Configure Gradle Signing

Edit `android/app/build.gradle`:

```gradle
android {
    ...
    signingConfigs {
        release {
            storeFile file("$HOME/chess.keystore")
            storePassword System.getenv("KEYSTORE_PASSWORD") ?: "PASSWORD"
            keyAlias "chess-key"
            keyPassword System.getenv("KEY_PASSWORD") ?: "PASSWORD"
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt')
        }
    }
}
```

**Verification:**
- [ ] Signing config added
- [ ] Keystore path correct
- [ ] Minification enabled
- [ ] ProGuard rules applied

---

### Step 3: Build Release APK

```bash
# Set environment
source .env.production

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Generate code
dart run build_runner build

# Build release APK
flutter build apk --release \
  --dart-define=ENVIRONMENT=$ENVIRONMENT \
  --dart-define=FIREBASE_PROJECT=$FIREBASE_PROJECT \
  --dart-define=REVENUECAT_KEY=$REVENUECAT_KEY

# Verify build
file build/app/outputs/apk/release/app-release.apk
```

**Build Output:**
- [ ] Build completed successfully
- [ ] No warnings or errors
- [ ] APK location: `build/app/outputs/apk/release/app-release.apk`
- [ ] APK size: _________ MB
- [ ] Build time: _________ seconds
- [ ] MD5: _________________________________

---

### Step 4: Sign and Optimize

```bash
# APK is already signed by gradle, but verify:
jarsigner -verify -verbose build/app/outputs/apk/release/app-release.apk

# Optional: Run zipalign for optimization
zipalign -v 4 build/app/outputs/apk/release/app-release.apk \
  build/app/outputs/apk/release/app-release-aligned.apk

# Use aligned version
mv build/app/outputs/apk/release/app-release-aligned.apk \
   build/app/outputs/apk/release/app-release.apk
```

**Verification:**
- [ ] Signature verified
- [ ] Alignment verified
- [ ] APK ready for upload

---

## 📱 iOS Production Build

### Step 1: Configure Code Signing

In Xcode (`ios/Runner.xcodeproj`):

1. Open Runner project in Xcode
2. Select Runner target
3. Go to Signing & Capabilities
4. Set Team ID
5. Verify provisioning profile

```bash
# Or from command line:
xcode-select --install
pod setup
cd ios && pod install && cd ..
```

**Verification:**
- [ ] Team ID set in Xcode
- [ ] Development provisioning profile
- [ ] Distribution certificate installed
- [ ] Provisioning profile matches bundle ID

---

### Step 2: Build Release IPA

```bash
# Set environment
source .env.production

# Clean
flutter clean

# Get dependencies
flutter pub get

# Generate code
dart run build_runner build

# Build for iOS
flutter build ios --release \
  --dart-define=ENVIRONMENT=$ENVIRONMENT \
  --dart-define=FIREBASE_PROJECT=$FIREBASE_PROJECT \
  --dart-define=REVENUECAT_KEY=$REVENUECAT_KEY

# Create IPA
cd build/ios/iphoneos
rm -rf Payload
mkdir Payload
cp -r Runner.app Payload/
zip -r Chess.ipa Payload/
cp Chess.ipa ../../../
cd ../../../

# Verify
file Chess.ipa
```

**Build Output:**
- [ ] Build completed successfully
- [ ] No warnings or errors
- [ ] IPA location: `Chess.ipa`
- [ ] IPA size: _________ MB
- [ ] Build time: _________ seconds
- [ ] MD5: _________________________________

---

### Step 3: Validate IPA

```bash
# Validate with Apple
xcrun altool --validate-app -f Chess.ipa -t ios \
  -u "YOUR_APPLE_ID" -p "APP_SPECIFIC_PASSWORD"

# Verify package contents
unzip -l Chess.ipa | head -20
```

**Verification:**
- [ ] IPA validation passed
- [ ] Package structure valid
- [ ] Ready for App Store upload

---

## 📊 Build Quality Verification

### Size Check

- [ ] **Android APK**: _________ MB (target: < 100 MB)
- [ ] **iOS IPA**: _________ MB (target: < 150 MB)
- [ ] Size reasonable for app functionality

### Performance Baseline

Before submission, verify on release build:

```bash
# On physical device:
flutter run --release

# Measure:
- App startup time: _________ seconds (target: < 3 sec)
- Memory usage: _________ MB (target: < 200 MB)
- Battery impact (1 hour): _________% (target: < 10%)
```

---

## 🎯 Store Listing Preparation

### App Store Metadata

Prepare these items for both stores:

**Icon & Screenshots:**
- [ ] App icon (1024x1024 PNG)
- [ ] Feature graphic (1024x500 for Play Store)
- [ ] Screenshots (5-8, 1080x1920)
- [ ] Preview video (optional)

**Text Content:**
- [ ] App name: "Chess Tactics Master"
- [ ] Short description (80 chars): _______________________
- [ ] Full description (4000 chars): (prepared in separate doc)
- [ ] Tagline/Subtitle: _______________________
- [ ] Keywords/Categories: Chess, Puzzles, Learning, Games
- [ ] Content rating: (See ratings section below)

**Links:**
- [ ] Privacy Policy URL: _______________________
- [ ] Terms of Service URL: _______________________
- [ ] Support URL: _______________________
- [ ] Developer Website: _______________________

---

## 🔐 Content Rating & Compliance

### Content Rating Questionnaire

Both stores require content ratings:

**Google Play Store - IARC Rating:**
1. Complete IARC questionnaire
2. Select rating categories:
   - [ ] Violence
   - [ ] Sexual content
   - [ ] Profanity
   - [ ] Alcohol/Tobacco
   - [ ] Gambling
   
3. Obtain rating certificate

**Apple App Store - Age Rating:**
1. Complete app information
2. Select content rating:
   - [ ] Violence
   - [ ] Sexual content
   - [ ] Profanity
   - [ ] Substances
   - [ ] Gambling

---

### Compliance Checklist

- [ ] Privacy Policy addresses data collection
- [ ] Privacy Policy includes:
  - [ ] Firebase Analytics data use
  - [ ] Crash reporting
  - [ ] Third-party services (RevenueCat)
  - [ ] GDPR compliance (if EU)
  - [ ] CCPA compliance (if California)

- [ ] Terms of Service include:
  - [ ] Subscription terms
  - [ ] In-app purchase policy
  - [ ] Cancellation instructions
  - [ ] Refund policy

---

## 📤 Google Play Store Submission

### Pre-Submission Checklist

- [ ] **App Bundle/APK**: Built and tested
- [ ] **Package name**: `com.yourwish.chess` (unique)
- [ ] **Version code**: 1 (increment for updates)
- [ ] **Version name**: 1.0.0
- [ ] **Minimum API level**: 21 (Android 5.0)
- [ ] **Target API level**: 34 (Android 14)
- [ ] **Required permissions**: Justified and documented
- [ ] **Privacy policy**: Public and complete
- [ ] **Content rating**: Completed

### Submission Steps

1. **Go to Google Play Console:**
   - URL: https://play.google.com/console
   - [ ] Sign in with appropriate account
   - [ ] Create or select app

2. **Upload APK:**
   - [ ] Click "Internal testing" → "Create release"
   - [ ] Upload `app-release.apk`
   - [ ] Add release notes
   - [ ] Review app content (required fields)

3. **Fill Store Listing:**
   - [ ] App title
   - [ ] Short description
   - [ ] Full description
   - [ ] Screenshots (5-8)
   - [ ] Feature graphic
   - [ ] Category
   - [ ] Content rating
   - [ ] Privacy policy
   - [ ] Terms of service

4. **Pricing & Distribution:**
   - [ ] Select: "Free"
   - [ ] Select countries (all or specific)
   - [ ] Content rating certificate

5. **Review & Submit:**
   - [ ] Review all information
   - [ ] Accept declaration
   - [ ] Click "Submit for review"

**Submission:**
- [ ] Date submitted: _________________
- [ ] Expected review time: 1-3 hours
- [ ] Review status: Check Play Console daily

---

## 🍎 Apple App Store Submission

### Pre-Submission Checklist

- [ ] **IPA**: Built and validated
- [ ] **Bundle identifier**: Matches provisioning
- [ ] **Version**: 1.0.0
- [ ] **Build number**: 1
- [ ] **Minimum iOS**: 14.0
- [ ] **Supported devices**: iPhone + iPad
- [ ] **Privacy policy**: Public and complete
- [ ] **Developer account**: Ready

### Submission Steps

1. **Go to App Store Connect:**
   - URL: https://appstoreconnect.apple.com
   - [ ] Sign in with Apple Developer account
   - [ ] Create or select app

2. **Prepare Version:**
   - [ ] Click "Version or Platform" → "iOS"
   - [ ] Fill in version information
   - [ ] Upload IPA via Xcode or web

3. **Fill App Information:**
   - [ ] App name
   - [ ] Subtitle
   - [ ] Primary category
   - [ ] Keywords
   - [ ] Description
   - [ ] Support URL
   - [ ] Marketing URL
   - [ ] Privacy policy

4. **Add Screenshots & Previews:**
   - [ ] Screenshots for each device size
   - [ ] Video preview (optional)
   - [ ] Feature graphic

5. **General App Information:**
   - [ ] Age rating
   - [ ] Content rights
   - [ ] Advertising ID
   - [ ] IDFA usage
   - [ ] Add to Siri (if applicable)

6. **Review Information:**
   - [ ] Reviewer notes
   - [ ] Demo account (if needed)
   - [ ] Sign-in credentials
   - [ ] Testing instructions

7. **Review & Submit:**
   - [ ] Review all information
   - [ ] Click "Submit for Review"

**Submission:**
- [ ] Date submitted: _________________
- [ ] Expected review time: 1-2 days
- [ ] Review status: Check App Store Connect

---

## 🎯 Submission Tracking

### Google Play Store

| Milestone | Timeline | Status | Date |
|-----------|----------|--------|------|
| Submission | Immediate | ⏳ | _____ |
| Initial Review | 1-3 hours | ⏳ | _____ |
| Policy Review | 1-24 hours | ⏳ | _____ |
| Approval | 24-48 hours | ⏳ | _____ |
| Live in Store | Within 2 hours of approval | ⏳ | _____ |

### Apple App Store

| Milestone | Timeline | Status | Date |
|-----------|----------|--------|------|
| Submission | Immediate | ⏳ | _____ |
| Technical Review | 1-2 days | ⏳ | _____ |
| Review | 1-3 days | ⏳ | _____ |
| Approval | 1-5 days | ⏳ | _____ |
| Live in Store | Within 1-2 hours of approval | ⏳ | _____ |

---

## 🚨 Handling Rejections

### If App Rejected

1. **Read rejection reason carefully**
2. **Document the issue** in PHASE_4 issues log
3. **Create fix if needed**
4. **Re-submit with changes**

**Common Rejection Reasons:**

**Google Play:**
- Incomplete privacy policy (include all data usage)
- Ads not properly labeled
- Subscription issues
- Policy violations

**Apple App Store:**
- Incomplete privacy policy (especially data collection)
- Subscription not clearly presented
- Missing app preview
- Content guidelines violation

**Fix Process:**
1. Fix issue in code or store listing
2. Increment build number
3. Rebuild and re-upload
4. Re-submit for review

---

## ✅ Phase 4 Completion Checklist

- [ ] Production builds created (Android APK + iOS IPA)
- [ ] Builds signed with production credentials
- [ ] Builds tested on release configuration
- [ ] Store listings complete with all metadata
- [ ] Privacy policy and ToS published
- [ ] Content ratings obtained
- [ ] Submitted to Google Play Store
- [ ] Submitted to Apple App Store
- [ ] Submission dates documented
- [ ] Daily check-ins on review status
- [ ] Ready to respond to feedback/rejections

---

## 📋 Next Steps

**Phase 5: Phased Rollout & Launch**
- Wait for app store approvals
- Once both approved, begin phased rollout
- Start with 10% user release
- Monitor metrics and expand gradually

---

**Document Version:** 1.0  
**Last Updated:** 2026-09-09  
**Status:** Ready for team execution
