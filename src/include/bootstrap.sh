#!/usr/bin/env bash
#
# Copyright 2014-2016 Paramtamtam <github.com/tarampampam>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

export LC_ALL=C;
[[ -z $NOD32MIRROR_FORCE_YES ]]         && export NOD32MIRROR_FORCE_YES=0;
[[ -z $NOD32MIRROR_EXTRA_CONFIGS_DIR ]] && export NOD32MIRROR_EXTRA_CONFIGS_DIR="$NOD32MIRROR_BASE_DIR/conf.d";

function require() {
  source "$1" || { echo "[FATAL ERROR] $2 file '$1' not exists or contains errors" && exit 1; };
}

require "$NOD32MIRROR_BASE_DIR/settings.conf"        'Settings';
require "$NOD32MIRROR_BASE_DIR/include/version.sh"   'Check versions functions';
require "$NOD32MIRROR_BASE_DIR/include/system.sh"    'System functions';
require "$NOD32MIRROR_BASE_DIR/include/ui.sh"        'User interface functions';
require "$NOD32MIRROR_BASE_DIR/include/fs.sh"        'File system functions';
require "$NOD32MIRROR_BASE_DIR/include/logger.sh"    'Log functions';
require "$NOD32MIRROR_BASE_DIR/include/debugmode.sh" 'Debug mode functions';
require "$NOD32MIRROR_BASE_DIR/include/network.sh"   'Network functions';
require "$NOD32MIRROR_BASE_DIR/include/nod32keys.sh" 'NOD32 keys functions';
require "$NOD32MIRROR_BASE_DIR/include/nod32.sh"     'NOD32 servers functions';
require "$NOD32MIRROR_BASE_DIR/include/ini.sh"       'INI files functions';

# Load extra configuration files
[ -d "$NOD32MIRROR_EXTRA_CONFIGS_DIR" ] && {
  for extra_config in $(find $NOD32MIRROR_EXTRA_CONFIGS_DIR -type f -name '*.conf'); do
    require "$extra_config" 'Extra configuration file';
  done;
};

# Check passed to script arguments
for arg in "$@"; do
  case $arg in
    '-d'|'--debug')     export NOD32MIRROR_DEBUG_MODE=1; set -e;;
    '-y'|'--force-yes') export NOD32MIRROR_FORCE_YES=1;;
    '-C'|'--color')     export NOD32MIRROR_COLOR_OUTPUT=1;;
    '-c'|'--no-color')  export NOD32MIRROR_COLOR_OUTPUT=0;;
  esac;
done;

# Check user id
#if [[ "$(id -u)" -eq 0 ]]; then
#  if [[ "$NOD32MIRROR_FORCE_YES" -ne 1 ]]; then
#    ui_message 'error' "$(ui_style 'Please do not run this script as root' 'red reverse')";
#    while true; do
#      echo -en "[Question] "; read -e -p "Do you want to continue? [y|n] " -i "n" yn;
#      case $yn in
#        [Nn]*) exit 1;;
#        [Yy]*) break;;
#        *)     ui_message 'error' 'Please answer (y)es or (n)o';;
#      esac;
#    done;
#  fi;
#fi;
