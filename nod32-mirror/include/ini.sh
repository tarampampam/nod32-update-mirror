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

function ini_get_all_sections_names() {
  local input_file=$1;   # Path to input file (string)
  local exclude_list=$2; # Exclude sections list, separated by spaces (string)
  local include_list=$3; # Include sections list, separated by spaces (string)
  [ -f "$input_file" ] && {
    local sections_names=$(sed -n 's/^\[\(.*\)\]/\1/p' $input_file | sed -e 's/[^A-Za-z0-9._-]//g');
    local result='';
    local pass=0;
    [[ ! -z "$sections_names" ]] && {
      for section_name in $sections_names; do
        # Set pass = 1 if 'section_name' == exclude list item
        [[ ! -z "$exclude_list" ]] && {
          for exclude_section_name in $exclude_list; do
            [ "$section_name" == "$exclude_section_name" ] && {
              pass=1 && break;
            };
          done;
        };
        # Do not append to result list if pass != 0
        [ "$pass" -eq 0 ] && {
          result="$result $section_name"
        };
        # Drop pass flag
        pass=0;
      done;
      # Include items from 'include_list'
      [[ ! -z "$include_list" ]] && {
        for include_section_name in $include_list; do
          result="$result $include_section_name";
        done;
      };
      # Make some clear
      result="${result#"${result%%[![:space:]]*}"}"; # Remove leading whitespace characters
      result="${result%"${result##*[![:space:]]}"}"; # Remove trailing whitespace characters
    };
    echo "$result" && return 0;
  };
  return 1;
}

function ini_get_section_content() {
  local input_file=$1;   # Path to input file (string)
  local section_name=$2; # Section name (string)
  [ -f "$input_file" ] && {
    local content=$(sed -n '/^\['$section_name'\]/,/^\[/p' $input_file | sed -e '/^\[/d' | sed -e '/^$/d');
    [[ ! -z "$content" ]] && {
      echo "$content" && return 0;
    };
  };
  return 1;
}

function ini_get_value_by_key() {
  local section_content=$1; # Section content (string)
  local key_name=$2;        # Key name (string)
  if [[ ! -z "$section_content" ]] && [[ ! -z "$key_name" ]]; then
    local value=$(sed -n '/^'$key_name'=\(.*\)$/s//\1/p' <<< "$section_content" | tr -d "\r" | tr -d "\n");
    [[ ! -z "$value" ]] && {
      echo "$value" && return 0;
    };
  fi;
  return 1;
}

