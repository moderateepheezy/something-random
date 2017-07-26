#!/bin/sh
set -e

echo "mkdir -p ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
mkdir -p "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"

SWIFT_STDLIB_PATH="${DT_TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}"

install_framework()
{
  if [ -r "${BUILT_PRODUCTS_DIR}/$1" ]; then
    local source="${BUILT_PRODUCTS_DIR}/$1"
  elif [ -r "${BUILT_PRODUCTS_DIR}/$(basename "$1")" ]; then
    local source="${BUILT_PRODUCTS_DIR}/$(basename "$1")"
  elif [ -r "$1" ]; then
    local source="$1"
  fi

  local destination="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"

  if [ -L "${source}" ]; then
      echo "Symlinked..."
      source="$(readlink "${source}")"
  fi

  # use filter instead of exclude so missing patterns dont' throw errors
  echo "rsync -av --filter \"- CVS/\" --filter \"- .svn/\" --filter \"- .git/\" --filter \"- .hg/\" --filter \"- Headers\" --filter \"- PrivateHeaders\" --filter \"- Modules\" \"${source}\" \"${destination}\""
  rsync -av --filter "- CVS/" --filter "- .svn/" --filter "- .git/" --filter "- .hg/" --filter "- Headers" --filter "- PrivateHeaders" --filter "- Modules" "${source}" "${destination}"

  local basename
  basename="$(basename -s .framework "$1")"
  binary="${destination}/${basename}.framework/${basename}"
  if ! [ -r "$binary" ]; then
    binary="${destination}/${basename}"
  fi

  # Strip invalid architectures so "fat" simulator / device frameworks work on device
  if [[ "$(file "$binary")" == *"dynamically linked shared library"* ]]; then
    strip_invalid_archs "$binary"
  fi

  # Resign the code if required by the build settings to avoid unstable apps
  code_sign_if_enabled "${destination}/$(basename "$1")"

  # Embed linked Swift runtime libraries. No longer necessary as of Xcode 7.
  if [ "${XCODE_VERSION_MAJOR}" -lt 7 ]; then
    local swift_runtime_libs
    swift_runtime_libs=$(xcrun otool -LX "$binary" | grep --color=never @rpath/libswift | sed -E s/@rpath\\/\(.+dylib\).*/\\1/g | uniq -u  && exit ${PIPESTATUS[0]})
    for lib in $swift_runtime_libs; do
      echo "rsync -auv \"${SWIFT_STDLIB_PATH}/${lib}\" \"${destination}\""
      rsync -auv "${SWIFT_STDLIB_PATH}/${lib}" "${destination}"
      code_sign_if_enabled "${destination}/${lib}"
    done
  fi
}

# Signs a framework with the provided identity
code_sign_if_enabled() {
  if [ -n "${EXPANDED_CODE_SIGN_IDENTITY}" -a "${CODE_SIGNING_REQUIRED}" != "NO" -a "${CODE_SIGNING_ALLOWED}" != "NO" ]; then
    # Use the current code_sign_identitiy
    echo "Code Signing $1 with Identity ${EXPANDED_CODE_SIGN_IDENTITY_NAME}"
    local code_sign_cmd="/usr/bin/codesign --force --sign ${EXPANDED_CODE_SIGN_IDENTITY} ${OTHER_CODE_SIGN_FLAGS} --preserve-metadata=identifier,entitlements '$1'"

    if [ "${COCOAPODS_PARALLEL_CODE_SIGN}" == "true" ]; then
      code_sign_cmd="$code_sign_cmd &"
    fi
    echo "$code_sign_cmd"
    eval "$code_sign_cmd"
  fi
}

# Strip invalid architectures
strip_invalid_archs() {
  binary="$1"
  # Get architectures for current file
  archs="$(lipo -info "$binary" | rev | cut -d ':' -f1 | rev)"
  stripped=""
  for arch in $archs; do
    if ! [[ "${VALID_ARCHS}" == *"$arch"* ]]; then
      # Strip non-valid architectures in-place
      lipo -remove "$arch" -output "$binary" "$binary" || exit 1
      stripped="$stripped $arch"
    fi
  done
  if [[ "$stripped" ]]; then
    echo "Stripped $binary of architectures:$stripped"
  fi
}


