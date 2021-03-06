#!/bin/sh

# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script can be used to set up apache to interact with the devserver.
# This apache server will run on port 8082 and rewrite requests to the
# devserver that aren't stored in the IMAGE_ROOT.

# Usage:
# ./setup_apache.sh -- Sets up using default static directory.
# ./setup_apache.sh DIR -- Sets up apache to serve images from DIR.

DEFAULT_IMAGE_ROOT=/home/chromeos-test/images
APACHE_CONFIG=/etc/apache2
ARCHIVE_ROOT=/var/www
MY_DIR="$(dirname $0)"

set -e

main () {
  sudo apt-get install apache2

  # Copy over configuration data.
  mkdir -m 755 -p "${ARCHIVE_ROOT}"
  cp -f "${MY_DIR}"/htaccess "${ARCHIVE_ROOT}/.htaccess"
  cp -f "${MY_DIR}"/apache2.conf "${APACHE_CONFIG}"
  cp -f "${MY_DIR}"/ports.conf "${APACHE_CONFIG}"
  cp -f "${MY_DIR}"/devserver "${APACHE_CONFIG}"/sites-available

  sudo chmod a+r -R ${ARCHIVE_ROOT}

  # Enable configurations.
  ln -sf "${APACHE_CONFIG}"/sites-available/devserver \
    "${APACHE_CONFIG}"/sites-enabled

  ln -sf "${APACHE_CONFIG}"/mods-available/proxy.load \
    "${APACHE_CONFIG}"/mods-enabled
  ln -sf "${APACHE_CONFIG}"/mods-available/proxy_http.load \
    "${APACHE_CONFIG}"/mods-enabled
  ln -sf "${APACHE_CONFIG}"/mods-available/rewrite.load \
    "${APACHE_CONFIG}"/mods-enabled

  # Setup devserver archive location.
  local image_root="${DEFAULT_IMAGE_ROOT}"
  [ -n "${1}" ] && image_root="${1}"

  local static_dir="${ARCHIVE_ROOT}"/static
  if [ -e "${static_dir}" ]; then
    unlink "${static_dir}"
  fi

  ln -sf "${image_root}" "${static_dir}"

  if [ -e "${static_dir}/archive" ]; then
    unlink "${static_dir}/archive"
  fi

  # Create a link to archive that points back to the same dir.
  ln -sf "${image_root}" "${static_dir}/archive"

  /etc/init.d/apache2 restart
}

main $@
