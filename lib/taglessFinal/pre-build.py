#!/usr/bin/env python3

import platform
import pathlib
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Get the directory of this script
script_dir = pathlib.Path(__file__).parent.absolute()

# Check the system
is_windows = 'CYGWIN' in platform.system()

configure_cmd = "" if is_windows else "(run ./configure)"
# Choose the vendor dir based on the system
vendor_dir = 'vendor-mingw' if is_windows else 'vendor'

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
     (progn
       {configure_cmd}
       (run make libpython3.11.a))
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
