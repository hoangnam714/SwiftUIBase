#!/bin/bash

set -euo pipefail

SCHEME="${SCHEME:-SwiftUIBase}"
CONFIGURATION="${CONFIGURATION:-Release}"
OUTPUT_DIR="${OUTPUT_DIR:-./build}"
BUILD_FOR_DISTRIBUTION="${BUILD_FOR_DISTRIBUTION:-YES}"
VERIFY_MODULE_INTERFACE="${VERIFY_MODULE_INTERFACE:-NO}"

IOS_ARCHIVE_PATH="$OUTPUT_DIR/iOS.xcarchive"
SIM_ARCHIVE_PATH="$OUTPUT_DIR/iOS-Simulator.xcarchive"
XCFRAMEWORK_PATH="$OUTPUT_DIR/SwiftUIBase.xcframework"
FRAMEWORK_NAME="SwiftUIBase.framework"
MODULE_NAME="SwiftUIBase"

echo "Cleaning old artifacts..."
rm -rf "$IOS_ARCHIVE_PATH" "$SIM_ARCHIVE_PATH" "$XCFRAMEWORK_PATH"

echo "Archiving iOS device framework..."
xcodebuild archive \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=iOS" \
  -archivePath "$IOS_ARCHIVE_PATH" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION="$BUILD_FOR_DISTRIBUTION" \
  SWIFT_VERIFY_EMITTED_MODULE_INTERFACE="$VERIFY_MODULE_INTERFACE" \
  OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface"

echo "Archiving iOS simulator framework..."
xcodebuild archive \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$SIM_ARCHIVE_PATH" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION="$BUILD_FOR_DISTRIBUTION" \
  SWIFT_VERIFY_EMITTED_MODULE_INTERFACE="$VERIFY_MODULE_INTERFACE" \
  OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface"

echo "Injecting Swift module metadata..."
DERIVED_DATA_DIR="$(ls -dt "$HOME"/Library/Developer/Xcode/DerivedData/SwiftUIBase-* 2>/dev/null | sed -n '1p')"
SIM_MODULE_SOURCE="$DERIVED_DATA_DIR/Build/Intermediates.noindex/ArchiveIntermediates/$SCHEME/BuildProductsPath/Release-iphonesimulator/$MODULE_NAME.swiftmodule"
SIM_FRAMEWORK_MODULES="$SIM_ARCHIVE_PATH/Products/usr/local/lib/$FRAMEWORK_NAME/Modules/$MODULE_NAME.swiftmodule"
IOS_FRAMEWORK_MODULES="$IOS_ARCHIVE_PATH/Products/usr/local/lib/$FRAMEWORK_NAME/Modules/$MODULE_NAME.swiftmodule"

mkdir -p "$SIM_FRAMEWORK_MODULES" "$IOS_FRAMEWORK_MODULES"

if [ ! -d "$SIM_MODULE_SOURCE" ]; then
  echo "Missing simulator module source at: $SIM_MODULE_SOURCE"
  exit 1
fi

cp -R "$SIM_MODULE_SOURCE"/. "$SIM_FRAMEWORK_MODULES"/

for ext in swiftmodule swiftdoc swiftinterface private.swiftinterface package.swiftinterface abi.json; do
  SRC="$SIM_MODULE_SOURCE/arm64-apple-ios-simulator.$ext"
  DST="$IOS_FRAMEWORK_MODULES/arm64-apple-ios.$ext"
  if [ -f "$SRC" ]; then
    cp "$SRC" "$DST"
  fi
done

echo "Creating XCFramework..."
xcodebuild -create-xcframework \
  -framework "$IOS_ARCHIVE_PATH/Products/usr/local/lib/$FRAMEWORK_NAME" \
  -framework "$SIM_ARCHIVE_PATH/Products/usr/local/lib/$FRAMEWORK_NAME" \
  -output "$XCFRAMEWORK_PATH"

echo "Done: $XCFRAMEWORK_PATH"
