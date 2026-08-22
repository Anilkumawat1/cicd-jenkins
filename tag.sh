#!/usr/bin/env bash

set -e

############################################
# Use Java 21
############################################

if ! JAVA_HOME=$(/usr/libexec/java_home -v 21 2>/dev/null); then
    echo "❌ Java 21 is not installed."
    echo "Install it using:"
    echo "brew install openjdk@21"
    exit 1
fi

export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"

echo "Using Java:"
java --version
echo ""

############################################
# Validate repository
############################################

if [ ! -d ".git" ]; then
    echo "❌ This is not a Git repository."
    exit 1
fi

if [ ! -f "pom.xml" ]; then
    echo "❌ pom.xml not found."
    exit 1
fi

############################################
# Ensure working tree is clean
############################################

if [[ -n $(git status --porcelain) ]]; then
    echo "❌ Working tree is not clean."
    echo "Commit or stash your changes first."
    echo ""
    git status --short
    exit 1
fi

############################################
# Current version
############################################

CURRENT_VERSION=$(./mvnw help:evaluate \
    -Dexpression=project.version \
    -q \
    -DforceStdout)

echo "----------------------------------------"
echo "Current Version : $CURRENT_VERSION"
echo "----------------------------------------"

read -rp "New Version (e.g. 1.0.0): " NEW_VERSION

############################################
# Validate version
############################################

if [[ -z "$NEW_VERSION" ]]; then
    echo "❌ Version cannot be empty."
    exit 1
fi

if [[ "$NEW_VERSION" == "$CURRENT_VERSION" ]]; then
    echo "❌ New version must be different from the current version."
    exit 1
fi

if [[ "$NEW_VERSION" =~ ^v ]]; then
    echo "❌ Do not include the 'v' prefix."
    echo "Example: 1.0.0"
    exit 1
fi

if [[ ! "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Invalid version format."
    echo "Use semantic versioning:"
    echo "Example: 1.0.0"
    exit 1
fi

############################################
# Check tag
############################################

if git rev-parse -q --verify "refs/tags/v$NEW_VERSION" >/dev/null; then
    echo "❌ Tag v$NEW_VERSION already exists."
    exit 1
fi

############################################
# Update version
############################################

echo ""
echo "Updating pom.xml..."

./mvnw versions:set \
    -DnewVersion="$NEW_VERSION" \
    -DgenerateBackupPoms=false

############################################
# Build project
############################################

echo ""
echo "Building project..."

if ! ./mvnw clean package -DskipTests; then
    echo ""
    echo "❌ Build failed."
    echo "Reverting pom.xml..."

    git checkout -- pom.xml

    exit 1
fi

echo "✅ Build successful."

############################################
# Commit
############################################

echo ""
echo "Creating release commit..."

git add pom.xml

git commit -m "Release v$NEW_VERSION"

echo "✅ Release commit created."

############################################
# Create tag
############################################

echo ""
echo "Creating tag v$NEW_VERSION..."

git tag "v$NEW_VERSION"

echo "✅ Tag v$NEW_VERSION created."

############################################
# Push commit
############################################

echo ""
echo "Pushing main branch..."

git push origin main

echo "✅ Main branch pushed."

############################################
# Push tag
############################################

echo ""
echo "Pushing release tag..."

git push origin "v$NEW_VERSION"

echo "✅ Tag v$NEW_VERSION pushed."

############################################
# Done
############################################

echo ""
echo "========================================"
echo "🎉 RELEASE COMPLETED"
echo "========================================"
echo ""
echo "Version : v$NEW_VERSION"
echo "Branch  : main"
echo "Tag     : v$NEW_VERSION"
echo ""
echo "Jenkins will:"
echo "  1. Build main → Build + Test only"
echo "  2. Build v$NEW_VERSION → Build + Test + Docker"
echo "  3. Push Docker image to GHCR"
echo ""
echo "========================================"