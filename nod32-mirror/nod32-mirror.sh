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

# Declare important variables
export NOD32MIRROR_VERSION="1.0.1.8";
[[ -z $NOD32MIRROR_BASE_DIR ]] && export NOD32MIRROR_BASE_DIR=$(dirname $(readlink -e $0));

# Execute bootstrap script
source "$NOD32MIRROR_BASE_DIR/include/bootstrap.sh" || { echo "[FATAL ERROR] Bootstrap file not found or contains errors" && exit 1; };

# Declare actions flags
ACTION_MAKE_UPDATE=0;
ACTION_MAKE_FLUSH=0;
ACTION_GET_KEY=0;
ACTION_KEYS_UPDATE=0;
ACTION_KEYS_CLEAN=0;
ACTION_KEYS_SHOW=0;
ACTION_DISABLE_NETWORK_LIMITS=0;
ACTION_SHOW_HELP=1;
ACTION_SHOW_VERSION=0;

# Check passed options and set actions flags
for arg in "$@"; do
  case $arg in
    '-u'|'--update')       ACTION_SHOW_HELP=0; ACTION_MAKE_UPDATE=1; ACTION_SHOW_STAT=1;;
    '-f'|'--flush')        ACTION_SHOW_HELP=0; ACTION_MAKE_FLUSH=1; ACTION_SHOW_STAT=1;;
    '-k'|'--get-key')      ACTION_SHOW_HELP=0; ACTION_GET_KEY=1;;
    '--keys-update')       ACTION_SHOW_HELP=0; ACTION_KEYS_UPDATE=1;;
    '--keys-clean')        ACTION_SHOW_HELP=0; ACTION_KEYS_CLEAN=1;;
    '--keys-show')         ACTION_SHOW_HELP=0; ACTION_KEYS_SHOW=1;;
    '-s'|'--stat')         ACTION_SHOW_HELP=0; ACTION_MAKE_UPDATE=0; ACTION_SHOW_STAT=1;;
    '-l'|'--no-limit')     ACTION_DISABLE_NETWORK_LIMITS=1;;
    '-h'|'-H'|'--help')    ACTION_SHOW_HELP=1;;
    '-V'|'-v'|'--version') ACTION_SHOW_HELP=0; ACTION_SHOW_VERSION=1;;
  esac;
done;

[[ -z $NOD32MIRROR_VERSION ]] && export NOD32MIRROR_VERSION='[unsetted]';

# Actions declarations
[[ "$ACTION_SHOW_HELP" -eq 1 ]] && {
  self=$(basename "$(test -L "$0" && readlink "$0" || echo "$0")");
  installed="$(ui_style 'installed' 'green')";
  not_installed="$(ui_style 'not installed' 'red bold')";
  unrar_inst="$not_installed"   && { system_application_exists 'unrar' && unrar_inst="$installed"; };
  curl_inst="$not_installed"    && { system_application_exists 'curl'  && curl_inst="$installed"; };
  wget_inst="$not_installed"    && { system_application_exists 'wget'  && wget_inst="$installed"; };
  sed_awk_inst="$not_installed" && { system_application_exists 'sed'   && system_application_exists 'awk' && sed_awk_inst="$installed"; };
echo -e "
    _   __          __________      __  ____
   / | / /___  ____/ /__  /__ \    /  |/  (_)_____________  _____
  /  |/ / __ \/ __  / /_ <__/ /   / /|_/ / / ___/ ___/ __ \/ ___/
 / /|  / /_/ / /_/ /___/ / __/   / /  / / / /  / /  / /_/ / /
/_/ |_/\____/\__,_//____/____/  /_/  /_/_/_/  /_/   \____/_/

  $(ui_style 'NOD32 Update Mirror' 'green') ($(ui_style 'https://git.io/vKs5E' 'yellow underline')), version "$(ui_style "$NOD32MIRROR_VERSION" 'yellow')"

$(ui_style 'Optional depends by:' 'yellow')
  $(ui_style 'unrar' 'yellow')      ($unrar_inst)
  $(ui_style 'curl' 'yellow')       ($curl_inst)
  $(ui_style 'wget' 'yellow')       ($wget_inst)
  $(ui_style 'sed & awk' 'yellow')  ($sed_awk_inst)

$(ui_style 'Usage:' 'yellow')
  $self [options]

$(ui_style 'Options:' 'yellow')
  $(ui_style '-u, --update' 'green')       $(ui_style 'Update mirror' 'yellow')
  $(ui_style '-f, --flush' 'green')        Remove all downloaded mirror files
  $(ui_style '-k, --get-key' 'green')      $(ui_style 'Get free key' 'yellow') ($(ui_style 'Use for educational or informational purposes only!' 'red bold'))
      $(ui_style '--keys-update' 'green')  Update free keys
      $(ui_style '--keys-clean' 'green')   Test all stored keys and remove invalid
      $(ui_style '--keys-show' 'green')    Show all stored valid keys
  $(ui_style '-C, --color' 'green')        Force enable color output
  $(ui_style '-c, --no-color' 'green')     Force disable color output
  $(ui_style '-s, --stat' 'green')         Show statistics
  $(ui_style '-l, --no-limit' 'green')     Disable any download limits
  $(ui_style '-d, --debug' 'green')        Display debug messages
  $(ui_style '-h, --help' 'green')         Display this help message
  $(ui_style '-v, --version' 'green')      Display script version
";
};

