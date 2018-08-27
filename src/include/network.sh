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

[[ -z $NOD32MIRROR_CURL_BIN ]]             && export NOD32MIRROR_CURL_BIN=$(which curl);
[[ -z $NOD32MIRROR_WGET_BIN ]]             && export NOD32MIRROR_WGET_BIN=$(which wget);
[[ -z $NOD32MIRROR_DOWNLOAD_SPEED_LIMIT ]] && export NOD32MIRROR_DOWNLOAD_SPEED_LIMIT=0;
[[ -z $NOD32MIRROR_DOWNLOAD_DELAY ]]       && export NOD32MIRROR_DOWNLOAD_DELAY=0;
[[ -z $NOD32MIRROR_DOWNLOAD_TIMEOUT ]]     && export NOD32MIRROR_DOWNLOAD_TIMEOUT=5;
[[ -z $NOD32MIRROR_DOWNLOAD_TRIES ]]       && export NOD32MIRROR_DOWNLOAD_TRIES=2;


function network_generate_useragent() {
  local RD=$RANDOM;
  echo "ESS Update (Windows; U; 32bit; VDB $((RD%15000+10000)); BPC $((RD%2+6)).0.\
$((RD%100+500)).0; OS: 5.1.2600 SP 3.0 NT; CH 1.1; LNG 1049; x32c; APP eavbe; BEO \
1; ASP 0.10; FW 0.0; PX 0; PUA 0; RA 0)";
}

if [[ -z $NOD32MIRROR_USERAGENT ]]; then
  export NOD32MIRROR_USERAGENT=$(network_generate_useragent);
fi;

function network_uri_add_last_slash() {
  local uri=$1; # URI (string)
  if [[ "${uri: -1}" == "/" ]]; then
    echo "$uri";
  else
    echo "$uri/";
  fi;
}

function network_uri_remove_last_slash() {
  local uri=$1; # URI (string)
  sed 's#/*$##' <<< "$uri";
}

function network_tool_enabled() {
  local tool_path=$1; # Tool path (string)
  if [[ ! "$tool_path" == 'false' ]] && [ -x "$tool_path" ]; then
    return 0;
  fi;
  return 1;
}

function network_get_headers() {
  local uri=$1;      # Request URI (string)
  local username=$2; # Auth username (string)
  local password=$3; # Auth password (string)
  local headers='';
  network_tool_enabled "$NOD32MIRROR_CURL_BIN" && {
    headers=$("$NOD32MIRROR_CURL_BIN" --location --insecure --head --silent --connect-timeout "$NOD32MIRROR_DOWNLOAD_TIMEOUT" --retry "$NOD32MIRROR_DOWNLOAD_TRIES" --user-agent "$NOD32MIRROR_USERAGENT" --user "$username:$password" "$uri");
  } || {
    network_tool_enabled "$NOD32MIRROR_WGET_BIN" && {
      headers=$("$NOD32MIRROR_WGET_BIN" --quiet --server-response --no-use-server-timestamps --no-check-certificate --spider --connect-timeout="$NOD32MIRROR_DOWNLOAD_TIMEOUT" --tries="$NOD32MIRROR_DOWNLOAD_TRIES" --user-agent="$NOD32MIRROR_USERAGENT" --http-user="$username" --http-password="$password" "$uri" 2>&1);
    };
  };
  echo "$headers";
}

function network_get_content() {
  local uri=$1;      # Request URI (string)
  local username=$2; # Auth username (string)
  local password=$3; # Auth password (string)
  local content='';
  network_tool_enabled "$NOD32MIRROR_CURL_BIN" && {
    content=$("$NOD32MIRROR_CURL_BIN" --location --insecure --silent --connect-timeout "$NOD32MIRROR_DOWNLOAD_TIMEOUT" --retry "$NOD32MIRROR_DOWNLOAD_TRIES" --user-agent "$NOD32MIRROR_USERAGENT" --user "$username:$password" "$uri");
  } || {
    network_tool_enabled "$NOD32MIRROR_WGET_BIN" && {
      content=$("$NOD32MIRROR_WGET_BIN" --quiet -O - --content-on-error --no-use-server-timestamps --no-check-certificate --connect-timeout="$NOD32MIRROR_DOWNLOAD_TIMEOUT" --tries="$NOD32MIRROR_DOWNLOAD_TRIES" --user-agent="$NOD32MIRROR_USERAGENT" --http-user="$username" --http-password="$password" "$uri" 2>&1);
    };
  };
  echo "$content";
}

function network_download_file() {
  local uri=$1;           # Request URI (string)
  local username=$2;      # Auth username (string)
  local password=$3;      # Auth password (string)
  local save_filepath=$4; # Path for saving file (string)
  [[ -z $uri ]] && return 1;
  [[ -z $save_filepath ]] && return 1;
  local save_filedirpath=$(fs_get_file_directory "$save_filepath");
  [ ! -d "$save_filedirpath" ] && {
    fs_create_directory "$save_filedirpath" || return 2;
  };
  network_tool_enabled "$NOD32MIRROR_CURL_BIN" && {
    "$NOD32MIRROR_CURL_BIN" --location --fail --insecure --silent --connect-timeout "$NOD32MIRROR_DOWNLOAD_TIMEOUT" --retry "$NOD32MIRROR_DOWNLOAD_TRIES" --user-agent "$NOD32MIRROR_USERAGENT" --user "$username:$password" -o "$save_filepath" "$uri" 1>/dev/null 2>&1;
  } || {
    network_tool_enabled "$NOD32MIRROR_WGET_BIN" && {
      "$NOD32MIRROR_WGET_BIN" --quiet --no-check-certificate --no-use-server-timestamps --connect-timeout="$NOD32MIRROR_DOWNLOAD_TIMEOUT" --tries="$NOD32MIRROR_DOWNLOAD_TRIES" --user-agent="$NOD32MIRROR_USERAGENT" --http-user="$username" --http-password="$password" -O "$save_filepath" "$uri" 1>/dev/null 2>&1;
    };
  };
  [ $? -eq 0 ] && return 0 || return 1;
}

