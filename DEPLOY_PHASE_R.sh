#!/bin/bash

# Phase R Production Deployment Script
# Chess Tactics Master - Security & Compliance
# Execute locally with Firebase CLI installed

set -e  # Exit on error

echo "=================================="
echo "Phase R Production Deployment"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Pre-deployment checks
echo -e "${YELLOW}Step 1: Pre-Deployment Verification${NC}"
echo "=================================="

# Check Firebase CLI
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}✗ Firebase CLI not found. Install: npm install -g firebase-tools${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Firebase CLI installed${NC}"

# Check if logged in
if ! firebase projects:list &> /dev/null; then
    echo -e "${YELLOW}! Firebase authentication required. Running: firebase login${NC}"
    firebase login
fi
echo -e "${GREEN}✓ Firebase authenticated${NC}"

# Check firestore.rules file
if [ ! -f "firestore.rules" ]; then
    echo -e "${RED}✗ firestore.rules not found in current directory${NC}"
    exit 1
fi
echo -e "${GREEN}✓ firestore.rules file found${NC}"

# Validate rules syntax
echo -e "${YELLOW}Validating Firestore rules syntax...${NC}"
if firebase deploy --dry-run --only firestore:rules --project=yourwish-chess-staging 2>&1 | grep -q "error\|Error"; then
    echo -e "${RED}✗ Rules validation failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Rules syntax valid${NC}"
echo ""

# Step 2: Staging Deployment
echo -e "${YELLOW}Step 2: Staging Deployment${NC}"
echo "=================================="
echo "Deploying to staging: yourwish-chess-staging"
echo ""

firebase deploy --only firestore:rules --project=yourwish-chess-staging

echo -e "${GREEN}✓ Staging deployment complete${NC}"
echo ""

# Step 3: Staging Validation
echo -e "${YELLOW}Step 3: Staging Validation (Manual)${NC}"
echo "=================================="
echo "Please verify staging environment:"
echo "1. Open Firebase Console: https://console.firebase.google.com/project/yourwish-chess-staging"
echo "2. Go to Firestore → Rules"
echo "3. Check that rules are deployed and active"
echo "4. Test user data access controls"
echo "5. Verify audit logging is working"
echo ""
read -p "Press ENTER after staging validation is complete..."
echo ""

# Step 4: Production Deployment
echo -e "${YELLOW}Step 4: Production Deployment${NC}"
echo "=================================="
echo -e "${RED}!!! WARNING: Deploying to PRODUCTION !!!${NC}"
echo "Project: yourwish-chess"
echo ""
read -p "Type 'DEPLOY_TO_PRODUCTION' to confirm: " confirm

if [ "$confirm" != "DEPLOY_TO_PRODUCTION" ]; then
    echo -e "${YELLOW}Production deployment cancelled${NC}"
    exit 0
fi

echo "Deploying to production..."
firebase deploy --only firestore:rules --project=yourwish-chess

echo -e "${GREEN}✓ Production deployment complete${NC}"
echo ""

# Step 5: Production Validation
echo -e "${YELLOW}Step 5: Production Monitoring${NC}"
echo "=================================="
echo "Phase R is now live in production!"
echo ""
echo "Monitor these items:"
echo "1. Firebase Console: https://console.firebase.google.com/project/yourwish-chess"
echo "2. Firestore → Rules (verify deployed)"
echo "3. Firestore → security_audit collection (check audit logs)"
echo "4. Analytics → Performance (check metrics)"
echo "5. Crashlytics (monitor for errors)"
echo ""
echo "If issues occur, run rollback script:"
echo "  bash ROLLBACK_PHASE_R.sh"
echo ""

echo -e "${GREEN}=================================="
echo "Phase R Deployment Complete! ✓"
echo "==================================${NC}"
