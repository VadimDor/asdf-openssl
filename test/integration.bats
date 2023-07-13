#!/usr/bin/env bats

# shellcheck disable=SC2230

load ../node_modules/bats-support/load.bash
load ../node_modules/bats-assert/load.bash
load ./lib/test_utils

# TODO: check tests below you really adopt

setup_file() {
  PROJECT_DIR="$(realpath "$(dirname "$BATS_TEST_DIRNAME")")"
  export PROJECT_DIR
  cd "$PROJECT_DIR"
  clear_lock git

  ASDF_DIR="$(mktemp -t asdf-openssl-integration-tests.XXXX -d)"
  export ASDF_DIR

  get_lock git
  git clone \
    --branch=v0.10.2 \
    --depth=1 \
    https://github.com/asdf-vm/asdf.git \
    "$ASDF_DIR"
  clear_lock git
}

teardown_file() {
  clear_lock git
  rm -rf "$ASDF_DIR"
}

setup() {
  ASDF_ASDF-OPENSSL_TEST_TEMP="$(mktemp -t asdf-openssl-integration-tests.XXXX -d)"
  export ASDF_ASDF-OPENSSL_TEST_TEMP
  ASDF_DATA_DIR="${ASDF_ASDF-OPENSSL_TEST_TEMP}/asdf"
  export ASDF_DATA_DIR
  mkdir -p "$ASDF_DATA_DIR/plugins"

  # `asdf plugin add asdf-openssl .` would only install from git HEAD.
  # So, we install by copying the plugin to the plugins directory.
  cp -R "$PROJECT_DIR" "${ASDF_DATA_DIR}/plugins/asdf-openssl"
  cd "${ASDF_DATA_DIR}/plugins/asdf-openssl"

  # shellcheck disable=SC1090,SC1091
  source "${ASDF_DIR}/asdf.sh"

  ASDF_ASDF-OPENSSL_VERSION_INSTALL_PATH="${ASDF_DATA_DIR}/installs/asdf-openssl/ref-version-1-6"
  export ASDF_ASDF-OPENSSL_VERSION_INSTALL_PATH

  # optimization if already installed
  info "asdf install asdf-openssl ref:version-1-6"
  if [ -d "${HOME}/.asdf/installs/asdf-openssl/ref-version-1-6" ]; then
    mkdir -p "${ASDF_DATA_DIR}/installs/asdf-openssl"
    cp -R "${HOME}/.asdf/installs/asdf-openssl/ref-version-1-6" "${ASDF_ASDF-OPENSSL_VERSION_INSTALL_PATH}"
    rm -rf "${ASDF_ASDF-OPENSSL_VERSION_INSTALL_PATH}/asdf-openssl"
    asdf reshim
  else
    get_lock git
    asdf install asdf-openssl ref:version-1-6
    clear_lock git
  fi
  asdf local asdf-openssl ref:version-1-6
}

teardown() {
  asdf plugin remove asdf-openssl || true
  rm -rf "${ASDF_ASDF-OPENSSL_TEST_TEMP}"
}

info() {
  echo "# ${*} …" >&3
}

@test "asdf-openssl_configuration__without_asdf-openssldeps" {
  # Assert package index is placed in the correct location
  info "asdf-openssl refresh -y"
  get_lock git
  asdf-openssl refresh -y
  clear_lock git
  assert [ -f "${ASDF_ASDF-OPENSSL_VERSION_INSTALL_PATH}/asdf-openssl/packages_official.json" ]

  # Assert package installs to correct location
  info "asdf-openssl install -y asdf-openssljson@1.2.8"
  get_lock git
  asdf-openssl install -y asdf-openssljson@1.2.8
  clear_lock git
  assert [ -x "${ASDF_ASDF-OPENSSL_VERSION_INSTALL_PATH}/asdf-openssl/bin/asdf-openssljson" ]
  assert [ -f "${ASDF_ASDF-OPENSSL_VERSION_INSTALL_PATH}/asdf-openssl/pkgs/asdf-openssljson-1.2.8/asdf-openssljson.asdf-openssl" ]
  assert [ ! -x "./asdf-openssldeps/bin/asdf-openssljson" ]
  assert [ ! -f "./asdf-openssldeps/pkgs/asdf-openssljson-1.2.8/asdf-openssljson.asdf-openssl" ]

  # Assert that shim was created for package binary
  assert [ -f "${ASDF_DATA_DIR}/shims/asdf-openssljson" ]

  # Assert that correct asdf-openssljson is used
  assert [ -n "$(asdf-openssljson -v | grep ' version 1\.2\.8')" ]

  # Assert that asdf-openssl finds asdf-openssl packages
  echo "import asdf-openssljson" >"${ASDF_ASDF-OPENSSL_TEST_TEMP}/testasdf-openssl.asdf-openssl"
  info "asdf-openssl c -r \"${ASDF_ASDF-OPENSSL_TEST_TEMP}/testasdf-openssl.asdf-openssl\""
  asdf-openssl c -r "${ASDF_ASDF-OPENSSL_TEST_TEMP}/testasdf-openssl.asdf-openssl"
}

@test "asdf-openssl_configuration__with_asdf-openssldeps" {
  rm -rf asdf-openssldeps
  mkdir "./asdf-openssldeps"

  # Assert package index is placed in the correct location
  info "asdf-openssl refresh"
  get_lock git
  asdf-openssl refresh -y
  clear_lock git
  assert [ -f "./asdf-openssldeps/packages_official.json" ]

  # Assert package installs to correct location
  info "asdf-openssl install -y asdf-openssljson@1.2.8"
  get_lock git
  asdf-openssl install -y asdf-openssljson@1.2.8
  clear_lock git
  assert [ -x "./asdf-openssldeps/bin/asdf-openssljson" ]
  assert [ -f "./asdf-openssldeps/pkgs/asdf-openssljson-1.2.8/asdf-openssljson.asdf-openssl" ]
  assert [ ! -x "${ASDF_ASDF-OPENSSL_VERSION_INSTALL_PATH}/asdf-openssl/bin/asdf-openssljson" ]
  assert [ ! -f "${ASDF_ASDF-OPENSSL_VERSION_INSTALL_PATH}/asdf-openssl/pkgs/asdf-openssljson-1.2.8/asdf-openssljson.asdf-openssl" ]

  # Assert that asdf-openssl finds asdf-openssl packages
  echo "import asdf-openssljson" >"${ASDF_ASDF-OPENSSL_TEST_TEMP}/testasdf-openssl.asdf-openssl"
  info "asdf-openssl c --asdf-opensslPath:./asdf-openssldeps/pkgs -r \"${ASDF_ASDF-OPENSSL_TEST_TEMP}/testasdf-openssl.asdf-openssl\""
  asdf-openssl c --asdf-opensslPath:./asdf-openssldeps/pkgs -r "${ASDF_ASDF-OPENSSL_TEST_TEMP}/testasdf-openssl.asdf-openssl"

  rm -rf asdf-openssldeps
}
