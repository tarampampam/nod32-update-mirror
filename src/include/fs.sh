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

[[ -z $NOD32MIRROR_TEMP_DIR ]]            && export NOD32MIRROR_TEMP_DIR='/tmp';
[[ -z $NOD32MIRROR_TEMP_DIRNAME ]]        && export NOD32MIRROR_TEMP_DIRNAME='nod32tmp';
[[ -z $NOD32MIRROR_TIMESTAMP_FILE_NAME ]] && export NOD32MIRROR_TIMESTAMP_FILE_NAME='';

# Create directory and test 'is writable?'
function fs_create_directory() {
  local path=$1; # Path to directory (string)
  [ ! -d "$path" ] && {
    mkdir -p "$path";
    [ $? -ne 0 ] && return 1;
  };
  [ -w "$path" ] && return 0 || return 1;
}

function fs_get_file_directory() {
  local path=$1; # Path to file (string)
  echo $(dirname "$path");
}

function fs_remove_multiple_slaches() {
  local path=$1; # Any string (string)
  tr -s '/' <<< "$path";
}

function fs_add_last_slash() {
  local path=$1; # Path (string)
  network_uri_add_last_slash "$path"; # Link to another function
}

function fs_remove_last_slash() {
  local path=$1; # Path (string)
  network_uri_remove_last_slash "$path"; # Link to another function
}

function fs_get_temp_directory() {
  echo "$NOD32MIRROR_TEMP_DIR/$NOD32MIRROR_TEMP_DIRNAME";
}

function fs_create_temp_directory() {
  local temp_directory="$(fs_get_temp_directory)";
  [ ! -d "$temp_directory" ] && fs_create_directory "$temp_directory";
  if [ -d "$temp_directory" ] && [ -w "$temp_directory" ]; then
    return 0;
  fi;
  return 1;
}

function fs_get_file_size() {
  local path=$1; # Path to file (string)
  local result=0;
  [ -f "$path" ] && {
    result=$(($(ls -l "$path" | cut -f 5 -d " ")/1024));
  };
  echo "$result";
}

function fs_get_directory_size() {
  local path=$1; # Path to directory (string)
  local result=0;
  if system_application_exists 'du' && [ -d "$path" ]; then
    result=$(du -hs "$mirror_dir" | tail -n 1 | awk '{print $1;}');
  fi;
  echo "$result";
}

function fs_remove_temp_directory() {
  local temp_directory="$(fs_get_temp_directory)";
  [ -d "$temp_directory" ] && {
    rm -Rf "$temp_directory" || return 1;
  };
  return 0;
}

function fs_create_timestamp_file() {
  local directory_path=$1;
  if [[ ! -z "$NOD32MIRROR_TIMESTAMP_FILE_NAME" ]]; then
    [ -d "$directory_path" ] && {
      echo $(date "+%Y-%m-%d %H:%M:%S") > "$directory_path/$NOD32MIRROR_TIMESTAMP_FILE_NAME" && return 0;
    };
  fi;
  return 1;
}