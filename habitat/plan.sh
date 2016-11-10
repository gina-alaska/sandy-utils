pkg_name="sandy-utils"
pkg_version=$(cat $PLAN_CONTEXT/../VERSION)
pkg_origin="uafgina"
pkg_maintainer="UAF GINA <support+habitat@gina.alaska.edu>"
pkg_license=('MIT')
pkg_source=nosource.tar.gz
pkg_deps=(
  core/bash
  core/bundler
  core/cacerts
  core/glibc
  core/libffi
  core/libyaml
  core/ruby
  core/zlib
)
pkg_build_deps=(
  core/coreutils
  core/gcc
  core/gcc-libs
  core/make
  core/git
  core/ruby
  core/bundler
  core/libyaml
)

pkg_bin_dirs=(bin)

do_build() {
	cp -av $PLAN_CONTEXT/../bin .
  cp -av $PLAN_CONTEXT/../lib .
  cp -av $PLAN_CONTEXT/../config .
  cp -av $PLAN_CONTEXT/../Gemfile* .

  local _bundler_dir=$(pkg_path_for bundler)

  export GEM_HOME=${pkg_path}/vendor/bundle
  export GEM_PATH=${_bundler_dir}:${GEM_HOME}


  bundle install --jobs 2 --retry 5 --path vendor/bundle --without development test
}

do_install() {
  cp -av . $pkg_prefix/

  for binstub in ${pkg_prefix}/bin/*; do
    build_line "Setting shebang for ${binstub} to 'ruby'"
    [[ -f $binstub ]] && sed -e "s#/usr/bin/env ruby#$(pkg_path_for ruby)/bin/ruby#" -i $binstub
    build_line "Wrapping ${binstub}"
    wrap_script "${binstub}"
  done
}

wrap_script() {
  mv $1 ${1}.real
  cat <<- EOF > $1
#!$(pkg_path_for core/bash)/bin/bash
export GEM_HOME="${pkg_prefix}/vendor/bundle"
export GEM_PATH="$(pkg_path_for bundler):${pkg_prefix}/vendor/bundle"

# Don't leak rails environment into the runner
unset LD_LIBRARY_PATH

# TODO:  This is horrible, but there is no other good alternative in the short
#        timeframe.  Terascan needs stuff set, but there is no good way to do this
#        in the existing scripts, so we'll attempt to do it here.
if [[ -f \$TSCANROOT/etc/tscan.bash_profile ]]; then
  source \$TSCANROOT/etc/tscan.bash_profile
fi


exec ${1}.real \$@
EOF
  chmod +x "${1}"
}

do_download() {
  return 0
}

do_verify() {
  return 0
}

do_unpack() {
  return 0
}

do_prepare() {
  return 0
}
