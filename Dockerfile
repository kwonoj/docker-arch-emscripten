FROM ojkwon/arch-nvm-node:84e4ad7-node12.10.0-npm6.10.2

# Build time args
ARG BUILD_TARGET=""
ARG PROTOBUF_VERSION=""
ARG EMSCRIPTEN_VERSION=""

# Upgrade system
RUN pacman --noconfirm -Syyu

# Install dependencies
RUN pacman --noconfirm -S \
  unzip \
  python \
  python-setuptools \
  python2-setuptools \
  jre8-openjdk

# Change subsequent execution shell to bash
SHELL ["/bin/bash", "-l", "-c"]

USER builder

# Install emcc
# we want to use system installed node instead, manually uninstall from sdk
RUN cd $TMPDIR && \
  git clone https://github.com/emscripten-core/emsdk.git && \
  cd emsdk && \
  ./emsdk install $EMSCRIPTEN_VERSION && \
  ./emsdk uninstall node-12.9.1-64bit && \
  ./emsdk activate $EMSCRIPTEN_VERSION && \
  printf '%s\n%s\n' "source $(pwd)/emsdk_env.sh" "$(cat ~/.bashrc)" > ~/.bashrc && \
  sudo cp ~/.bashrc /root

RUN echo $PATH
# Initialize emcc
RUN node -v && emcc -v

# Install specific version of protobuf corresponding to protobuf-wasm.
RUN if [[ "${BUILD_TARGET}" == "protobuf" ]]; then \
    cd $TMPDIR && \
    curl https://github.com/protocolbuffers/protobuf/releases/download/v$PROTOBUF_VERSION/protobuf-all-$PROTOBUF_VERSION.tar.gz -L > protobuf-all-$PROTOBUF_VERSION.tar.gz && \
    tar xvzf ./protobuf-all-$PROTOBUF_VERSION.tar.gz && cd protobuf-$PROTOBUF_VERSION && \
    ./configure && make && make check && sudo make install && sudo ldconfig; \
  fi

# Build emscripten-wasm as well to generate lib build will be placed build under `/home/builder/temp/.libs`
RUN if [[ "${BUILD_TARGET}" == "protobuf" ]]; then \
      cd $TMPDIR && git clone https://github.com/google/protobuf && cd protobuf && git checkout v$PROTOBUF_VERSION &&\
      cd $TMPDIR && git clone https://github.com/kwonoj/protobuf-wasm && \
      cd $TMPDIR/protobuf-wasm && git checkout v$PROTOBUF_VERSION && cp *.patch $TMPDIR/protobuf && \
      cd $TMPDIR/protobuf && git apply *.patch && \
      git status && \
      sh autogen.sh && emconfigure ./configure CXXFLAGS="-O2" && emmake make && \
      cp -r ./src/.libs $TMPDIR/ && \
      ls -al $TMPDIR/.libs; \
    fi

# trigger dummy build to cache corresponding binaryen port for wasm
RUN mkdir -p $TMPDIR/hello && \
  echo "int main() { return 0; }" > $TMPDIR/hello/hello.c && \
  emcc $TMPDIR/hello/hello.c -o $TMPDIR/hello/hello.js && \
  rm -rf $TMPDIR/hello

USER root

RUN node -v && emcc -v

CMD emcc --version
