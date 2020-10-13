#!/bin/bash -l
cd 

VERSION=$(cat ~/build/VERSION)

echo "Version is " $VERSION

echo "Setting up Conda.."
rm -rf /opt/gina/sandy-utils-$VERSION
conda config --add channels conda-forge
conda create -y -p /opt/gina/sandy-utils-$VERSION gdal ruby=2.6.5 libffi pkg-config gxx_linux-64 conda-pack
conda activate /opt/gina/sandy-utils-$VERSION

#echo "Conda setup."
echo "Installing ruby gems.."
export GEM_HOME="/opt/gina/sandy-utils-$VERSION/vendor/bundle"
export GEM_PATH="/opt/gina/sandy-utils-$VERSION:/opt/gina/sandy-utils-$VERSION/vendor/bundle"

echo "Copying sandy-utils to build area.."
cd ~/build
cp -rv lib/processing_framework* /opt/gina/sandy-utils-$VERSION/lib/
cp -rv config /opt/gina/sandy-utils-$VERSION/config
cp -v  Gemfile Gemfile.lock config README.md VERSION CHANGELOG.md  notes.md LICENSE Rakefile /opt/gina/sandy-utils-$VERSION
mkdir -p /opt/gina/sandy-utils-$VERSION/tools
./build_bin_stubs.rb bin/*

echo "Done with  ruby gems.."
export GEM_HOME="/opt/gina/sandy-utils-$VERSION/vendor/bundle"
export GEM_PATH="/opt/gina/sandy-utils-$VERSION:/opt/gina/sandy-utils-$VERSION/vendor/bundle"

echo "Installing gems required for Sandy-utils.."
cd /opt/gina/sandy-utils-$VERSION
bundle install --deployment
echo "Done with  ruby gems.."

echo "Making package..."
cd ~/build
SB_TARBALL="sandy-utils-$VERSION.pre.tar.gz"
conda pack -q --n-threads -1 --compress-level 0 -o $SB_TARBALL
mkdir  ~/build/sandy-utils-$VERSION
cd ~/build/sandy-utils-$VERSION
tar -xf ~/build/$SB_TARBALL
cp ~/build/build_log.txt .
cd ~/build
tar --gzip -cf sandy-utils-$VERSION.tar.gz sandy-utils-$VERSION

