FROM ojkwon/arch-nvm-node:301cc67-node8.9.1-npm5.6
MAINTAINER OJ Kwon <kwon.ohjoong@gmail.com>

# Build time args
ARG BUILD_TARGET=""
ARG PROTOBUF_VERSION=""

# Upgrade system
RUN pacman --noconfirm -Syyu

# Install dependencies
RUN pacman --noconfirm -S \
  unzip \
  python \
  python-setuptools \
  python2-setuptools \
  jre8-openjdk \
  emscripten

# Change subsequent execution shell to bash
SHELL ["/bin/bash", "-l", "-c"]

USER builder

# Initialize emcc
RUN emcc && emcc --version

# Install specific version of protobuf corresponding to protobuf-wasm.
RUN cd $TMPDIR && \
  curl https://archive.archlinux.org/packages/p/protobuf/protobuf-$PROTOBUF_VERSION-1-x86_64.pkg.tar.xz > ./protobuf-$PROTOBUF_VERSION-1-x86_64.pkg.tar.xz && \
  curl https://archive.archlinux.org/packages/p/protobuf/protobuf-$PROTOBUF_VERSION-1-x86_64.pkg.tar.xz.sig > ./protobuf-$PROTOBUF_VERSION-1-x86_64.pkg.tar.xz.sig && \
  sudo pacman --noconfirm -U protobuf-$PROTOBUF_VERSION-1-x86_64.pkg.tar.xz

# Build emscripten-wasm as well to generate lib build will be placed build under `/home/builder/temp/.libs`
RUN if [[ "${BUILD_TARGET}" == "protobuf" ]]; then \
      cd $TMPDIR && git clone https://github.com/google/protobuf && cd protobuf && git checkout v$PROTOBUF_VERSION &&\
      cd $TMPDIR && git clone https://github.com/kwonoj/protobuf-wasm && \
      cd $TMPDIR/protobuf-wasm && git checkout v$PROTOBUF_VERSION && cp *.patch $TMPDIR/protobuf && \
      cd $TMPDIR/protobuf && git apply *.patch && \
      git status && \
      sh autogen.sh && emconfigure ./configure && emmake make && \
      cp -r ./src/.libs $TMPDIR/ && \
      ls $TMPDIR/.libs; \
    fi

# trigger dummy build to cache corresponding binaryen port for wasm
RUN mkdir -p $TMPDIR/hello && \
  echo "int main() { return 0; }" > $TMPDIR/hello/hello.c && \
  emcc $TMPDIR/hello/hello.c -s WASM=1 -s SINGLE_FILE=1 -o $TMPDIR/hello/hello.js && \
  rm -rf $TMPDIR/hello

USER root

CMD emcc --version
