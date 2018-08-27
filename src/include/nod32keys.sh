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

[[ -z $NOD32MIRROR_USE_FREE_KEY ]]          && export NOD32MIRROR_USE_FREE_KEY=0;
[[ -z $NOD32MIRROR_KEYS_DIRECTORY ]]        && export NOD32MIRROR_KEYS_DIRECTORY="$HOME/.nod32keys";
[[ -z $NOD32MIRROR_INVALID_KEYS_FILENAME ]] && export NOD32MIRROR_INVALID_KEYS_FILENAME='invalidkeys.txt';
[[ -z $NOD32MIRROR_VALID_KEYS_FILENAME ]]   && export NOD32MIRROR_VALID_KEYS_FILENAME='validkeys.txt';

function nod32keys_get_new_free_keys() {
  # Format:
  #   ...
  #   EAV-1122334455:aabbccddee
  #   EAV-5544332211:eeddccbbaa
  #   ...
  local page_content='';
  local keys_list='';
  # thx 2 @cryol <https://github.com/cryol> for this:
  page_content="$(network_get_content 'http://tnoduse2.blogspot.ru/')";
  [[ ! -z "$page_content" ]] && {
    keys_list+=$(sed -e 's/<[^>]*>//g' <<< "$page_content" |\
                 awk -F: '/((TRIAL|EAV)-[0-9]+)|(Password: [a-z0-9]+)/ {print $2}' |\
                 sed -e 's/ //g' | tr -d "\r" |\
                 awk '{getline b;printf("%s:%s\n",$0,b)}');
    keys_list+=$'\n';
  };
  # thx 2 @zcooler <https://github.com/zcooler> for this:
  page_content="$(network_get_content 'http://nod325.com/')";
  [[ ! -z "$page_content" ]] && {
    keys_list+=$(sed -e 's/<[^>]*>//g' <<< "$page_content" |\
                 awk -F: '/((TRIAL|EAV)-[0-9]+)|(Password:[a-z0-9]+)/ {print $2}' |\
                 tr -d "\r" |\
                 awk '{getline b;printf("%s:%s\n",$0,b)}');
  };
  [[ ! -z "$keys_list" ]] && {
    echo "$keys_list" && return 0;
  };
  return 1;
}

function nod32keys_get_file_path() {
  local type=$1; # List type
  case $type in
    'valid')   echo "$NOD32MIRROR_KEYS_DIRECTORY/$NOD32MIRROR_VALID_KEYS_FILENAME" && return 0;;
    'invalid') echo "$NOD32MIRROR_KEYS_DIRECTORY/$NOD32MIRROR_INVALID_KEYS_FILENAME" && return 0;;
  esac;
  return 1;
}

function nod32keys_get_all_keys() {
  local type=$1; # List type
  case $type in
    'valid')
      local file_path="$(nod32keys_get_file_path 'valid')";
      [ -f "$file_path" ] && {
        cat "$file_path" && return 0;
      };;
    'invalid')
      local file_path="$(nod32keys_get_file_path 'invalid')";
      [ -f "$file_path" ] && {
        cat "$file_path" && return 0;
      };;
  esac;
  return 1;
}

function nod32keys_file_make_clean() {
  local file_path=$1; # Path to file (string)
  if [ -f "$file_path" ]; then
    local clean=$(awk '!a[$0]++' "$file_path" | sed 's/^ *//; s/ *$//; /^$/d');
    [[ ! -z "$clean" ]] && {
      echo "$clean" > "$file_path";
    }
    return 0
  fi;
  return 1;
}

function nod32keys_add_key() {
  local keys=$1; # Key (or keys list) for storing (string)
  local valid_keys_file="$(nod32keys_get_file_path 'valid')";
  fs_create_directory "$NOD32MIRROR_KEYS_DIRECTORY" && {
    for key in $keys; do
      echo "$key" >> "$valid_keys_file";
    done;
    nod32keys_file_make_clean "$valid_keys_file";
    return 0;
  };
  return 1;
}

function nod32keys_remove_key() {
  local keys=$1; # Key (or keys list) for removing (string)
  local valid_keys_file="$(nod32keys_get_file_path 'valid')";
  local invalid_keys_file="$(nod32keys_get_file_path 'invalid')";
  fs_create_directory "$NOD32MIRROR_KEYS_DIRECTORY" && {
    for key in $keys; do
      echo "$key" >> "$invalid_keys_file";
      [ -f "$valid_keys_file" ] && {
        local result=$(sed "/$key/d" "$valid_keys_file");
        echo "$result" > "$valid_keys_file";
      };
    done;
    nod32keys_file_make_clean "$invalid_keys_file";
    nod32keys_file_make_clean "$valid_keys_file";
    return 0;
  };
  return 1;
}

