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

[[ -z $NOD32MIRROR_SERVER_URI ]]              && export NOD32MIRROR_SERVER_URI='';
[[ -z $NOD32MIRROR_SERVER_USERNAME ]]         && export NOD32MIRROR_SERVER_USERNAME='';
[[ -z $NOD32MIRROR_SERVER_PASSWORD ]]         && export NOD32MIRROR_SERVER_PASSWORD='';
[[ -z $NOD32MIRROR_URI_PATH ]]                && export NOD32MIRROR_URI_PATH='';
[[ -z $NOD32MIRROR_TEST_URI ]]                && export NOD32MIRROR_TEST_URI='';
[[ -z $NOD32MIRROR_PLATFORMS ]]               && export NOD32MIRROR_PLATFORMS='__ALL__';
[[ -z $NOD32MIRROR_TYPES ]]                   && export NOD32MIRROR_TYPES='__ALL__';
[[ -z $NOD32MIRROR_LANGUAGES ]]               && export NOD32MIRROR_LANGUAGES='__ALL__';
[[ -z $NOD32MIRROR_VERSIONS ]]                && export NOD32MIRROR_VERSIONS='pcu 4 5 6 7 8 9 10 11';
[[ -z $NOD32MIRROR_W10UPGRADE_ENABLED ]]      && export NOD32MIRROR_W10UPGRADE_ENABLED=1;
[[ -z $NOD32MIRROR_VERSION_FILE_NAME ]]       && export NOD32MIRROR_VERSION_FILE_NAME='';
[[ -z $NOD32MIRROR_DB_VERSION_SECTION_NAME ]] && export NOD32MIRROR_DB_VERSION_SECTION_NAME='ENGINE2';
[[ -z $NOD32MIRROR_VERSION_FILE_CRLF ]]       && export NOD32MIRROR_VERSION_FILE_CRLF=0;

function nod32_key_valid_test() {
  local username=$1; # Auth username (string)
  local password=$2; # Auth password (string)
  [[ -z $NOD32MIRROR_TEST_URI ]] && {
    ui_message 'error' 'TEST URI is NOT setted. Cannot test key' && return 1;
  };
  local uri="$NOD32MIRROR_TEST_URI";
  ui_message 'debug' "Request headers for a testing key \"$username:$password\".." "$uri";
  local headers=$(network_get_headers "$uri" "$username" "$password");
  ui_message 'debug' 'Response headers:' "$headers";
  [[ ! -z "$headers" ]] && {
    local http_code=$(network_headers_get_http_code "$headers");
    if [[ "$http_code" == "200" ]] || [[ "$http_code" == "304" ]]; then
      return 0;
    fi;
  };
  return 1;
}

function nod32_server_test_available() {
  local uri=$1;      # Server URI (string)
  local username=$2; # Auth username (string)
  local password=$3; # Auth password (string)
  local test_filename='update.ver';
  # Add '/' at the end (if needed)
  local test_uri="$(network_uri_remove_last_slash $uri)/$test_filename";
  ui_message 'debug' 'Sending request for a testing server availability..' "$test_uri";
  local headers=$(network_get_headers "$test_uri" "$username" "$password");
  ui_message 'debug' 'Response headers:' "$headers";
  [[ ! -z "$headers" ]] && {
    local http_code=$(network_headers_get_http_code "$headers");
    if [[ "$http_code" == "200" ]] || [[ "$http_code" == "304" ]]; then
      return 0;
    fi;
  };
  return 1;
}

function nod32_autosetup_working_server() {
  for i in {0..9}; do
    ## Get server settings
    eval test_server=\$\{NOD32MIRROR_SERVER_$i\};
    [[ ! "$test_server" == "" ]] && {
      local uri=$(awk '{print $1;}' <<< "$test_server");
      local username=$(awk '{print $2;}' <<< "$test_server");
      local password=$(awk '{print $3;}' <<< "$test_server");
      local extra="$uri";
      if [[ ! -z "$username" ]] && [[ ! -z "$password" ]]; then
        extra+=" [$username:$(ui_mask_string $password)]";
      fi;
      ui_message 'info' "Checking server ($extra).. " '' 'no_newline';
      nod32_server_test_available "$uri" "$username" "$password" && {
        echo -e "$(ui_style 'Available' 'green')";
        export NOD32MIRROR_SERVER_URI="$uri";
        export NOD32MIRROR_SERVER_USERNAME="$username";
        export NOD32MIRROR_SERVER_PASSWORD="$password";
        return 0 && break; # break here is just for fun
      } || {
        echo -e "$(ui_style 'Is not available' 'red')";
      };
    }
  done;
  return 1;
}

