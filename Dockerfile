FROM ojkwon/arch-nvm-node:801bb47-node-8.9.1-npm5.6
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

# START gcc--------------------------------
# Install gcc-6.3.1-2-x86_64.pkg.tar.xz
# until binaryen clang failure (https://github.com/WebAssembly/binaryen/issues/1300) resolved with gcc 7.x

RUN cd $TMPDIR && \
  curl https://archive.archlinux.org/packages/g/gcc/gcc-6.3.1-2-x86_64.pkg.tar.xz > ./gcc-6.3.1-2-x86_64.pkg.tar.xz && \
  curl https://archive.archlinux.org/packages/g/gcc/gcc-6.3.1-2-x86_64.pkg.tar.xz.sig > ./gcc-6.3.1-2-x86_64.pkg.tar.xz.sig && \
  curl https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-6.3.1-2-x86_64.pkg.tar.xz > ./gcc-libs-6.3.1-2-x86_64.pkg.tar.xz && \
  curl https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-6.3.1-2-x86_64.pkg.tar.xz.sig > ./gcc-libs-6.3.1-2-x86_64.pkg.tar.xz.sig && \
  sudo pacman --noconfirm -U gcc-libs-6.3.1-2-x86_64.pkg.tar.xz gcc-6.3.1-2-x86_64.pkg.tar.xz

# END gcc--------------------------------

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

USER root

CMD emcc --version
