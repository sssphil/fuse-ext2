set -e # exit on error

# building from source, as brew e2fsprogs/blkid is broken, which we need for UUID/LABEL support
E2FS_BUILD="source"  # options: "brew", "source"

# tested on macfuse@5.0.7 and fuse-t@1.0.49
# brew install --cask macfuse
# brew tap macos-fuse-t/homebrew-cask && brew install fuse-t fuse-t-sshfs

# tested dependencies: autoconf@2.72 automake@1.18.1 libtool@2.5.4 e2fsprogs@1.47.3 m4@1.3.20
echo "[script] installing dependencies via brew"
brew install autoconf automake libtool m4

# Get prefixes
M4_PREFIX="$(brew --prefix m4)"
LIBTOOL_PREFIX="$(brew --prefix libtool)"
E2FS_PREFIX=

export PATH="${M4_PREFIX}/bin:$PATH"

if [ "$E2FS_BUILD" = "source" ]; then
    echo "[script] building e2fsprogs from source"

    if [ ! -d "e2fsprogs" ]; then
        git clone https://git.kernel.org/pub/scm/fs/ext2/e2fsprogs.git
    else
        echo "[script] e2fsprogs directory already exists, skipping clone"
    fi

    cd e2fsprogs
    # libblkid required for fuse-ext2 UUID/LABEL support
    # fuse2fs causing build errors on macOS
    echo "[script] e2fsprogs: configure"
    ./configure --disable-nls --enable-libblkid --disable-fuse2fs
    echo "[script] e2fsprogs: make"
    make
    echo "[script] e2fsprogs: sudo make install"
    sudo make install
    cd ..

    echo "[script] remove uuid.h installed by e2fsprogs to avoid uuid_string_t error for fuse-ext2 build"
    sudo rm -f /usr/local/include/uuid/uuid.h

    E2FS_PREFIX="/usr/local"
else
    echo "[script] using Homebrew e2fsprogs"
    brew install e2fsprogs

    E2FS_PREFIX="$(brew --prefix e2fsprogs)"

    export PATH="${E2FS_PREFIX}/bin:$PATH"
    export PATH="${E2FS_PREFIX}/sbin:$PATH"

    echo "[script] correcting e2fsprogs symlinks, ./fuse-ext2/Makefile.am#L155-156"
    sudo ln -s -f "${E2FS_PREFIX}/sbin/e2label" "/usr/local/sbin/e2label"
    sudo ln -s -f "${E2FS_PREFIX}/sbin/mke2fs" "/usr/local/sbin/mke2fs"
fi

# git clone -b master https://github.com/alperakcan/fuse-ext2 && cd fuse-ext2 && git checkout ae35afb
echo "[script] building fuse-ext2"
./autogen.sh

# see ./configure for "$@"
CFLAGS="-idirafter${E2FS_PREFIX}/include -idirafter${LIBTOOL_PREFIX}/include -idirafter/usr/local/include/fuse/"
LDFLAGS="-Wl,-rpath,/usr/local/lib -L${E2FS_PREFIX}/lib -L${LIBTOOL_PREFIX}/lib -L/usr/local/lib"
./configure "$@"
echo "[script] configuring with: \
      ${CFLAGS} \
      ${LDFLAGS} \
      ./configure $@"
CFLAGS=${CFLAGS} LDFLAGS=${LDFLAGS} ./configure "$@"

make

echo "[script] installing fuse-ext2"
sudo make install