[[ "$ACTION_SHOW_VERSION" -eq 1 ]] && {
  echo -e "
Nod32 Update Mirror Script, version $NOD32MIRROR_VERSION
Copyright 2014-2016 Paramtamtam <github.com/tarampampam>
License MIT: <rawgit.com/tarampampam/nod32-update-mirror/master/LICENSE>

This is free software. There is NO WARRANTY, to the extent permitted by law.
";
};

[[ "$ACTION_MAKE_FLUSH" -eq 1 ]] && {
  ui_message 'debug' 'Execute "flush" action';
  [ -d "$NOD32MIRROR_MIRROR_DIR" ] && {
    find "$NOD32MIRROR_MIRROR_DIR" -type f \(\
      -name '*.nup' \
      -o -name '._*' \
      -o -name '*.ver' \
      -o -name "$NOD32MIRROR_TIMESTAMP_FILE_NAME" \
      -o -name "$NOD32MIRROR_VERSION_FILE_NAME" \)\
      -delete;
    find "$NOD32MIRROR_MIRROR_DIR" -type d \(\
      -name 'pcu' \
      -o -name 'v[0-9]*' \)\
      -exec rm -Rf "{}" +;
    ui_message 'notice' 'Mirror flushed';
  };
};

[[ "$ACTION_GET_KEY" -eq 1 ]] && {
  ui_message 'debug' 'Execute "get key" action';
  echo -e "\n$(ui_style 'Use for educational or informational purposes only!' 'red bold')\n";
  nod32keys_get_valid_key || {
    ui_message 'fatal' 'Cannot get valid free key' && exit 1;
  }
};

[[ "$ACTION_DISABLE_NETWORK_LIMITS" -eq 1 ]] && {
  ui_message 'debug' 'Execute "dissable network limits" action';
  ui_message 'debug' 'Download limits DISABLED';
  export NOD32MIRROR_DOWNLOAD_SPEED_LIMIT=0;
  export NOD32MIRROR_DOWNLOAD_DELAY=0;
};

[[ "$ACTION_KEYS_UPDATE" -eq 1 ]] && {
  ui_message 'debug' 'Execute "keys update" action';
  nod32keys_update_keys;
};

[[ "$ACTION_KEYS_CLEAN" -eq 1 ]] && {
  ui_message 'debug' 'Execute "keys clean" action';
  nod32keys_remove_invalid_keys;
};

[[ "$ACTION_KEYS_SHOW" -eq 1 ]] && {
  ui_message 'debug' 'Execute "keys show" action';
  nod32keys_get_all_keys 'valid';
};

