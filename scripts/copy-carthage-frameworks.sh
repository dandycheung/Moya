#!/bin/sh
# Add Homebrew paths for both Intel (/usr/local) and Apple Silicon (/opt/homebrew).
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

case "$PLATFORM_NAME" in
    macosx) plat=Mac;;
    iphone*) plat=iOS;;
    watch*) plat=watchOS;;
    appletv*) plat=tvOS;;
    *) echo "error: Unknown PLATFORM_NAME: $PLATFORM_NAME"; exit 1;;
esac

for (( n = 0; n < SCRIPT_INPUT_FILE_COUNT; n++ )); do
    VAR=SCRIPT_INPUT_FILE_$n
    framework=$(basename "${!VAR}")
    export SCRIPT_INPUT_FILE_$n="$SRCROOT"/Carthage/Build/$plat/"$framework"
done

carthage copy-frameworks || exit

for (( n = 0; n < SCRIPT_INPUT_FILE_COUNT; n++ )); do
    VAR=SCRIPT_INPUT_FILE_$n
    source=${!VAR}.dSYM
    dest=${BUILT_PRODUCTS_DIR}/$(basename "$source")
    ditto "$source" "$dest" || exit
done