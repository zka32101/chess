#!/bin/bash

# Phase R Rollback Script
# Reverts Firestore rules to previous version if deployment issues occur

set -e

echo "=================================="
echo "Phase R - Emergency Rollback"
echo "=================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verify Firebase CLI
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}✗ Firebase CLI not found${NC}"
    exit 1
fi

echo -e "${RED}!!! WARNING: ROLLBACK WILL REVERT PRODUCTION RULES !!!${NC}"
echo ""
echo "This will restore the previous Firestore rules version."
echo "Users may experience temporary access issues during rollback."
echo ""
read -p "Type 'ROLLBACK' to confirm: " confirm

if [ "$confirm" != "ROLLBACK" ]; then
    echo -e "${YELLOW}Rollback cancelled${NC}"
    exit 0
fi

echo ""
echo "Executing rollback on production..."
echo ""

# Get current rules version
echo "Fetching current rules from production..."
firebase rules:list --project=yourwish-chess 2>&1 | head -20

echo ""
echo -e "${YELLOW}Manual Steps Required:${NC}"
echo ""
echo "1. Go to Firebase Console:"
echo "   https://console.firebase.google.com/project/yourwish-chess"
echo ""
echo "2. Navigate to: Firestore Database → Rules"
echo ""
echo "3. Click 'Versions' or 'Release History' tab"
echo ""
echo "4. Select the previous rules version (before Phase R)"
echo ""
echo "5. Click 'Publish' to restore previous version"
echo ""
echo "6. Confirm the rollback"
echo ""
echo -e "${GREEN}Rollback process initiated${NC}"
echo ""
echo "After manual rollback completes:"
echo "- Monitor production in Firebase Console"
echo "- Check Firestore → security_audit for any issues"
echo "- Report incident to security team"
echo "- Schedule post-mortem meeting"
echo ""

