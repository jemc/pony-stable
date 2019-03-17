#! /bin/bash

REPO_TYPE=debian
PACKAGE_VERSION=$1  # e.g., 0.24.0
DISTRO=$2 # e.g., bionic

if [[ "$PACKAGE_VERSION" == "" ]]; then
  echo "Error! PACKAGE_VERSION (argument 1) required!"
  exit 1
fi

if [[ "$DISTRO" == "" ]]; then
  echo "Error! DISTRO (argument 2) required!"
  exit 1
fi

BINTRAY_REPO_NAME="ponylang-debian"
OUTPUT_TARGET="bintray_${REPO_TYPE}_${DISTRO}.json"

DATE="$(date +%Y-%m-%d)"

case "$REPO_TYPE" in
  "debian")
    FILES="\"files\":
        [
          {
            \"includePattern\": \"/home/travis/build/ponylang/pony-stable/(pony-stable_.*${DISTRO}.*.deb)\", \"uploadPattern\": \"pool/main/p/pony-stable/\$1\",
            \"matrixParams\": {
            \"deb_distribution\": \"${DISTRO}\",
            \"deb_component\": \"main\",
            \"deb_architecture\": \"amd64\"}
         }
       ],
       \"publish\": true"
    ;;
esac

JSON="{
  \"package\": {
    \"repo\": \"$BINTRAY_REPO_NAME\",
    \"name\": \"pony-stable\",
    \"subject\": \"pony-language\",
    \"website_url\": \"https://www.ponylang.io/\",
    \"issue_tracker_url\": \"https://github.com/ponylang/pony-stable/issues\",
    \"vcs_url\": \"https://github.com/ponylang/pony-stable.git\",
    \"licenses\": [\"BSD 2-Clause\"],
    \"github_repo\": \"ponylang/pony-stable\",
    \"github_release_notes_file\": \"CHANGELOG.md\",
    \"public_download_numbers\": true
  },
  \"version\": {
    \"name\": \"$PACKAGE_VERSION\",
    \"desc\": \"pony-stable release $PACKAGE_VERSION\",
    \"released\": \"$DATE\",
    \"vcs_tag\": \"$PACKAGE_VERSION\",
    \"github_use_tag_release_notes\": true,
    \"github_release_notes_file\": \"CHANGELOG.md\"
  },"

JSON="$JSON$FILES}"

echo "Writing JSON to file: $OUTPUT_TARGET, from within $(pwd) ..."
echo "$JSON" > "$OUTPUT_TARGET"

echo "=== WRITTEN FILE =========================="
cat -v "$OUTPUT_TARGET"
echo "==========================================="

