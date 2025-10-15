# tested dependencies: macfuse@5.0.7 autoconf@2.72 automake@1.18.1 libtool@2.5.4 e2fsprogs@1.47.3 m4@1.3.20
echo "[script] installing dependencies via brew"
brew install --cask macfuse
brew install autoconf automake libtool e2fsprogs m4 

export PATH="$(brew --prefix m4)/bin:$PATH"

export PATH="$(brew --prefix e2fsprogs)/bin:$PATH"
export PATH="$(brew --prefix e2fsprogs)/sbin:$PATH"

# git clone -b master https://github.com/alperakcan/fuse-ext2 && cd fuse-ext2 && git checkout ae35afb
echo "[script] building fuse-ext2"
./autogen.sh

# see ./configure for "$@"
CFLAGS="-idirafter$(brew --prefix e2fsprogs)/include -idirafter$(brew --prefix libtool)/include -idirafter/usr/local/include/fuse/" LDFLAGS="-L$(brew --prefix e2fsprogs)/lib -L$(brew --prefix libtool)/lib -L/usr/local/lib" ./configure "$@"

make

echo "[script] installing fuse-ext2"
sudo make install

echo "[script] correcting e2fsprogs symlinks, ./fuse-ext2/Makefile.am#L155-156"
sudo ln -s -f "$(brew --prefix e2fsprogs)/sbin/e2label" "/usr/local/sbin/e2label"
sudo ln -s -f "$(brew --prefix e2fsprogs)/sbin/mke2fs" "/usr/local/sbin/mke2fs"