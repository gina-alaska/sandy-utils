VERSION=$(cat ~/build/VERSION)
echo "Version is " $VERSION
conda activate /opt/gina/sandy-utils-$VERSION

#echo "Conda setup."
echo "Installing ruby gems.."
export GEM_HOME="/opt/gina/sandy-utils-$VERSION/vendor/bundle"
export GEM_PATH="/opt/gina/sandy-utils-$VERSION:/opt/gina/sandy-utils-$VERSION/vendor/bundle"