# Return codes description:
#   101 : File already exists (downloading skipped)
#   100 : File downloaded successful
#   12  : File not found on remote server (HTTP error 404)
#   10  : Unknown error
#   1   : Parameters / execute error
# Example of usage:
#   network_sync_remote_file $NOD32MIRROR_TEST_URI 'EAV-0160162254' 'hb2kcjv9fn' $NOD32MIRROR_MIRROR_DIR;
#   case $? in
#     101) ui_message 'notice' 'File skipped' "$NOD32MIRROR_TEST_URI";;
#     100) ui_message 'info'   'File downloaded successful' "$NOD32MIRROR_TEST_URI";;
#     12)  ui_message 'error'  'File not found (code 404) on remote server' "$NOD32MIRROR_TEST_URI";;
#     *)   ui_message 'error'  'Downloading file error' "$NOD32MIRROR_TEST_URI";;
#   esac;

function network_sync_remote_file() {
  local uri=$1;              # Request URI (string)
  local username=$2;         # Auth username (string)
  local password=$3;         # Auth password (string)
  local target_directory=$4; # Path to directory with outdated file (string)
  local result='';
  local speedlimit='';
  [[ -z "$uri" ]] && return 1;
  [[ -z "$target_directory" ]] && return 1;
  fs_create_directory "$target_directory" && {
    network_tool_enabled "$NOD32MIRROR_CURL_BIN" && {
      local uri_filename=${uri##*/}; # Extract filename from URI string
      [[ $NOD32MIRROR_DOWNLOAD_SPEED_LIMIT -ne 0 ]] && {
        speedlimit=" --limit-rate $NOD32MIRROR_DOWNLOAD_SPEED_LIMIT""k ";
      }
      [[ $NOD32MIRROR_DOWNLOAD_DELAY -ne 0 ]] && sleep $NOD32MIRROR_DOWNLOAD_DELAY;
      result=$("$NOD32MIRROR_CURL_BIN" --fail --location --insecure --verbose --connect-timeout "$NOD32MIRROR_DOWNLOAD_TIMEOUT" --retry "$NOD32MIRROR_DOWNLOAD_TRIES" --user-agent "$NOD32MIRROR_USERAGENT" --user "$username:$password" $speedlimit --time-cond "$target_directory/$uri_filename" --output "$target_directory/$uri_filename" "$uri" 2>&1);
      local debug_data=$(head -n 65 <<< "$result");
      ui_message 'debug' 'cURL result' "$debug_data";
      case "$result" in
        *[Ii]s\ not\ new\ enough*) return 101;;
        *HTTP\ 304\ [Rr][Ee][Ss][Pp][Oo]*) return 101;;
        *\[[Dd]ata\ not\ show*) return 100;;
        *404\ [Nn]ot\ [Ff]ound*) return 12;;
        *) return 10;;
      esac;
      return 0;
    } || {
      network_tool_enabled "$NOD32MIRROR_WGET_BIN" && {
        [[ $NOD32MIRROR_DOWNLOAD_SPEED_LIMIT -ne 0 ]] && {
          speedlimit=" --limit-rate=$NOD32MIRROR_DOWNLOAD_SPEED_LIMIT""k ";
        }
        [[ $NOD32MIRROR_DOWNLOAD_DELAY -ne 0 ]] && sleep $NOD32MIRROR_DOWNLOAD_DELAY;
        result=$("$NOD32MIRROR_WGET_BIN" --verbose --debug --cache=off --timestamping --no-use-server-timestamps --user-agent="$NOD32MIRROR_USERAGENT" --connect-timeout="$NOD32MIRROR_DOWNLOAD_TIMEOUT" --tries="$NOD32MIRROR_DOWNLOAD_TRIES" --http-user="$username" --http-password="$password" $speedlimit --directory-prefix="$target_directory" "$uri" 2>&1);
        local debug_data=$(head -n 90 <<< "$result");
        ui_message 'debug' 'Wget result' "$debug_data";
        case "$result" in
          *[Nn]ot\ retrieving*) return 101;;
          *[Oo]mitting\ download*) return 101;;
          *[Nn]ot\ modified\ on\ server*) return 101;;
          *[Ss]erver\ ignored*)  return 101;;
          *[Ss]aved*) return 100;;
          *ERROR\ 404*) return 12;;
          *) return 10;;
        esac;
      };
    };
  };
  return 1;
}

function network_headers_get_http_code() {
  local headers=$1; # Headers strings (string)
  echo $(echo "$headers" | grep 'HTTP\/' | tail -n 1 | sed -e 's/^[ \t]*//' | cut -d' ' -f 2 2>/dev/null);
}
