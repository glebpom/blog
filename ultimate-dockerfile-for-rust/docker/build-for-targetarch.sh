#!/bin/bash

if [[ "$1" == "arm64" ]]
then
  TARGET=aarch64-unknown-linux-gnu
elif [[ "$1" == "amd64" ]]
then
  TARGET=x86_64-unknown-linux-gnu
else
  exit 1
fi

rustup target add $TARGET
cargo build --release --target=$TARGET
cp target/$TARGET/release/ultimate-dockerfile-for-rust /usr/local/bin/ultimage-dockerfile-for-rust
