#!/bin/bash

# List Swift language features the compiler knows about.
#
# Usage:
#
#     swift-list-features [version]     # default: main branch
#
# Examples:
#
#     swift-list-features               # Queries main branch
#     swift-list-features 6.1           # Queries release/6.1 branch
#
# The output is in CSV format (delimiter: comma, including a header row).
# This allows you to format/filter/process the output by piping it into other
# tools.
#
# NOTE: See also `swift -print-supported-features` (introduced in Swift 6.2).
# It outputs essentially the same information about upcoming and experimental
# features in JSON format. But only for the compiler version you have installed,
# so this script is still useful for comparing multiple compiler versions.
#
# Examples:
#
# 1) Print a nicely formatted table using [xan](https://github.com/medialab/xan):
#
#    ```sh
#    swift-list-features.sh 6.1 | xan view --all
#    ```
#
# 2) Also sort the output by type and language mode, and tell xan to group the table by type:
#
#    ```sh
#    swift-list-features.sh main | xan sort -s "type,language_mode" | xan view --all --groupby "type"
#    ```
#
# 3) Print SwiftPM-compatible settings for all features with a given language mode:
#
#    ```sh
#    swift-list-features.sh main \
#        | xan filter 'type eq "Upcoming" && language_mode eq "7"' \
#        | xan select name | xan behead \
#        | sed 's/^/.enableUpcomingFeature("/; s/$/"),/'
#    ```
#
#    Example output:
#    
#    ```
#    .enableUpcomingFeature("ExistentialAny"),
#    .enableUpcomingFeature("InferIsolatedConformances"),
#    .enableUpcomingFeature("InternalImportsByDefault"),
#    .enableUpcomingFeature("MemberImportVisibility"),
#    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
#    ```
#
# This script uses curl to download the file in which the language features
# are defined from the Swift repo and uses Clang to parse it.
#
# Original author: Gor Gyolchanyan
# <https://forums.swift.org/t/how-to-test-if-swiftc-supports-an-upcoming-experimental-feature/69095/10>
#
# Enhanced/modified by: Ole Begemann

swift_version=$1

if test -z "$swift_version" || test "$swift_version" = "main"; then
  branch="main"
else
  branch="release/${swift_version}"
fi

GITHUB_URL="https://raw.githubusercontent.com/apple/swift/${branch}/include/swift/Basic/Features.def"
FEATURES_DEF_FILE="$(curl --fail-with-body --silent "${GITHUB_URL}")"
curlStatus=$?
if test $curlStatus -ne 0; then
    echo "$FEATURES_DEF_FILE"
    echo "Error: failed to download '$GITHUB_URL'. Invalid URL?"
    exit $curlStatus
fi

echo "type,name,language_mode,se_number,available_in_prod,description"
clang --preprocess --no-line-commands -nostdinc -x c - <<EOF | sort | sed 's/,SE-0,/,,/'
#define LANGUAGE_FEATURE(FeatureName, SENumber, Description, ...)          ,FeatureName,,SE-SENumber,,Description
#define OPTIONAL_LANGUAGE_FEATURE(FeatureName, SENumber, Description, ...) Optional,FeatureName,,SE-SENumber,,Description
#define UPCOMING_FEATURE(FeatureName, SENumber, Version)                   Upcoming,FeatureName,Version,SE-SENumber,,
#define EXPERIMENTAL_FEATURE(FeatureName, AvailableInProd)                 Experimental,FeatureName,,,AvailableInProd,
${FEATURES_DEF_FILE}
EOF