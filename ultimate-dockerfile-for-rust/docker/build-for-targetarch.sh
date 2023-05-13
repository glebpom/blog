#!/bin/bash

set -ex

if [[ "$1" == "arm64" ]]
then
  TARGET=aarch64-unknown-linux-gnu
  export TARGET_CC=/usr/bin/aarch64-linux-gnu-gcc
  export TARGET_CXX=/usr/bin/aarch64-linux-gnu-g++
elif [[ "$1" == "amd64" ]]
then
  TARGET=x86_64-unknown-linux-gnu
  export TARGET_CC=/usr/bin/x86_64-linux-gnu-gcc
  export TARGET_CC=/usr/bin/x86_64-linux-gnu-g++
  export CC_x86_64_unknown_linux_gnu=/usr/bin/x86_64-linux-gnu-gcc
  export CXX_x86_64_unknown_linux_gnu=/usr/bin/x86_64-linux-gnu-g++
else
  exit 1
fi

rustup target add $TARGET
cargo build --release --target=$TARGET
cp target/$TARGET/release/ultimate-dockerfile-for-rust /usr/local/bin/ultimage-dockerfile-for-rust
