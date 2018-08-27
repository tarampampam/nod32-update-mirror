#!/usr/bin/env bash
set -e

# Nginx config file path
NGINX_CONFIG_FILE_PATH="${NGINX_CONFIG_FILE_PATH:-/etc/nginx/nginx.conf}";

# Nginx basic auth settings
NGINX_AUTH_FILE_PATH="${NGINX_AUTH_FILE_PATH:-/etc/nginx/.htpasswd}";
NGINX_AUTH_USERS_AND_PASSWORDS="${NGINX_AUTH_USERS_AND_PASSWORDS:-}";

# Make replaces using pattern in a file. Pattern must looks like: '%ENV_VAR_NAME|default value%', where:
# - 'ENV_VAR_NAME' - Environment variable name for replacing
# - 'default value' - Value for setting, if environment variable was not found (can be empty)
function make_replaces() {
  local FILE_PATH="$1"; # Path to the file (string)

  # Extract lines with variables from config file
  local found_variables=$(grep -oP '%[A-Za-z0-9_]+\|.*?%' "$FILE_PATH");
  #echo -e "DEBUG: Found variables in config file:\n$found_variables"; # for debug

  local name default_value env_value value;

  # Iterate found variables
  while read -r variable; do
    if [[ ! -z "$variable" ]]; then
      name=$(echo "$variable" | sed -n 's^.*%\(.*\)|.*%.*^\1^p');
      default_value=$(echo "$variable" | sed -n 's^.*%.*|\(.*\)%.*^\1^p');
      env_value=$(eval "echo \$${name}");
      value="${env_value:-$default_value}";

      # Make replaces
      if [[ ! -z "$name" ]]; then
        echo "INFO: [$FILE_PATH] Set \"%$name%\" to \"$value\"";

        sed -i "s^%$name|[^%]*%^${value//\&/\\\&}^gi" "$FILE_PATH";
      else
        (>&2 echo "ERROR: Variable named \"$name\" has no default value or invalid.");
      fi;
    fi;
  done <<< "$found_variables";
}

# Setup nginx basic auth settings
if [ "$NGINX_AUTH_USERS_AND_PASSWORDS" != "" ]; then
  # Create empty file for passwords
  [ ! -f "$NGINX_AUTH_FILE_PATH" ] && touch "$NGINX_AUTH_FILE_PATH";

  for single_entry in $(echo "$NGINX_AUTH_USERS_AND_PASSWORDS" | tr [:space:] ' '); do
    username=$(echo "${single_entry}" | cut -d ':' -f 1);
    password=$(echo "${single_entry}" | cut -d ':' -f 2);

    echo "Generate nginx basic auth file: $NGINX_AUTH_FILE_PATH ($username : $password)";
    # Generate entry
    htpasswd -b "$NGINX_AUTH_FILE_PATH" "$username" "$password";
    # Make verification
    htpasswd -vb "$NGINX_AUTH_FILE_PATH" "$username" "$password";
  done;

  echo 'Passwords file content:';
  cat "$NGINX_AUTH_FILE_PATH";

  # Export environment value with nginx settings (function "make_replaces" works with it)
  # Also - you need to escape "^" char for passing into sed
  export NGINX_AUTH_SETTINGS='location ~* \^.+\.nup$ {
    allow all;
    auth_basic "Enter login:password for getting access";
    auth_basic_user_file '"$NGINX_AUTH_FILE_PATH"';
  }';
fi;

# Make main nginx config file replaces
make_replaces "$NGINX_CONFIG_FILE_PATH";
#echo -e "DEBUG: Nginx config file content: $(cat $NGINX_CONFIG_FILE_PATH)"; # for debug

if nginx -t; then
  exec "$@";
else
  echo "Nginx configuration error." && exit 1;
fi;
