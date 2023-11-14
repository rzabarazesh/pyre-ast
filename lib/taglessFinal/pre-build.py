#!/usr/bin/env python3

import platform
import pathlib
import subprocess
import os
import urllib.request
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Get the directory of this script
script_dir = pathlib.Path(__file__).parent.absolute()

# Check the system
is_windows = platform.system() == 'Windows'

# Choose the vendor dir based on the system
vendor_dir = 'vendor-mingw' if is_windows else 'vendor-unix'

vendor_dir_path = script_dir / vendor_dir

# Define the Dune file content
dune_content = f'''\
(subdir
 {vendor_dir}/Modules
 (dirs :standard _*))

(subdir
 {vendor_dir}/Lib
 (dirs :standard _*))

(rule
 (deps
  (source_tree {vendor_dir}))
 (targets libpython.a pyconfig.h)
 (action
  (no-infer
   (progn
    (chdir
     {vendor_dir}
     (copy {vendor_dir}/libpython3.11.a libpython.a)
     (copy {vendor_dir}/pyconfig.h pyconfig.h)))))

(library
 (name taglessFinal)
 (package pyre-ast)
 (libraries base)
 (no_dynlink)
 (foreign_stubs
  (language c)
  (names binding)
  (flags :standard -I{vendor_dir}/Include -I.))
 (foreign_archives python))
'''

# Write the Dune file
dune_path = script_dir / 'dune'
dune_path.write_text(dune_content)

if is_windows:
    # Download Msys2
    url = 'https://github.com/msys2/msys2-installer/releases/download/nightly-x86_64/msys2-base-x86_64-latest.sfx.exe'
    msys2_exe_path = script_dir / 'msys2.exe'
    try:
        urllib.request.urlretrieve(url, str(msys2_exe_path))
        logging.info('Downloaded Msys2')
    except Exception as e:
        logging.error('Could not download Msys2: %s', e)
        raise

    # Extract to C:\msys64
    try:
        subprocess.run([str(msys2_exe_path), '-y', '-oC:\\'], check=True)
        logging.info('Extracted Msys2')
    except Exception as e:
        logging.error('Could not extract Msys2: %s', e)
        raise

    # Delete msys2.exe
    try:
        os.remove(msys2_exe_path)
        logging.info('Deleted msys2.exe')
    except Exception as e:
        logging.error('Could not delete msys2.exe: %s', e)
        # Don't raise an error, as this is not a critical failure

    # Run for the first time
    subprocess.run(['C:\\msys64\\usr\\bin\\bash', '-lc', ' '], check=True)

    # Update MSYS2
    for _ in range(2):  # Core update and normal update
        subprocess.run(['C:\\msys64\\usr\\bin\\bash', '-lc', 'pacman --noconfirm -Syuu'], check=True)

    # Install packages
    packages = ' '.join([
        'make', 'binutils', 'autoconf', 'autoconf-archive', 'automake-wrapper', 'tar', 'gzip', 
        'mingw-w64-x86_64-toolchain', 'mingw-w64-x86_64-expat', 'mingw-w64-x86_64-bzip2', 
        'mingw-w64-x86_64-libffi', 'mingw-w64-x86_64-mpdecimal', 'mingw-w64-x86_64-ncurses', 
        'mingw-w64-x86_64-openssl', 'mingw-w64-x86_64-sqlite3', 'mingw-w64-x86_64-tcl',
        'mingw-w64-x86_64-tk', 'mingw-w64-x86_64-zlib', 'mingw-w64-x86_64-xz', 
        'mingw-w64-x86_64-tzdata'
    ])
    subprocess.run(['C:\\msys64\\usr\\bin\\bash', '-lc', 'pacman -S --noconfirm ' + packages], check=True)

    # Set environment variables
    os.environ['CHERE_INVOKING'] = 'yes'
    os.environ['MSYSTEM'] = 'MINGW64'

    # Ensure gcc is found
    subprocess.run(['C:\\msys64\\usr\\bin\\bash', '-lc', 'which gcc'], check=True)

    # Build libpython3.11.a
    subprocess.run(
        ['C:\\msys64\\usr\\bin\\bash', '-lc', 
        './configure --prefix=/mingw64 --host=x86_64-w64-mingw32 --build=x86_64-w64-mingw32 '
        '--enable-shared --with-system-expat --with-system-ffi --with-system-libmpdec --without-ensurepip '
        '--enable-loadable-sqlite-extensions --with-tzpath=/mingw64/share/zoneinfo --enable-optimizations && make -j8 libpython3.11.a'],  
        cwd=str(vendor_dir_path),
        check=True
    )

else:
    try:
        subprocess.run(['./configure'], cwd=str(vendor_dir_path), check=True)
        subprocess.run(['make', 'libpython3.11.a'], cwd=str(vendor_dir_path), check=True)
        logging.info('Configured and made libpython3.11.a successfully.')
    except Exception as e:
        logging.error('Could not configure or make libpython3.11.a: %s', e)
        raise