function nod32keys_key_exists() {
  local list=$1; # List type for a checking
  local key=$2;  # Key for a checking
  local valid_keys_file="$(nod32keys_get_file_path 'valid')";
  local invalid_keys_file="$(nod32keys_get_file_path 'invalid')";
  case $list in
    'valid')
      [ -f "$valid_keys_file" ] && {
        grep -Fq "$key" "$valid_keys_file" && return 0;
      };;
    'invalid')
      [ -f "$invalid_keys_file" ] && {
        grep -Fq "$key" "$invalid_keys_file" && return 0;
      };;
  esac;
  return 1;
}

function nod32keys_update_keys() {
  local valid_keys_file="$(nod32keys_get_file_path 'valid')";
  ui_message 'info' 'Requesting for a new free keys..';
  local new_free_keys=$(nod32keys_get_new_free_keys);
  [[ ! -z "$new_free_keys" ]] && {
    ui_message 'info' "Getting new keys and save valid in \"$valid_keys_file\"..";
    while read line; do
      local username=${line%%:*};
      local password=${line#*:};
      if [[ ! -z "$username" ]] && [[ ! -z "$password" ]]; then
        ui_message 'info' "Checking key $username:$(ui_mask_string $password).. " '' 'no_newline';
        if nod32_key_valid_test "$username" "$password"; then
          if nod32keys_key_exists 'valid' "$username"; then
            echo -ne " $(ui_style 'skipped' 'yellow')";
          else
            nod32keys_add_key "$username:$password" && echo -ne "+$(ui_style 'added' 'green')";
          fi;
        else
          echo -ne "-$(ui_style 'invalid' 'red')";
        fi;
        echo;
      else
        ui_message 'error' "Error while reading key \"$username:$password\"";
      fi;
    done <<< "$new_free_keys";
  } || {
    ui_message 'error' 'Cannot get new free keys :(';
  };
}

function nod32keys_remove_invalid_keys() {
  local valid_keys_file="$(nod32keys_get_file_path 'valid')";
  if [ -f "$valid_keys_file" ]; then
    local original_content="$(nod32keys_get_all_keys 'valid')";
    ui_message 'debug' 'Valid keys content is' "$original_content";
    if [[ ! -z "$original_content" ]]; then
      local lines_counter=0;
      ui_message 'info' 'Removing invalid keys..';
      while read -r line; do
        lines_counter=$((lines_counter+1));
        local username=${line%%:*};
        local password=${line#*:};
        if [[ ! -z "$username" ]] && [[ ! -z "$password" ]]; then
          ui_message 'info' "Checking key $username:$(ui_mask_string $password).. " '' 'no_newline';
          if nod32_key_valid_test "$username" "$password"; then
            echo -ne " $(ui_style 'leaved' 'green')";
          else
            echo -ne "-$(ui_style 'removed' 'red')";
            nod32keys_remove_key "$username:$password";
          fi;
          echo;
        else
          ui_message 'error' "Error while reading \"$valid_keys_file\" on line $lines_counter";
          ui_message 'debug' 'Content' "$original_content";
        fi;
      done <<< "$original_content";
    fi;
  else
    ui_message 'debug' 'Removeing invalid keys failed: valid keys file not found';
  fi;
}

function nod32keys_get_random_key() {
  local valid_keys_file="$(nod32keys_get_file_path 'valid')";
  if [ -f "$valid_keys_file" ]; then
    local lines_count=$(wc -l < "$valid_keys_file");
    [ $lines_count -le 0 ] && lines_count=1;
    local random_key=$(head -$((${RANDOM} % $lines_count + 1)) "$valid_keys_file" | tail -n 1);
    local username=${random_key%%:*};
    local password=${random_key#*:};
    if [[ ! -z "$username" ]] && [[ ! -z "$password" ]]; then
      if nod32_key_valid_test "$username" "$password"; then
        echo "$username:$password" && return 0;
      else
        nod32keys_remove_key "$username:$password" && return 1;
      fi;
    else
      return 1;
    fi;
  fi;
  return 1;
}

function nod32keys_get_valid_key() {
  local random_key="$(nod32keys_get_random_key | tail -n 1)";
  ui_message 'debug' 'Returned random key is' "$random_key";
  if [[ ! -z "$random_key" ]]; then
    echo "$random_key" && return 0;
  else
    nod32keys_remove_invalid_keys;
    nod32keys_update_keys;
    random_key="$(nod32keys_get_random_key | tail -n 1)";
    ui_message 'debug' 'Returned random key is' "$random_key";
    [[ ! -z "$random_key" ]] && {
      echo "$random_key" && return 0;
    }
  fi;
  return 1;
}