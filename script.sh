set -e # exit on error

# building from source, as brew e2fsprogs/blkid is broken, which we need for UUID/LABEL support
E2FS_BUILD="source"  # options: "brew", "source"

# tested dependencies: macfuse@5.0.7 autoconf@2.72 automake@1.18.1 libtool@2.5.4 e2fsprogs@1.47.3 m4@1.3.20
echo "[script] installing dependencies via brew"
brew install --cask macfuse
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
    ./configure --disable-nls --enable-libblkid --disable-fuse2fs
    make
    sudo make install
    cd ..

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
CFLAGS="-idirafter${E2FS_PREFIX}/include -idirafter${LIBTOOL_PREFIX}/include -idirafter/usr/local/include/fuse/" \
LDFLAGS="-L${E2FS_PREFIX}/lib -L${LIBTOOL_PREFIX}/lib -L/usr/local/lib" \
./configure "$@"

make

echo "[script] installing fuse-ext2"
sudo make install