if [[ "$CONFIGURATION" == "Debug" ]]; then
  install_framework "$BUILT_PRODUCTS_DIR/CLabsImageSlider/CLabsImageSlider.framework"
  install_framework "$BUILT_PRODUCTS_DIR/CSStickyHeaderFlowLayout/CSStickyHeaderFlowLayout.framework"
  install_framework "$BUILT_PRODUCTS_DIR/DropDown/DropDown.framework"
  install_framework "$BUILT_PRODUCTS_DIR/GRDB.swift/GRDB.framework"
  install_framework "$BUILT_PRODUCTS_DIR/JNDropDownMenu/JNDropDownMenu.framework"
  install_framework "$BUILT_PRODUCTS_DIR/KJExpandableTableTree/KJExpandableTableTree.framework"
  install_framework "$BUILT_PRODUCTS_DIR/MIBadgeButton-Swift/MIBadgeButton_Swift.framework"
  install_framework "$BUILT_PRODUCTS_DIR/NVActivityIndicatorView/NVActivityIndicatorView.framework"
  install_framework "$BUILT_PRODUCTS_DIR/RGBottomSheet/RGBottomSheet.framework"
  install_framework "$BUILT_PRODUCTS_DIR/SDWebImage/SDWebImage.framework"
  install_framework "$BUILT_PRODUCTS_DIR/SkyFloatingLabelTextField/SkyFloatingLabelTextField.framework"
  install_framework "$BUILT_PRODUCTS_DIR/SnapKit/SnapKit.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Spring/Spring.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Stepperier/Stepperier.framework"
  install_framework "$BUILT_PRODUCTS_DIR/SwiftImageCarousel/SwiftImageCarousel.framework"
  install_framework "$BUILT_PRODUCTS_DIR/SwiftSoup/SwiftSoup.framework"
  install_framework "$BUILT_PRODUCTS_DIR/SwiftyJSON/SwiftyJSON.framework"
  install_framework "$BUILT_PRODUCTS_DIR/UICheckbox.Swift/UICheckbox_Swift.framework"
  install_framework "$BUILT_PRODUCTS_DIR/UIScrollView-InfiniteScroll/UIScrollView_InfiniteScroll.framework"
fi
if [[ "$CONFIGURATION" == "Release" ]]; then
  install_framework "$BUILT_PRODUCTS_DIR/CLabsImageSlider/CLabsImageSlider.framework"
  install_framework "$BUILT_PRODUCTS_DIR/CSStickyHeaderFlowLayout/CSStickyHeaderFlowLayout.framework"
  install_framework "$BUILT_PRODUCTS_DIR/DropDown/DropDown.framework"
  install_framework "$BUILT_PRODUCTS_DIR/GRDB.swift/GRDB.framework"
  install_framework "$BUILT_PRODUCTS_DIR/JNDropDownMenu/JNDropDownMenu.framework"
  install_framework "$BUILT_PRODUCTS_DIR/KJExpandableTableTree/KJExpandableTableTree.framework"
  install_framework "$BUILT_PRODUCTS_DIR/MIBadgeButton-Swift/MIBadgeButton_Swift.framework"
  install_framework "$BUILT_PRODUCTS_DIR/NVActivityIndicatorView/NVActivityIndicatorView.framework"
  install_framework "$BUILT_PRODUCTS_DIR/RGBottomSheet/RGBottomSheet.framework"
  install_framework "$BUILT_PRODUCTS_DIR/SDWebImage/SDWebImage.framework"
  install_framework "$BUILT_PRODUCTS_DIR/SkyFloatingLabelTextField/SkyFloatingLabelTextField.framework"
  install_framework "$BUILT_PRODUCTS_DIR/SnapKit/SnapKit.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Spring/Spring.framework"
  install_framework "$BUILT_PRODUCTS_DIR/Stepperier/Stepperier.framework"
  install_framework "$BUILT_PRODUCTS_DIR/SwiftImageCarousel/SwiftImageCarousel.framework"
  install_framework "$BUILT_PRODUCTS_DIR/SwiftSoup/SwiftSoup.framework"
  install_framework "$BUILT_PRODUCTS_DIR/SwiftyJSON/SwiftyJSON.framework"
  install_framework "$BUILT_PRODUCTS_DIR/UICheckbox.Swift/UICheckbox_Swift.framework"
  install_framework "$BUILT_PRODUCTS_DIR/UIScrollView-InfiniteScroll/UIScrollView_InfiniteScroll.framework"
fi
if [ "${COCOAPODS_PARALLEL_CODE_SIGN}" == "true" ]; then
  wait
fi
