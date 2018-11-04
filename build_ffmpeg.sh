#!/bin/bash
set -e

# This script will compile and install a ffmpeg build with support for nvenc on ubuntu.
# See the prefix path and compile options if edits are needed to suit your needs.

#install required things from apt
installLibs(){
echo "Installing prerequisites"
sudo apt-get update
sudo apt-get -y install autoconf automake build-essential libass-dev libfreetype6-dev libgpac-dev \
  libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev \
  libxcb-xfixes0-dev pkg-config texi2html zlib1g-dev cmake mercurial nasm yasm
}

#Compile libx265
compileLibX265(){
echo "Compiling libx265"
cd ~/ffmpeg_sources
rm -rf x265
hg clone https://bitbucket.org/multicoreware/x265
cd ~/ffmpeg_sources/x265/build/linux
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DHIGH_BIT_DEPTH:bool=ON -DENABLE_CLI:BOOL=OFF ../../source
sed -i 's/-lgcc_s/-lgcc_eh/g' x265.pc
make -j$(nproc)
make -j$(nproc) install
make -j$(nproc) clean
}

#Compile libx264
compileLibX264(){
echo "Compiling libx264"
cd ~/ffmpeg_sources
rm -rf last_x264.tar.bz2 x264-snapshot*
wget http://download.videolan.org/pub/x264/snapshots/last_x264.tar.bz2
tar xjvf last_x264.tar.bz2
cd x264-snapshot*
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-shared --enable-pic
PATH="$HOME/bin:$PATH" make -j$(nproc)
make -j$(nproc) install
make -j$(nproc) distclean
}

#Compile libfdk-acc
compileLibfdkcc(){
echo "Compiling libfdk-cc"
sudo apt-get install unzip
cd ~/ffmpeg_sources
rm -rf fdk-aac.zip mstorsjo-fdk-aac*
wget -O fdk-aac.zip https://github.com/mstorsjo/fdk-aac/zipball/master
unzip fdk-aac.zip
cd mstorsjo-fdk-aac*
autoreconf -fiv
./configure --prefix="$HOME/ffmpeg_build"
make -j$(nproc)
make -j$(nproc) install
make -j$(nproc) distclean
}

#Compile libmp3lame
compileLibMP3Lame(){
echo "Compiling libmp3lame"
sudo apt-get install nasm
cd ~/ffmpeg_sources
rm -rf lame*
wget http://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
tar xzvf lame-3.100.tar.gz
cd lame-3.100
./configure --prefix="$HOME/ffmpeg_build" --enable-nasm
make -j$(nproc)
make -j$(nproc) install
make -j$(nproc) distclean
}

#Compile libopus
compileLibOpus(){
echo "Compiling libopus"
cd ~/ffmpeg_sources
rm -rf opus*
wget https://ftp.osuosl.org/pub/xiph/releases/opus/opus-1.3.tar.gz
tar xzvf opus-1.3.tar.gz
cd opus-1.3
./configure --prefix="$HOME/ffmpeg_build"
make -j$(nproc)
make -j$(nproc) install
make -j$(nproc) distclean
}

#Compile libvpx
compileLibPvx(){
echo "Compiling libvpx"
cd ~/ffmpeg_sources
rm -rf libvpx*
wget https://github.com/webmproject/libvpx/archive/v1.7.0.tar.gz
tar xvf v1.7.0.tar.gz
cd libvpx-1.7.0
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --enable-pic
PATH="$HOME/bin:$PATH" make -j$(nproc)
make -j$(nproc) install
make -j$(nproc) clean
}

compileNvCodecHeaders() {
cd ~/ffmpeg_sources
rm -rf nv-codec-headers
git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd nv-codec-headers
make install PREFIX="$HOME/ffmpeg_build"
}

#Compile ffmpeg
compileFfmpeg(){
echo "Compiling ffmpeg"
cd ~/ffmpeg_sources
rm -rf ffmpeg*
wget https://www.ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
tar xjvf ffmpeg-snapshot.tar.bz2
cd ffmpeg

PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --extra-cflags="-I$HOME/ffmpeg_build/include -I/usr/local/cuda/include/" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib -L/usr/local/cuda/lib64/" \
  --extra-libs="-lpthread -lm" \
  --bindir="$HOME/bin" \
  --enable-gpl \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libass \
  --enable-nonfree \
  --nvccflags="-gencode arch=compute_61,code=sm_61 -O2" \
  --enable-nvenc \
  --enable-libnpp \
  --enable-cuda \
  --disable-cuda-sdk
  # --enable-vaapi \
PATH="$HOME/bin:$PATH" make -j$(nproc)
make -j$(nproc) install
}

#The process
cd ~
mkdir -p ffmpeg_sources
installLibs
compileLibX265
compileLibX264
compileLibfdkcc
compileLibMP3Lame
compileLibOpus
compileLibPvx
compileNvCodecHeaders
compileFfmpeg
echo "Complete!"
