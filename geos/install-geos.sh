#!/bin/bash

set -e

# Install build dependencies
sudo yum install -y automake \
    bzip2 \
    cmake3 \
    curl-devel \
    expect \
    gcc \
    gcc-c++ \
    gzip \
    libtiff-devel \
    make \
    python3-devel \
    tar

# Install GEOS
curl -O https://download.osgeo.org/geos/geos-3.7.5.tar.bz2
tar xjvf geos-3.7.5.tar.bz2
cd geos-3.7.5
./configure && make && sudo make install
cd ..
rm -rf geos-3.7.5

# Install sqlite>=3.11 (needed for proj)
curl -O https://www.sqlite.org/src/tarball/sqlite.tar.gz
tar xzf sqlite.tar.gz
cd sqlite/
export CFLAGS="-DSQLITE_ENABLE_FTS3 \
    -DSQLITE_ENABLE_FTS3_PARENTHESIS \
    -DSQLITE_ENABLE_FTS4 \
    -DSQLITE_ENABLE_FTS5 \
    -DSQLITE_ENABLE_JSON1 \
    -DSQLITE_ENABLE_LOAD_EXTENSION \
    -DSQLITE_ENABLE_RTREE \
    -DSQLITE_ENABLE_STAT4 \
    -DSQLITE_ENABLE_UPDATE_DELETE_LIMIT \
    -DSQLITE_SOUNDEX \
    -DSQLITE_TEMP_STORE=3 \
    -DSQLITE_USE_URI \
    -O2 \
    -fPIC"
export PREFIX="/usr/local"
LIBS="-lm" ./configure --disable-tcl --enable-shared --enable-tempstore=always --prefix="$PREFIX"
make
sudo make install
cd ..
rm -rf sqlite

# Install proj
curl -O https://download.osgeo.org/proj/proj-9.2.1.tar.gz
tar xzvf proj-9.2.1.tar.gz
cd proj-9.2.1
mkdir build
cd build
cmake3 -DSQLITE3_INCLUDE_DIR=/usr/local/include/ -DSQLITE3_LIBRARY=/usr/local/lib/libsqlite3.so ..
cmake3 --build .
sudo cmake3 --build . --target install
cd ../../
rm -rf proj-9.2.1

# Now install cartopy
# The path=$path portion adds /usr/local/bin to the sudo environment path so that cartopy can find geos
sudo env "PATH=$PATH" pip3 install cartopy