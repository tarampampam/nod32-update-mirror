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

[[ -z $NOD32MIRROR_LOG_PATH ]] && export NOD32MIRROR_LOG_PATH='';

function logger_enabled() {
  [[ ! -z "$NOD32MIRROR_LOG_PATH" ]] && return 0 || return 1;
}

function logger_get_logfile_path() {
  logger_enabled && {
    [ -d "$NOD32MIRROR_LOG_PATH" ] && {
      echo "$NOD32MIRROR_LOG_PATH/nod32mirror.log"; 
    } || {
      echo "$NOD32MIRROR_LOG_PATH"; 
    };
    return 0; 
  };
  return 1;
}

function logger_writeable() {
  logger_enabled && {
    local logfile_filepath=$(logger_get_logfile_path);
    local logfile_directory=$(fs_get_file_directory "$logfile_filepath");
    [ ! -d "$logfile_directory" ] && fs_create_directory "$logfile_directory" 2>/dev/null;
    [ ! -f "$logfile_filepath" ] && touch "$logfile_filepath" 2>/dev/null;
    if [ -f "$logfile_filepath" ] && [ -w "$logfile_filepath" ]; then
      return 0;
    fi;
  };
  return 1;
}

function logger_write() {
  local level=$1; # Log message level (string)
  local text=$2;  # Log message text (string)
  local extra=$3; # Log message additional text (string)
  [ "$#" -eq 1 ] && {
    text=$1;
    level='info';
  };
  [[ ! -z "$extra" ]] && {
    text="$text ($extra)";
  };
  if logger_enabled && logger_writeable; then
    # Disable logging debug messages if debug mode is not enabled
    if ! debugmode_enabled && [[ "$level" == 'debug' ]]; then
      return 0;
    fi;
    local text_out='';
    local time_stamp=$(date +%Y-%m-%d/%H:%M:%S);
    case $level in
      'error')  text_out="[$time_stamp] [Error] $text";;
      'fatal')  text_out="[$time_stamp] [FATAL ERROR] $text";;
      'notice') text_out="[$time_stamp] [Notice] $text";;
      'debug')  text_out="[$time_stamp] [Debug] $text";;
      *)        text_out="[$time_stamp] [Info] $text";;
    esac;
    # Remove color codes (special characters)
    text_out=$(sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" <<< "$text_out");
    echo "$text_out" >> "$(logger_get_logfile_path)" && return 0;
  fi;
  return 1;
}