#!/bin/bash -l
echo "Installing conda"
dnf update -y
dnf install -y wget bzip2 xz  make
dnf group install -y "Development Tools"
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash ./Miniforge3-Linux-x86_64.sh -b -p "${HOME}/conda"
source "${HOME}/conda/etc/profile.d/conda.sh"
# For mamba support also run the following command
source "${HOME}/conda/etc/profile.d/mamba.sh"

echo "Conda installed"


SCRIPT_PATH=$(readlink -f -- "${BASH_SOURCE[0]}")

 if [ -d "/mnt/src" ]; then
   echo "INFO: Standalone build"
   cd /mnt/src
 else 
   echo "INFO: CDI Build"
 fi

VERSION=$(cat ./VERSION)-$(date +"%Y%m%d")

echo "Version is " $VERSION

echo $VERSION > ./VERSION.tmp

echo "Setting up Conda.."
rm -rf /opt/gina/sandy-utils-$VERSION
conda config --add channels conda-forge
conda create -y -p /opt/gina/sandy-utils-$VERSION gdal ruby=3 libffi pkg-config gxx_linux-64 conda-pack git lftp
conda activate /opt/gina/sandy-utils-$VERSION

#echo "Conda setup."
echo "Installing ruby gems.."
export GEM_HOME="/opt/gina/sandy-utils-$VERSION/vendor/bundle"
export GEM_PATH="/opt/gina/sandy-utils-$VERSION:/opt/gina/sandy-utils-$VERSION/vendor/bundle"

echo "setting ld library path.."
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/gina/sandy-utils-$VERSION/lib

echo "Copying sandy-utils to build area.."
cp -rv lib/processing_framework* /opt/gina/sandy-utils-$VERSION/lib/
cp -rv config /opt/gina/sandy-utils-$VERSION/config
cp -v  Gemfile Gemfile.lock  README.md VERSION CHANGELOG.md  notes.md LICENSE Rakefile /opt/gina/sandy-utils-$VERSION
mkdir -p /opt/gina/sandy-utils-$VERSION/tools
./build_bin_stubs.rb bin/*

chmod a+rx /opt/gina/sandy-utils-$VERSION/tools/*

echo "Installing gems required for Sandy-utils.."
cd /opt/gina/sandy-utils-$VERSION
bundle config set deployment true
bundle install 
echo "Done with  ruby gems.."

echo "Ddditional Environment Setting.."
echo export VERSION=$VERSION > /opt/gina/sandy-utils-$VERSION/env.sh
echo source /opt/gina/sandy-utils-$VERSION/bin/activate >> /opt/gina/sandy-utils-$VERSION/env.sh
echo export GEM_HOME="/opt/gina/sandy-utils-$VERSION/vendor/bundle" >> /opt/gina/sandy-utils-$VERSION/env.sh 
echo export GEM_PATH="/opt/gina/sandy-utils-$VERSION:/opt/gina/sandy-utils-$VERSION/vendor/bundle"  >> /opt/gina/sandy-utils-$VERSION/env.sh
echo export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/opt/gina/sandy-utils-$VERSION/lib >> /opt/gina/sandy-utils-$VERSION/env.sh

echo "Making package..."
BUILDDIR=/mnt/build
mkdir -p ${BUILDDIR}
cd ${BUILDDIR}
SB_TARBALL="sandy-utils-$VERSION.pre.tar"
rm  $SB_TARBALL
conda-pack -q --n-threads -1 --compress-level 1 -o $SB_TARBALL

rm -rf ${BUILDDIR}/sandy-utils-$VERSION
mkdir  ${BUILDDIR}/sandy-utils-$VERSION
cd ${BUILDDIR}/sandy-utils-$VERSION
tar -xf ${BUILDDIR}/$SB_TARBALL
cd ${BUILDDIR}
#not sure how to save the build log.
#cp build_log.txt sandy-utils-$VERSION/


+  if [ -d "/mnt/src" ]; then
+    echo "INFO: Standalone build - don't do github stuff"
     tar --bzip2 -cf sandy-utils-$VERSION.tar.bz2 sandy-utils-$VERSION
     tar -cJf  sandy-utils-$VERSION.tar.xz sandy-utils-$VERSION
+  else
+    echo "INFO: CDI Build"
          export SAFE_REF="${GITHUB_REF_NAME//\//-}"
          export FULL_RELEASE_NAME="sandy-utils-${SAFE_REF}.$(date +%Y%m%d)"
          tar --bzip2 -cf $FULL_RELEASE_NAME.tar.bz2 sandy-utils-$VERSION
          tar -cJf  $FULL_RELEASE_NAME.tar.xz sandy-utils-$VERSION
          gh release view "${{ github.ref_name }}" >/dev/null 2>&1 || \
          gh release create "${{ github.ref_name }}" \
           --title "${{ github.ref_name }}" \
           --notes "Automated release for ${{ github.ref_name }}" \
           --target "${{ github.sha }}"
          gh release upload "${{ github.ref_name }}" "${FULL_RELEASE_NAME}.tar.bz2" "${FULL_RELEASE_NAME}.tar.xz"
+  fi
