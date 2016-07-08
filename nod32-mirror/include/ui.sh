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

[[ -z $NOD32MIRROR_COLOR_OUTPUT ]] && export NOD32MIRROR_COLOR_OUTPUT=1;

# Replace all characters in a string
function ui_mask_string() {
  local string=$1; # User input (string)
  local masked='';
  debugmode_enabled && { # Disable hiding in debug mode
    masked="$string";
  } || {
    masked=$(sed 's/./\*/g' <<< "$string");
  };
  echo "$masked";
}

# Style user text
function ui_style() {
  local user_text=$1;   # User input text (string)
  local user_styles=$2; # Text color/styles, separated by spaces (string)
  declare -A styles;
  styles['white']='\033[0;37m';  # White text color
  styles['red']='\033[0;31m';    # Red text color
  styles['green']='\033[0;32m';  # Green text color
  styles['yellow']='\033[0;33m'; # Yellow text color
  styles['blue']='\033[0;34m';   # Blue text color
  styles['gray']='\033[1;30m';   # Gray text color
  styles['bold']='\033[1m';      # Bold text style
  styles['underline']='\033[4m'; # Underlined text style
  styles['reverse']='\033[7m';   # Reversed colors text style
  styles['none']='\033[0m';      # Reset text styles
  local text_styles='';
  for style in $user_styles; do
    if [[ ! -z "$style" ]] && [[ ! -z "${styles[$style]}" ]]; then
      text_styles="$text_styles${styles[$style]}";
    fi;
  done;
  # Disable any text styles if some variable is setted
  [ "$NOD32MIRROR_COLOR_OUTPUT" -ne "1" ] && {
    text_styles='';
  };
  [ ! -z "$text_styles" ] && {
    echo -e "$text_styles$user_text${styles[none]}";
  } || {
    echo -e "$1";
  };
}

# Show user message
function ui_message() {
  local type=$1;       # Message type (string)
  local text=$2;       # Message text (string)
  local extra=$3;      # Additional text (string)
  local additional=$4; # Additional options
  [ "$#" -eq 1 ] && {
    text=$1;
  };
  # Send message to logger if last is enabled
  if logger_enabled && logger_writeable; then
    if [[ ! "$type" == 'verbose' ]]; then # Except verbose messages
      logger_write "$type" "$text" "$extra";
    fi;
  fi;
  [ ! -z "$extra" ] && {
    local styled_text=$(ui_style "$extra" 'yellow');
    text="$text ($styled_text)";
  };
  # Disable showing debug messages if debug mode is not enabled
  if ! debugmode_enabled && [ "$type" == 'debug' ]; then
    return;
  fi;
  local text_out='';
  local to_stderr=0;
  local now=$(date +%H:%M:%S);
  case $type in
    'error')   text_out="[$(ui_style $now 'red')] $text"; to_stderr=1;;
    'fatal')   text_out="$(ui_style 'Fatal error:' 'red reverse') $text\n"; to_stderr=1;;
    'notice')  text_out="[$(ui_style $now 'blue bold')] $text";;
    'debug')   text_out="$(ui_style '[Debug   ]' 'reverse') $text";;
    'info')    text_out="[$(ui_style $now 'yellow')] $text";;
    'verbose') text_out="[$(ui_style $now 'yellow')] $text";;
    *)         text_out="[$(date +%H:%M:%S)] $text";;
  esac;
  local additional_flags='';
  # Do not output the trailing newline (no_newline/oneline = no newline)
  if [[ "$additional" == 'no_newline' ]] || [[ "$additional" == 'oneline' ]]; then
    debugmode_enabled || {
      additional_flags="$additional_flags -n";
    };
  fi;
  [ $to_stderr -ne 1 ] && {
    echo -e $additional_flags "$text_out";
  } || {
    echo -e $additional_flags "$text_out" 1>&2;
  };
}