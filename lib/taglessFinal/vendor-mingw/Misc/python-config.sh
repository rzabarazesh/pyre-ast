#!/bin/sh

exit_with_usage ()
{
    echo "Usage: $0 --prefix|--exec-prefix|--includes|--libs|--cflags|--ldflags|--extension-suffix|--help|--abiflags|--configdir|--embed"
    exit 1
}

# Really, python-config.py (and thus .sh) should be called directly, but
# sometimes software (e.g. GDB) calls python-config.sh as if it were the
# Python executable, passing python-config.py as the first argument.
# Work around that oddness by ignoring any .py passed as first arg.
case "$1" in
    *.py)
        shift
    ;;
esac

if [ "$1" = "" ] ; then
    exit_with_usage
fi

# Returns the actual prefix where this script was installed to.
installed_prefix ()
{
    local RESULT=$(dirname $(cd $(dirname "$1") && pwd -P))
    if [ $(which readlink) ] ; then
        RESULT=$(readlink -f "$RESULT")
    fi
    # Since we don't know where the output from this script will end up
    # we keep all paths in Windows-land since MSYS2 can handle that
    # while native tools can't handle paths in MSYS2-land.
    if [ "$OSTYPE" = "msys" ]; then
        RESULT=$(cd "$RESULT" && pwd -W)
    fi
    echo $RESULT
}

prefix_real=$(installed_prefix "$0")

# Use sed to fix paths from their built-to locations to their installed to
# locations. Keep prefix & exec_prefix using their original values in case
# they are referenced in other configure variables, to prevent double
# substitution, issue #22140.
prefix="/mingw64"
exec_prefix="${prefix}"
exec_prefix_real=${prefix_real}
includedir=$(echo "${prefix}/include" | sed "s#$prefix#$prefix_real#")
libdir=$(echo "${exec_prefix}/lib" | sed "s#$prefix#$prefix_real#")
CFLAGS=$(echo "" | sed "s#$prefix#$prefix_real#")
VERSION="3.11"
LIBM="-lm"
LIBC=""
SYSLIBS="$LIBM $LIBC"
ABIFLAGS=""
# Protect against lack of substitution.
if [ "$ABIFLAGS" = "@""ABIFLAGS""@" ] ; then
    ABIFLAGS=
fi
LIBS="-lpython3.11  -lversion -lshlwapi -lpathcch -lbcrypt $SYSLIBS"
LIBS_EMBED="-lpython${VERSION}${ABIFLAGS}  -lversion -lshlwapi -lpathcch -lbcrypt $SYSLIBS"
BASECFLAGS=" -Wsign-compare"
OPT="-DNDEBUG -g -fwrapv -O3 -Wall"
PY_ENABLE_SHARED="1"
LDVERSION="$(VERSION)$(ABIFLAGS)"
LDLIBRARY="libpython$(LDVERSION).dll.a"
LIBDEST=${prefix_real}/lib/python${VERSION}
LIBPL=$(echo "$(prefix)/lib/python3.11/config-$(VERSION)$(ABIFLAGS)" | sed "s#$prefix#$prefix_real#")
SO=".cp311-mingw_x86_64.pyd"
PYTHONFRAMEWORK=""
INCDIR="-I$includedir/python${VERSION}${ABIFLAGS}"
PLATINCDIR="-I$includedir/python${VERSION}${ABIFLAGS}"
PY_EMBED=0

# Scan for --help or unknown argument.
for ARG in $*
do
    case $ARG in
        --help)
            exit_with_usage
        ;;
        --embed)
            PY_EMBED=1
        ;;
        --prefix|--exec-prefix|--includes|--libs|--cflags|--ldflags|--extension-suffix|--abiflags|--configdir)
        ;;
        *)
            exit_with_usage
        ;;
    esac
done

if [ $PY_EMBED = 1 ] ; then
    LIBS="$LIBS_EMBED"
fi

for ARG in "$@"
do
    case $ARG in
        --prefix)
            echo -ne "$prefix_real"
        ;;
        --exec-prefix)
            echo -ne "$exec_prefix_real "
        ;;
        --includes)
            echo -ne "$INCDIR $PLATINCDIR"
        ;;
        --cflags)
            echo -ne "$INCDIR $PLATINCDIR $BASECFLAGS $CFLAGS $OPT"
        ;;
        --libs)
            echo -ne "$LIBS"
        ;;
        --ldflags)
            LIBPLUSED=
            if [ "$PY_ENABLE_SHARED" = "0" ] ; then
                LIBPLUSED="-L$LIBPL"
            fi
            echo -ne "$LIBPLUSED -L$libdir $LIBS "
        ;;
        --extension-suffix)
            echo -ne "$SO "
        ;;
        --abiflags)
            echo -ne "$ABIFLAGS "
        ;;
        --configdir)
            echo -ne "$LIBPL "
        ;;
esac
done
