#!/bin/bash
FROM_DIR="/opt/local/lib/"
TO_DIR="/usr/local/git/lib/"

mkdir -p $TO_DIR
pushd $FROM_DIR
cp -R libcrypto.0.9.8.dylib \
			libz.1.2.3.dylib \
			libssl.0.9.8.dylib \
			libexpat.1.5.2.dylib $TO_DIR

cd $TO_DIR
strip *.dylib

ln -s libcrypto.0.9.8.dylib libcrypto.dylib
ln -s libz.1.2.3.dylib libz.1.dylib
ln -s libssl.0.9.8.dylib libssl.dylib
ln -s libexpat.1.5.2.dylib libexpat.dylib

popd
