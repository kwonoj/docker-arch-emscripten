FROM ojkwon/arch-nvm-node:4032238-node7.9-npm4
MAINTAINER OJ Kwon <kwon.ohjoong@gmail.com>

# Build time args
ARG BUILD_TARGET=""

# Install dependencies
RUN pacman --noconfirm -Syu \
  emscripten \
  unzip \
  python \
  python-setuptools \
  python2-setuptools \
  jre8-openjdk

# Change subsequent execution shell to bash
SHELL ["/bin/bash", "-l", "-c"]

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
    makepkg && sudo pacman --noconfirm -U *.pkg.tar.xz && \
    cd $TMPDIR && git clone https://github.com/kwonoj/protobuf-emscripten && \
    cd $TMPDIR/protobuf-emscripten/3.1.0 && \
    sh autogen.sh && emconfigure ./configure && emmake make && \
    cp -r ./src/.libs $TMPDIR/ && \
    ls $TMPDIR/.libs; \
  fi

USER root

CMD emcc --version