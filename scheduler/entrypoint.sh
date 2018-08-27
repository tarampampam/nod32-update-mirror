#!/usr/bin/env bash

SCHEDULE_COMMAND="${*:-echo 'scheduler ticked'}";
FIRST_START_DELAY="${FIRST_START_DELAY:-1}";
SCHEDULE_PERIOD="${SCHEDULE_PERIOD:-5}";
START_BEFORE_LOOP="${START_BEFORE_LOOP:-true}";
WRITE_NOD32MIRROR_CONFIG_PATH="${WRITE_NOD32MIRROR_CONFIG_PATH:-/src/conf.d/default.conf}";

STDOUT="${STDOUT:-/proc/1/fd/1}";
STDERR="${STDERR:-/proc/1/fd/2}";

trap "echo SIGHUP" HUP
trap "echo Shutting down; exit" TERM

# Execute command function
function execute_command() {
  ${SCHEDULE_COMMAND} > ${STDOUT} 2> ${STDERR};
}

# Iterate each env variable, witch starts with NOD32*, and dump it into config file
function write_env_into_config_file() {
  while read env_value; do
    key=$(echo "${env_value}" | cut -d '=' -f 1);
    value=$(echo "${env_value}" | cut -d '=' -f 2);

    echo -e "export $key=\"$value\";" >> "$WRITE_NOD32MIRROR_CONFIG_PATH";
  done <<<"$(printenv | grep -e '^NOD32')";
}

write_env_into_config_file;
cat "$WRITE_NOD32MIRROR_CONFIG_PATH";

echo "INFO: Command to execute: \"$SCHEDULE_COMMAND\". Delay between executions: $SCHEDULE_PERIOD";

sleep "$FIRST_START_DELAY";

if [ "$START_BEFORE_LOOP" == "true" ]; then
  execute_command;
fi;

while :; do
  # Do not freeze on LARGE delay
  for (( i=1; i<=$SCHEDULE_PERIOD; i+=1)); do
    sleep 1;
  done;

  execute_command;
done;
