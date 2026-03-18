#!/bin/bash

# Deploy Firestore Security Rules Script
# This script deploys the Firestore security rules to your Firebase project

echo "Deploying Firestore security rules..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Deploy the rules
firebase deploy --only firestore:rules

echo "Firestore security rules deployed successfully!"
