#!/bin/bash
set -e

# Check if an argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <staging|production>"
    exit 1
fi

release_type=$1

echo "Fetching latest release..."
latest_tag=$(gh release list --limit 1 --json tagName --jq '.[0].tagName // "v0.0.0"')

if [ -z "$latest_tag" ]; then
  echo "No releases found. Using v0.0.0 as the base version."
  latest_tag="v0.0.0"
fi

echo "Latest tag: $latest_tag"

commit_message=$(git log --format=oneline --pretty=format:%s -n 1 $CIRCLE_SHA1)
echo "Commit message: $commit_message"

# Function to increment version
increment_version() {
  local version=$1
  local input=$2

  # Extract major, minor, and patch versions
  IFS='.' read -r major minor patch <<< "${version//v/}"

  # Check input string for [major], [minor], [patch]
  if [[ $input == *"[major]"* ]]; then
    major=$((major + 1))
    minor=0
    patch=0
  elif [[ $input == *"[minor]"* ]]; then
    minor=$((minor + 1))
    patch=0
  else
    # Treat as [patch] if no [major] or [minor] found
    patch=$((patch + 1))
  fi

  # Join version parts and return new version
  new_version="v$major.$minor.$patch"

  echo "$new_version"
}

# Get new version
new_version=$(increment_version "$latest_tag" "$commit_message")
cmd_args=""

if [ "$release_type" = "staging" ]; then
  new_version="$new_version-staging-$CIRCLE_SHA1"
  cmd_args="--prerelease"
elif [ "$release_type" = "production" ]; then
  if [[ $CIRCLE_BRANCH != "master" ]]; then
    echo "Production releases should only be created from the master branch"
    exit 1
  fi
else
  echo "Invalid release type. Use 'staging' or 'production'."
  exit 1
fi

echo "Creating $release_type release: $new_version"

# Check if providers directory exists and contains JAR files
if [ ! -d "./providers" ] || [ -z "$(ls -A ./providers/*.jar 2>/dev/null)" ]; then
    echo "Error: providers directory is missing or contains no JAR files."
    exit 1
fi

release_notes="$commit_message"
if [ "$release_type" = "staging" ]; then
    release_notes="Staging Release: $release_notes"
fi

release_url=$(gh release create "$new_version" ./providers/*.jar --title="$new_version" --notes="$release_notes" $cmd_args)

echo "Release create