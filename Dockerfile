FROM --platform=linux/amd64 ruby:3.1.2

WORKDIR /app

RUN --mount=target=/var/lib/apt/lists,type=cache \
    --mount=target=/var/cache/apt,type=cache \
    curl -fsSL https://deb.nodesource.com/setup_14.x | bash -; \
    apt-get install -y --no-install-recommends \
                       $(apt-cache search -q "libjemalloc[0-9]$" | cut -d' ' -f1); \
    apt-get install -y --no-install-recommends \
                       build-essential \
                       ghostscript \
                       git \
                       imagemagick \
                       less \
                       libpq-dev \
                       locate \
                       nodejs \
                       vim

# Install vips with HEIC support
RUN --mount=target=/var/lib/apt/lists,type=cache \
    --mount=target=/var/cache/apt,type=cache \
    --mount=target=/opt,type=cache \
    apt install -y --no-install-recommends \
                   build-essential \
                   pkg-config \
                   cmake \
                   meson \
                   libglib2.0-dev \
                   libexpat1-dev \
                   libheif-dev \
                   libimagequant-dev; \
    cd /opt && \
    git clone https://github.com/randy408/libspng && \
    cd libspng && \
    git checkout v0.7.2 && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(( $(nproc) + 1 )) && \
    make install; \
    cd /opt && \
    git clone https://github.com/dloebl/cgif && \
    cd cgif && \
    git checkout V0.3.0 && \
    sed -i "s/\['inc\/'\]/include_directories('inc\/')/g" meson.build && \
    sed -i "s/\['..\/inc\/'\]/include_directories('..\/inc\/')/g" tests/meson.build && \
    meson setup --prefix=/usr build && \
    meson install -C build; \
    cd /opt && \
    wget -qO - https://github.com/libvips/libvips/releases/download/v8.12.2/vips-8.12.2.tar.gz | tar xzvf - -C . && \
    cd vips-8.12.2 && \
    ./configure && \
    make -j$(( $(nproc) + 1 )) && \
    make install && \
    ldconfig -v


ENV BUNDLER_VERSION 2.3.12

RUN gem install bundler --version 2.3.12 --force; \
    npm install -g yarn; \
    sed -i 's/name="disk" value="1GiB"/name="disk" value="8GiB"/' /etc/ImageMagick-6/policy.xml; \
    sed -i 's/name="width" value="16KP"/name="width" value="50KP"/' /etc/ImageMagick-6/policy.xml; \
    sed -i 's/name="height" value="16KP"/name="height" value="50KP"/' /etc/ImageMagick-6/policy.xml

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN --mount=target=/root/bundlecache,type=cache \
    bundle config set path /root/bundlecache; \
    bundle config set clean true; \
    export MAKEFLAGS="-j$(nproc)"; bundle install --jobs=$(nproc); \
    bundle config unset path; \
    bundle config unset clean; \
    export RUBY_MAJOR_VERSION=$(ruby -e "print RbConfig::CONFIG['ruby_version']"); \
    cp -ar /root/bundlecache/ruby/$RUBY_MAJOR_VERSION /root/bundle; \
    cp Gemfile.lock /root/Gemfile.lock
RUN cp -ar /root/bundle /usr/local/; rm -rf /root/bundle

COPY . /app

CMD ["ruby", "/app/main.rb"]
