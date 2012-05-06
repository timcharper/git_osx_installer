finddir() {
  for d in $*; do
    if [ -d "$d" ]; then
      echo $d
      return 0
    fi
  done
  echo "Unable to find any of $*" 1>&2
  return 1
}

PACKAGE_MAKER_APP=$(finddir {/Developer,}/Applications/Utilities/PackageMaker.app)
SDK_PATH=$(finddir {/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform,}/Developer/SDKs/MacOSX10.6.sdk)
