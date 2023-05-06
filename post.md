# Intro

# Preparing simple rust app

```bash
cargo init ultimate-dockerfile-for-rust
cd ultimate-dockerfile-for-rust
cargo check
```

# Simple Dockerfile

Let's start by creating a very simple `Dockerfile`, which just compiles our code in release mode

```Dockerfile
# syntax=docker/dockerfile:1.5

ARG RUST_VERSION=1.69

FROM rust:${RUST_VERSION}-bullseye

ADD . /code
WORKDIR /code

RUN cargo build --release

CMD ["/code/target/release/ultimate-dockerfile-for-rust"]
```

This is a simple Dockerfile which you may use to build and run your application:
```bash
docker build -t ultimate-dockerfile-for-rust .
docker run -it ultimate-dockerfile-for-rust 
```

However, there is a significant downside of this approach - image contains the sources code and 
build artifacts, which increase the size and keeps the data which is not needed to run the app.

## Multistage dockerfile

Let's mintroduce two stages - build and main:

```Dockerfile
# syntax=docker/dockerfile:1.5

ARG RUST_VERSION=1.69

FROM rust:${RUST_VERSION}-bullseye as build

ADD . /code
WORKDIR /code

RUN cargo build --release

FROM debian:bullseye as main

COPY --from=build /code/target/release/ultimate-dockerfile-for-rust 
/usr/local/bin/ultimate-dockerfile-for-rust

RUN ["/usr/local/bin/ultimate-dockerfile-for-rust"]
```

Such image will not contain sources code and build artifacts.

## Utilizing docker caching

Docker caches each stage of the build process. It's worth to utilize this mechanism to cache at 
least fetching of dependencies. 

Let's modify Dockerfile in the following way:
```
# syntax=docker/dockerfile:1.5

ARG RUST_VERSION=1.69

FROM rust:${RUST_VERSION}-bullseye as build

RUN mkdir -p code/src
WORKDIR /code

RUN echo "fn main() {}" > src/main.rs
COPY Cargo.toml .
COPY Cargo.lock .

RUN cargo fetch

ADD . /code
WORKDIR /code

RUN cargo build --release

FROM debian:bullseye as main

COPY --from=build /code/target/release/ultimate-dockerfile-for-rust 
/usr/local/bin/ultimate-dockerfile-for-rust

RUN ["/usr/local/bin/ultimate-dockerfile-for-rust"]
```

## Multi-arch image

With growing adoption of ARM CPUs like in Apple M1 and Amazon Graviton, it's very useful to prepare 
multi-arch docker images. Let's introduce cross-compilation to our image.

Let's start by creating `docker` directory:
```shell
mkdir docker
```

and create `build-for-targetarch.sh` file with the following content:

```bash
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
```

Don't forget to enable execution build

```shell
chmod +x build-for-targetarch.sh
```

Change the `Dockerfile` content to following:

```
# syntax=docker/dockerfile:1.5

ARG RUST_VERSION=1.69

FROM --platform=$BUILDPLATFORM rust:${RUST_VERSION}-bullseye as build-common

RUN mkdir -p code/src
WORKDIR /code

RUN echo "fn main() {}" > src/main.rs
COPY Cargo.toml .
COPY Cargo.lock .

RUN cargo fetch

ADD . /code
WORKDIR /code

FROM --platform=$BUILDPLATFORM build-common as build-arch

ARG TARGETARCH

ADD /docker /docker

RUN /docker/build-for-targetarch.sh $TARGETARCH

FROM debian:bullseye as main

ARG TARGETARCH

COPY --from=build-arch /usr/local/bin/ultimage-dockerfile-for-rust 
/usr/local/bin/ultimage-dockerfile-for-rust

CMD ["/usr/local/bin/ultimage-dockerfile-for-rust"]
```

This will support build for both architectures and utilize cross-compilation for that. 
Cross-compilation is preferred, because you typically use one architecture to compile for both, and 
it's more efficient to avoid virtualization to execute heavy operations, like rust project 
compilation.

Try building for multiple platforms:

```shell
docker buildx build --platform=linux/aarch64,linux/amd64 -t ultimage-dockerfile-for-rust .
```

## Native Dependencies

Let's try adding native dependencies to our `Cargo.toml`


- Cross-Compilation with LLVM
- Support CPU optimizations
    - skylake512
    - graviton3
- sccache

