#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=SCRIPTDIR/../utils.bash
source "$(dirname "${BASH_SOURCE[0]}")/../utils.bash"

ASDF_ASDF-OPENSSL_INSTALL_DEPS_ACCEPT="no"
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -y | --yes)
      ASDF_ASDF-OPENSSL_INSTALL_DEPS_ACCEPT="yes"
      shift # past argument
      ;;
    *)                   # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift              # past argument
      ;;
  esac
done

asdf_asdf-openssl_install_deps @POSITIONAL