function nod32_mirror_remote_directory() {
  local extra_url_path=$1; # Remote server extra (additional) URL part, ex.: 'v5/' (string)
  if [[ -z "$NOD32MIRROR_SERVER_URI" ]]; then
    ui_message 'error' 'Setup server URI first' && return 1;
  fi;
  if [[ -z "$NOD32MIRROR_MIRROR_DIR" ]]; then
    ui_message 'error' 'Setup target mirror directory first' && return 1;
  fi;
  local uri="$(network_uri_remove_last_slash "$NOD32MIRROR_SERVER_URI")/$extra_url_path";
  local username="$NOD32MIRROR_SERVER_USERNAME";
  local password="$NOD32MIRROR_SERVER_PASSWORD";
  local target_directory=''; # Local directory path, ex.: /home/user/mirror/v5 (string)
  target_directory=$(fs_remove_multiple_slaches "$NOD32MIRROR_MIRROR_DIR/$extra_url_path");
  target_directory=$(fs_remove_last_slash "$target_directory");
  uri="$(network_uri_remove_last_slash $uri)/";
  if fs_create_temp_directory && fs_create_directory "$target_directory"; then
    local versions_file_name='update.ver';
    local temp_directory="$(fs_get_temp_directory)";
    local remote_versions_file_uri="$uri$versions_file_name";
    local local_versions_file_path="$temp_directory/$versions_file_name";
    # Download remote versions file
    ui_message 'notice' "Starting mirroring \"$uri\" -> \"$target_directory\"";
    ui_message 'info' "Download versions file ($remote_versions_file_uri).. " '' 'no_newline';
    network_download_file "$remote_versions_file_uri" "$username" "$password" "$local_versions_file_path" && {
      echo -e "$(ui_style 'Success' 'green')";
      # Make check - versions file packed with RAR, or not?
      [ "$(head -c 3 $local_versions_file_path)" == "Rar" ] && {
        ui_message 'info' 'Versions file packed by RAR, unpacking..' '' 'no_newline';
        if system_application_exists 'unrar'; then
          local achive_name="$versions_file_name.rar";
          (cd "$temp_directory" && mv -f "$versions_file_name" "$achive_name" && $(which unrar) x -y -inul "$achive_name");
          if [ -f "$temp_directory/$achive_name" ] && [ -f "$local_versions_file_path" ]; then
            rm -f "$temp_directory/$achive_name";
            echo -e "$(ui_style ' Success' 'green')";
          fi;
        else
          echo -e "$(ui_style 'Failed' 'red')";
          ui_message 'error' 'Unrar tool is not installed. Skipping.' && return 1;
        fi;
      }
      # Writing new file
      local new_versions_file_path="$target_directory/$versions_file_name";
      local sections_list=$(ini_get_all_sections_names "$local_versions_file_path" 'Expire');
      debugmode_enabled && {
        local sections_count=$(wc -w <<< "$sections_list");
        ui_message 'debug' "Found $sections_count section(s) in $local_versions_file_path";
      };
      local sections_total_counter=0;
      local sections_writed_counter=0;
      local sections_skipped_counter=0;
      local db_version_value='';
      declare -a files_array;
      ui_message 'info' "Parsing & writing new ($new_versions_file_path) versions file " '' 'no_newline';
      echo -ne "$(ui_style '(dots = skipped sections)' 'gray'): ";
      echo -e ";; This mirror created by <github.com/tarampampam/nod32-update-mirror> ver.$NOD32MIRROR_VERSION ;;\n" > "$new_versions_file_path";
      # Walk through all sections
      for section_name in $sections_list; do
        local  section_content=$(ini_get_section_content "$local_versions_file_path" "$section_name");
        local section_platform=$(ini_get_value_by_key "$section_content" 'platform');
        local     section_type=$(ini_get_value_by_key "$section_content" 'type');
        local    section_level=$(ini_get_value_by_key "$section_content" 'level');
        local section_language=$(ini_get_value_by_key "$section_content" 'language');
        local write_section=0;
        local dont_modify_section=0;
        # Try to detect DB version
        if [[ "$section_name" == "$NOD32MIRROR_DB_VERSION_SECTION_NAME" ]]; then
          db_version_value=$(ini_get_value_by_key "$section_content" 'version');
          # Write DB version into file
          if [[ ! -z "$db_version_value" ]] && [[ ! -z "$NOD32MIRROR_VERSION_FILE_NAME" ]]; then
            echo -e "$db_version_value" > "$target_directory/$NOD32MIRROR_VERSION_FILE_NAME";
          fi;
        fi;
        case "$section_name" in
          'HOSTS')
            section_content=";; Ignore HOSTS section";
            dont_modify_section=1;
            write_section=1;
            ;;
          'PCUVER')
            # Program Component Update
            [[ "$NOD32MIRROR_VERSIONS" == *pcu* ]] && {
              local pcu_file_relative_uri=$(fs_remove_multiple_slaches "/$NOD32MIRROR_URI_PATH/pcu/update.ver");
              section_content="file=$pcu_file_relative_uri";
              dont_modify_section=1;
              write_section=1;
            };
            ;;
          *)
            if [[ ! -z "$section_platform" ]]; then
              for settings_platform in $NOD32MIRROR_PLATFORMS; do
                if [[ "$settings_platform" == "$section_platform" ]] || [[ "$NOD32MIRROR_PLATFORMS" == "__ALL__" ]]; then
                  if [[ ! -z "$section_type" ]]; then
                    for settings_type in $NOD32MIRROR_TYPES; do
                      if [[ ! -z "$NOD32MIRROR_W10UPGRADE_ENABLED" ]] && [[ "$section_type" == "w10upgrade" ]]; then
                        continue;
                      fi;
                      if [[ "$settings_type" == "$section_type" ]] || [[ "$NOD32MIRROR_TYPES" == "__ALL__" ]]; then
                        #write_section=1 && break 3;
                        for settings_level in 0 1 2; do
                          if [[ "$settings_level" == "$section_level" ]]; then
                            write_section=1 && break 3;
                          fi;
                        done;
                        for settings_language in $NOD32MIRROR_LANGUAGES; do
                          if [[ "$settings_language" == "$section_language" ]] || [[ "$NOD32MIRROR_LANGUAGES" == "__ALL__" ]]; then
                            write_section=1 && break 3;
                          fi;
                        done;
                      fi;
                    done;
                  fi;
                fi;
              done;
            fi;
            ;;
        esac;
        if [[ $write_section -eq 1 ]]; then
          if [[ $dont_modify_section -ne 1 ]]; then
            local section_file=$(ini_get_value_by_key "$section_content" 'file');
            local filename_only='';
            local file_full_uri='';
            local file_new_relative_uri='';
            if [[ ! -z "$section_file" ]]; then
              filename_only=${section_file##*/};
              if [[ $section_file == *\:\/\/* ]]; then
                # Path is FULL (ex.: http://nod32mirror.com/nod_upd/em002_32_l0.nup). Save value 'as is'
                file_full_uri="$section_file";
              else
                if [[ $section_file == \/* ]]; then
                  # If path with some 'parent directory' (is slash in path) (ex.: /nod_upd/em002_32_l0.nup)
                  local protocol=$(sed -e's,^\(.*://\).*,\1,g' <<< "$NOD32MIRROR_SERVER_URI");
                  local host=$(awk -F/ '{print $3}' <<< "$NOD32MIRROR_SERVER_URI");
                  file_full_uri="$protocol$host$section_file";
                else
                  # If filename ONLY (ex.: em002_32_l0.nup)
                  file_full_uri="$NOD32MIRROR_SERVER_URI$section_file";
                fi;
              fi;
              files_array+=("$file_full_uri");
              file_new_relative_uri=$(fs_remove_multiple_slaches "/$NOD32MIRROR_URI_PATH/$extra_url_path/$filename_only");
            fi;
            sections_writed_counter=$((sections_writed_counter+1));
            ui_message 'debug' "+ Write section \"$section_name\"";
            section_content="${section_content/$section_file/$file_new_relative_uri}";
          fi;
          echo -e "[$section_name]\n$section_content\n" >> "$new_versions_file_path";
          echo -n '#'; # Written
        else
          ui_message 'debug' "- Ignore section \"$section_name\"";
          sections_skipped_counter=$((sections_skipped_counter+1));
          echo -ne "$(ui_style '.' 'gray')"; # Skipped
        fi;
        sections_total_counter=$((sections_total_counter+1));
        #if [[ $sections_total_counter -gt 15 ]]; then break; fi; # TODO: For debug only
      done;
      [[ $NOD32MIRROR_VERSION_FILE_CRLF -eq 1 ]] && {
        sed -i 's/$/\r/' "$new_versions_file_path"; # Convert LF to CRLF (as in original versions file, issue #37)
      }
      echo; ui_message 'debug' "Total processed sections: $sections_total_counter, written: $sections_writed_counter, skipped: $sections_skipped_counter";
      # Download files
      local download_counter=0;
      local download_successful_counter=0;
      local download_skipped_counter=0;
      local download_errors_counter=0;
      local download_total_count=${#files_array[@]};
      for file_uri in ${files_array[*]}; do
        download_counter=$((download_counter+1));
        ui_message 'verbose' "Download file \"$file_uri\" ($download_counter of $download_total_count).. " '' 'no_newline';
        network_sync_remote_file "$file_uri" "$username" "$password" "$target_directory";
        case $? in
          101) echo -e "$(ui_style 'Skipped' 'gray')"; download_skipped_counter=$((download_skipped_counter+1));;
          100) echo -e "$(ui_style 'Success' 'green')"; download_successful_counter=$((download_successful_counter+1));;
          12)  echo -e "$(ui_style 'File not found' 'red')"; download_errors_counter=$((download_errors_counter+1));;
          *)   echo -e "$(ui_style 'Downloading file error' 'red')"; download_errors_counter=$((download_errors_counter+1));;
        esac;
      done;
      ui_message 'notice' "Mirroring \"$uri\" -> \"$target_directory\" $(ui_style 'complete!' 'green')";
      ui_message 'info' "Successfully downloaded files: $(ui_style $download_successful_counter 'green'), skipped: $(ui_style $download_skipped_counter 'yellow'), with errors: $(ui_style $download_errors_counter 'red')";
      return 0;
    } || {
      echo -e "$(ui_style 'Failed' 'red')" && return 1;
    };
  else
    ui_message 'fatal' 'Cannot create target or temp directory' "$target_directory" && return 1;
  fi;
  return 1;
}
