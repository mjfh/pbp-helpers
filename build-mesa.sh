#! /bin/sh
#
# Syntax:
#  sh build-mesa.sh [DEVDIR=/fancy/dev/dir] [UNINSTALL=yes]
#
# Ackn:
#  xmixahlx
#  https://forum.pine64.org/showthread.php?tid=8953
#  v0.2020202.2020
#  BUILD MESA-GIT AND INSTALL TO /USR/LOCAL
#  RERUN TO UPDATE

## COMMAND LINE ARGUMENTS
for args do
    case $args in
    ?*=?*) var=`expr "$args" : '\([^=]*\)'`
	   val=`expr "$args" : '[^=]*=\(.*\)'`
	   eval "$var"="'$val'" ;;
    *)     exec >&2
	   s="[DEVDIR=/fancy/build/folder] [UNINSTALL=yes] [GIT_PULL=no] [CLEAN=no]"
	   echo "Usage: /bin/sh `basename $0` $s"
	   exit 2
    esac
done

## VARS
: ${DEVDIR:=/usr/local/src/build}
PKGDIR="$DEVDIR/mesa"

if test yes = "$UNINSTALL"
then (
    ## UNINSTALL
    echo set -ex
    echo cd "'$PKGDIR'"

    echo ninja -C pbp-build uninstall
    echo ldconfig
  ) | sudo -s

else (
    ## REQS
    echo echo
    echo echo +++ Make sure that deb-src is enabled in /etc/apt/sources.list
    echo echo
    echo set -ex
    echo apt update
    echo apt -y install meson ccache git build-essential cmake
    echo apt -y build-dep mesa libcairo2-dev
    echo mkdir -p      "'$DEVDIR'"
    echo chown `id -u` "'$DEVDIR'"
  ) | sudo -s &&

  (
    set -ex
    cd "$DEVDIR"
  
    ## GET/UPDATE
    test -f "$PKGDIR/.gitignore" ||
      git clone --depth=1 https://gitlab.freedesktop.org/mesa/mesa.git

    ## UPDATE (RERUN)
    cd "$PKGDIR"
    git clean -f
    test no = "$GIT_PULL" || {
      git checkout master
      git reset --hard
      git pull origin master
      git branch `date "+%Y%m%d%H%M%S-bullt"` || true
    }
  ) &&

  (
    set -ex
    cd "$PKGDIR"

    ## CONFIGURE
    rm -Rf pbp-build
    meson pbp-build \
	-Dprefix=/usr/local \
	-Dbuildtype=release \
	-Dplatforms=x11,wayland,drm,surfaceless \
	-Dgallium-drivers=panfrost,kmsro,swrast \
	-Dllvm=false \
	-Dlibunwind=false

    ## BUILD
    ninja -C pbp-build
  ) &&

  (
    echo set -ex
    echo cd "'$PKGDIR'"

    ## INSTALL & CLEAN
    echo ninja -C pbp-build install
    echo ldconfig
    test no = "$CLEAN" || {
      echo rm -Rf pbp-build
    }
  ) | sudo -s &&

  # RESTART XORG OR WAYLAND
  echo "+++ Done - restart Xorg or Wayland now :)"
fi

# ENJOY