[[ "$ACTION_MAKE_UPDATE" -eq 1 ]] && {
  ui_message 'debug' 'Execute "update" action';
  if [[ -z $NOD32MIRROR_MIRROR_DIR ]]; then
    ui_message 'fatal' 'Empty directory path for mirroring files. Please, check configuration file' && exit 1;
  fi;
  [[ "$NOD32MIRROR_USE_FREE_KEY" -eq 1 ]] && {
    # Work with 'free key'
    ui_message 'debug' 'Use free key option is ENABLED';
    ui_message 'info' 'Requesting for a free key.. ' '' 'no_newline';
    free_key=$(nod32keys_get_valid_key 2>&1 | tail -n 1);
    username=${free_key%%:*};
    password=${free_key#*:};
    if [[ ! -z "$username" ]] && [[ ! -z "$password" ]]; then
      export NOD32MIRROR_SERVER_URI='http://update.eset.com:80/eset_upd/';
      export NOD32MIRROR_SERVER_USERNAME="$username";
      export NOD32MIRROR_SERVER_PASSWORD="$password";
      echo -e "$(ui_style 'Success' 'green')";
    else
      echo -e "$(ui_style 'Error' 'red')";
    fi;
    ui_message 'debug' 'Username and password' "$username:$password";
  } || {
    ui_message 'debug' 'Use free key option is disabled';
    # Setup global server URI, username and password based on settings
    # declared in configuration file
    nod32_autosetup_working_server;
  };
  # Check for exists work server info
  if [[ ! -z "$NOD32MIRROR_SERVER_URI" ]]; then
    ui_message 'debug' 'Work with server' "$NOD32MIRROR_SERVER_URI";
    # Prepare directory for mirroring files
    fs_create_directory "$NOD32MIRROR_MIRROR_DIR" || {
      ui_message 'fatal' 'Cannot create directory for mirroring files' "$NOD32MIRROR_MIRROR_DIR" && exit 1;
    } && {
      ui_message 'debug' 'Directory for mirroring files' "$NOD32MIRROR_MIRROR_DIR";
    };
    # Prepare directory for temporary files
    if fs_remove_temp_directory && fs_create_temp_directory; then
      ui_message 'debug' 'Directory for temporary files' "$(fs_get_temp_directory)";
      NOD32MIRROR_VERSIONS="__ROOT__ $NOD32MIRROR_VERSIONS"; # Add '__ROOT__' to versions list
      for VERSION in $NOD32MIRROR_VERSIONS; do
        extra_url='';
        if [[ ! "$VERSION" == "__ROOT__" ]]; then
          if [[ "$VERSION" =~ ^[0-9]+$ ]]; then
            extra_url="v$VERSION/";
          else
            extra_url="$VERSION/";
          fi;
        fi;
        nod32_mirror_remote_directory "$extra_url";
      done;
      fs_create_timestamp_file "$NOD32MIRROR_MIRROR_DIR" && {
        ui_message 'info' 'Timestamp file created' "$NOD32MIRROR_TIMESTAMP_FILE_NAME";
      };
    else
      ui_message 'fatal' 'Cannot create (or remove) directory for temporary files' "$(fs_get_temp_directory)";
      ACTION_SHOW_STAT=0;
    fi;
  else
    ui_message 'fatal' 'No available servers could be found at this time. Please, check configuration file';
    ACTION_SHOW_STAT=0;
  fi;
};

[[ "$ACTION_SHOW_STAT" -eq 1 ]] && {
  mirror_dir="$NOD32MIRROR_MIRROR_DIR";
  [ -d "$mirror_dir" ] && {
    files_count=$(find "$mirror_dir" -type f -iname '*.nup' | wc -l);
    [[ ! "$files_count" == "" ]] && {
      ui_message 'info' "Total updates (*.nup) files count: $(ui_style "$files_count file(s)" 'yellow')";
    };
    updates_files_size=$(find "$mirror_dir" -type f -name '*.nup' -ls | awk '{total += $7} END {printf("%.1fM", (total/1024/1024))}');
    [[ ! "$updates_files_size" == "" ]] && {
      ui_message 'info' "Total updates (*.nup) files size: $(ui_style $updates_files_size 'yellow')";
    };
    mirror_dir_size=$(fs_get_directory_size "$mirror_dir");
    [[ ! "$mirror_dir_size" == "0" ]] && {
      ui_message 'info' "Mirror directory size is $(ui_style $mirror_dir_size 'yellow')";
    };
  };
};

[ -d "$(fs_get_temp_directory)" ] && fs_remove_temp_directory;
