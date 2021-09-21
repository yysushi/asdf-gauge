#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/getgauge/gauge"
TOOL_NAME="gauge"
TOOL_TEST="gauge --help"

fail() {
  echo -e "asdf-$TOOL_NAME: $*"
  exit 1
}

curl_opts=(-fsSL)

# NOTE: You might want to remove this if gauge is not hosted on GitHub releases.
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
  curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
  git ls-remote --tags --refs "$GH_REPO" |
    grep -o 'refs/tags/.*' | cut -d/ -f3- |
    sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

list_all_versions() {
  list_github_tags
}

get_download_url() {
  local version="$1"
  echo "$GH_REPO/releases/download/v${version}/gauge-${version}-$(get_platform).$(get_arch).zip"
}

install_version() {
  local version install_path bin_install_path download_url
  version="$1"
  install_path="$2"
  bin_install_path="$install_path/bin"
  download_url="$(get_download_url "$version")"

  (
    mkdir -p "$bin_install_path"
    # download
    echo "* Downloading $TOOL_NAME release $version..."
    curl "${curl_opts[@]}" -o "$install_path/gauge.zip" -C - "$download_url" || fail "Could not download $download_url"
    # extract
    unzip "$install_path/gauge.zip" -d "$bin_install_path" || fail "Could not extract $install_path/gauge.zip"
    chmod +x "$bin_install_path/gauge"
    rm -rf "$install_path/gauge.zip"
    # test
    test -x "$bin_install_path/gauge" || fail "Expected $bin_install_path/gauge to be executable."
    echo "$TOOL_NAME $version installation was successful!"
  ) || (
    rm -rf "$install_path"
    fail "An error ocurred while installing $TOOL_NAME $version."
  )
}

get_arch() {
  uname -m | tr '[:upper:]' '[:lower:]'
}

get_platform() {
  uname | tr '[:upper:]' '[:lower:]'
}
