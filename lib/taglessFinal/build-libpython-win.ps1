# Download the archive
(New-Object System.Net.WebClient).DownloadFile('https://github.com/msys2/msys2-installer/releases/download/nightly-x86_64/msys2-base-x86_64-latest.sfx.exe', 'msys2.exe')
.\msys2.exe -y -oC:\  # Extract to C:\msys64
#Remove-Item msys2.exe  # Delete the archive again

# Run for the first time
C:\msys64\usr\bin\bash -lc ' '
# Update MSYS2
C:\msys64\usr\bin\bash -lc 'pacman --noconfirm -Syuu'  # Core update (in case any core packages are outdated)
C:\msys64\usr\bin\bash -lc 'pacman --noconfirm -Syuu'  # Normal update
C:\msys64\usr\bin\bash -lc 'pacman -S --noconfirm make binutils \
autoconf autoconf-archive automake-wrapper tar gzip mingw-w64-x86_64-toolchain\
 mingw-w64-x86_64-expat mingw-w64-x86_64-bzip2 mingw-w64-x86_64-libffi mingw-w64-x86_64-mpdecimal\
  mingw-w64-x86_64-ncurses mingw-w64-x86_64-openssl mingw-w64-x86_64-sqlite3 mingw-w64-x86_64-tcl\
   mingw-w64-x86_64-tk mingw-w64-x86_64-zlib mingw-w64-x86_64-xz mingw-w64-x86_64-tzdata'


$env:CHERE_INVOKING = 'yes'  # Preserve the current working directory
$env:MSYSTEM = 'MINGW64'  # Start a 64 bit Mingw environment
C:\msys64\usr\bin\bash -lc 'which gcc' #ensure gcc is found

C:\msys64\usr\bin\bash -lc 'cd cpython-mingw && ./configure --prefix=/mingw64 --host=x86_64-w64-mingw32 \
--build=x86_64-w64-mingw32 --enable-shared --with-system-expat --with-system-ffi --with-system-libmpdec \
 --without-ensurepip --enable-loadable-sqlite-extensions --with-tzpath=/mingw64/share/zoneinfo --enable-optimizations \
  && make -j8 libpython3.11.a && cp libpython3.11.a ../libpython.a && cp pyconfig.h ../pyconfig.h'