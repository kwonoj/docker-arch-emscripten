FROM ojkwon/arch-nvm-node:7b0d30e-node8.4-npm5.4.1
MAINTAINER OJ Kwon <kwon.ohjoong@gmail.com>

# Build time args
ARG BUILD_TARGET=""

# Upgrade system
RUN pacman --noconfirm -Syyu

# Install dependencies
RUN pacman --noconfirm -S \
  unzip \
  python \
  python-setuptools \
  python2-setuptools \
  jre8-openjdk
# emscripten // disabled while installing pinned down version

# Change subsequent execution shell to bash
SHELL ["/bin/bash", "-l", "-c"]

#START emscripten--------------------------------
# Install emscripten-1.37.18-1-x86_64.pkg.tar.xz
# until binaryen clang failure (https://github.com/WebAssembly/binaryen/issues/1164) resolved

RUN cd $TMPDIR && \
  curl https://archive.archlinux.org/packages/e/emscripten/emscripten-1.37.18-1-x86_64.pkg.tar.xz > ./emscripten-1.37.18-1-x86_64.pkg.tar.xz && \
  curl https://archive.archlinux.org/packages/e/emscripten/emscripten-1.37.18-1-x86_64.pkg.tar.xz.sig > ./emscripten-1.37.18-1-x86_64.pkg.tar.xz.sig && \
  sudo pacman --noconfirm -U emscripten-1.37.18-1-x86_64.pkg.tar.xz

#END emscripten--------------------------------

#START preamble patch--------------------------------
# Patch preamble.js to support Electron's renderer process with node.js environment
# Refer https://github.com/kripken/emscripten/pull/5577 for detail.
# TODO: remove based on upstream PR status
COPY ./preamble.patch $TMPDIR/
RUN patch /usr/lib/emscripten/src/preamble.js $TMPDIR/preamble.patch
#END preamble patch--------------------------------

# Initialize emcc
RUN emcc

USER builder

# Install 3.1 version of protobuf via makepkg instead of latest, to align with
# protobuf-emscripten. Also build emscripten-protobuf as well, place build under
# /home/builder/temp/.libs
RUN if [[ "${BUILD_TARGET}" == "protobuf" ]]; then \
    echo "installing protobuf 3.1 dependency" && \
    mkdir $TMPDIR/proto31 && cd $TMPDIR/proto31 && \
    curl "https://git.archlinux.org/svntogit/packages.git/plain/trunk/PKGBUILD?h=packages/protobuf&id=fa8b9da391b26b6ace1941e9871a6416db74d67b" > ./PKGBUILD && \
    makepkg --skipchecksums && sudo pacman --noconfirm -U *.pkg.tar.xz && \
    cd $TMPDIR && git clone https://github.com/kwonoj/protobuf-emscripten && \
    cd $TMPDIR/protobuf-emscripten/3.1.0 && \
    sh autogen.sh && emconfigure ./configure && emmake make && \
    cp -r ./src/.libs $TMPDIR/ && \
    ls $TMPDIR/.libs; \
  fi

USER root

CMD emcc --version