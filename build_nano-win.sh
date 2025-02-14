#!/bin/bash -e

_host="${1:-x86_64}-w64-mingw32"

_pwd="$(cygpath -m $(pwd) || readlink -f $(pwd))"
_nproc="$(nproc)"
_prefix="${_pwd}/pkg_${_host}"

./autogen.sh

export PKG_CONFIG="true"  # Force it to succeed.
export CPPFLAGS="-D__USE_MINGW_ANSI_STDIO -I\"${_prefix}/include\""
export CFLAGS="-O2 -pthread"
export LDFLAGS="-O2 -L\"${_prefix}/lib/\" -static -Wl,-s"

wget -c "https://invisible-mirror.net/archives/ncurses/ncurses-6.1.tar.gz"
tar -xzvf ncurses-6.1.tar.gz
patch -p1 < ncurses-6.1.patch

mkdir -p "${_pwd}/build_${_host}"
pushd "${_pwd}/build_${_host}"

mkdir -p "ncurses"
pushd "ncurses"
../../ncurses-6.1/configure --host="${_host}" --prefix="${_prefix}"  \
  --without-ada --without-cxx-binding --disable-db-install --without-manpages  \
  --without-pthread --without-debug --enable-widec --disable-database  \
  --disable-rpath --enable-termcap --disable-home-terminfo --enable-sp-funcs  \
  --enable-term-driver --enable-static --disable-shared
make -j"${_nproc}"
make install
popd

export NCURSESW_CFLAGS="-I\"${_prefix}/include/ncursesw\""
export NCURSESW_LIBS="-lncursesw"

mkdir -p "nano"
pushd "nano"
touch roll-a-release.sh  # Lie to configure.ac to make use of `git describe`.
../../configure --host="${_host}" --prefix="${_prefix}" --enable-nanorc  \
  --enable-color --enable-utf8 --disable-nls --disable-speller  \
  --disable-threads --disable-rpath LIBS="-lshlwapi"
make -j"${_nproc}"
make install-strip
popd
