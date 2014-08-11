#!/bin/bash

## @author    Samoylov Nikolay
## @project   Get NOD32 key
## @copyright 2014 <samoylovnn@gmail.com>
## @github    https://github.com/tarampampam/nod32-update-mirror/
## @version   0.1.1
##
## @depends   curl, sed, awk, tr, wc, head, basename

# *****************************************************************************
# ***                               Config                                   **
# *****************************************************************************

WORK_DIR="$HOME/.nod32keys/";
VALID_KEYS=$WORK_DIR"validkeys.txt";
INVALID_KEYS=$WORK_DIR"invalidkeys.txt";
LOGFILE=$WORK_DIR"nod32keys.log";

# *****************************************************************************
# ***                            END Config                                  **
# *****************************************************************************

## Switch output language to English (DO NOT CHANGE THIS)
export LC_ALL=C;

## Init global variables
KEY_FOUND=false;

cRed='\e[1;31m'; cGreen='\e[0;32m'; cNone='\e[0m'; cYel='\e[1;33m';
cBlue='\e[1;34m'; cGray='\e[1;30m';

## Helpers Functions ##########################################################

## Show log message in console
logmessage() {
  ## $1 = (not required) '-n' flag for echo output
  ## $2 = message to output

  flag=''; outtext='';
  if [ "$1" == "-n" ]; then
    flag="-n "; outtext=$2;
  else
    outtext=$1;
  fi

  echo -e $flag[$(date +%H:%M:%S)] "$outtext";
}

## Write log file (if filename setted)
writeLog() {
  if [ ! -z "$LOGFILE" ]; then
    echo [$(date +%Y-%m-%d/%H:%M:%S)] "$1" >> "$LOGFILE";
  fi
}

## Check - Login and Pass is valid or not?
checkKey() {
  ## $1 = (not required) '-n' flag for echo output
  ## $2 = Login for checking
  ## $3 = Password for checking
  
  local USERAGENT="ESS Update (Windows; U; 32bit; VDB $((RD%15000+10000)); \
BPC $((RD%2+6)).0.$((RD%100+500)).0; OS: 5.1.2600 SP 3.0 NT; CH 1.1; \
LNG 1049; x32c; APP eavbe; BEO 1; ASP 0.10; FW 0.0; PX 0; PUA 0; RA 0)";
  
  local UpdServer='update.eset.com';
  local TestPath='/v3-rel-sta/mod_000_loader_1072/em000_32_l0.nup';
  local flag='' Login='' Pass='';
  if [ "$1" == "-n" ]; then
    flag="-en"; Login=$2; Pass=$3;
  else
    flag="-e"; Login=$1; Pass=$2;
  fi
  
  ## Wait 1..3 sec before making request
  sleep $(((RANDOM%3)+1))s;
  
  headers=$(curl --user-agent "$USERAGENT" \
    --user $Login:$Pass \
    -Is \
    'http://'$UpdServer''$TestPath);
  code=$(echo \"$headers\" | head -n 1 | cut -d' ' -f 2);
  
  if [ "$code" == "200" ] || [ "$code" == "304" ]; then
    return 0;
  else
    return 1;
  fi
}

## Getting new keys by pirates
getKeys() {
  local keysList='';
  ## Format:
  ##  TRIAL-0118291735:hsnu26k7hu
  ##  TRIAL-0118393856:n98nk6sm6s
  
  #thx @zcooler <https://github.com/zcooler> for this
  keysList+=$(curl -s http://nod325.com/ |\
    sed -e 's/<[^>]*>//g' |\
    awk -F: '/((TRIAL|EAV)-[0-9]+)|(Password:[a-z0-9]+)/ {print $2}' |\
    tr -d "\r" |\
    awk '{getline b;printf("%s:%s\n",$0,b)}');
  keysList+=$(curl -s http://www.nod327.net/ |\
    sed -e 's/<[^>]*>//g' |\
    awk -F: '/((TRIAL|EAV)-[0-9]+)|(nod32key:[a-z0-9]+)/ {print $2}' |\
    tr -d "\r" |\
    awk '{getline b;printf("\n%s:%s",$0,b)}');
  echo "$keysList";
}

## Remove empty lines from $1 file, and remove spaces at begin and end
removeEmptyLinesInFile() {
  ## $1 = file name (with path)
  if [ -f $1 ]; then
    echo "$(sed 's/^ *//; s/ *$//; /^$/d' $1)" > $1;
  fi
}

## Remove line containing $1 from file $2
removeKeyFromFile() {
  ## $1 = substring for search
  ## $2 = file name (with path)
  if [ -f "$2" ]; then
    ## Save invalid key (if path is setted)
    if [ ! -z "$INVALID_KEYS" ] && [ "$2" == "$VALID_KEYS" ]; then
      echo "$1" >> "$INVALID_KEYS";
    fi
    local result=$(sed "/$1/d" $2);
    echo "$result" > $2;
  fi
}

echoKey() {
  ## $1 = key for output
  KEY_FOUND=true;
  #logmessage "Hell yeah, lucky key for you is:";
  echo -e "MIT License, ${cRed}use for educational or information purposes only!${cNone}";
  echo "";
  echo $1;
}

## Get new keys by getKeys() and store new+valid keys in file
getNewKeysAndSave() {
  logmessage "${cYel}Getting new keys and save valid in '$VALID_KEYS'${cNone}";
  writeLog "Getting new keys and save valid in '$VALID_KEYS'";
  ## Get list of warez keys, and read result 'line by line'
  while read line; do
    ## Get user:pass from line
    local Username=${line%%:*} Password=${line#*:};
    ## Check values for != empty
    if [ ! -z $Username ] && [ ! -z $Password ]; then
      logmessage -n "Checking key ${cYel}$Username${cNone}:$Password.. ";
      if checkKey -n $Username $Password; then
        ## If tested key valid and not exists in keys file - add it (or skip)
        if [ -f "$VALID_KEYS" ] && grep -Fq $Username "$VALID_KEYS"; then
          echo -ne "  ${cYel}skipped${cNone}";
        else
          echo "$Username:$Password" >> "$VALID_KEYS";
          echo -ne " +${cGreen}added${cNone}";
        fi
      else
        echo -ne " -${cRed}invalid${cNone}";
      fi
      echo "";
    else
      logmessage "${cRed}Error${cNone} reading new key ('${cRed}$Username${cNone}':'${cRed}$Password${cNone}')";
    fi
  done <<< "$(getKeys)"; removeEmptyLinesInFile "$VALID_KEYS";
}

removeInvalidKeys() {
  if [ -f "$VALID_KEYS" ]; then
    ## Make a copy of file..
    cp -f "$VALID_KEYS" "$VALID_KEYS.lock";
    local lineCounter=0;
    ## ..and work with it
    logmessage "${cYel}Removing invalid keys from '$VALID_KEYS'${cNone}";
    writeLog "Removing invalid keys from '$VALID_KEYS'";
    while read line; do
      lineCounter=$((lineCounter+1));
      ## Get user:pass from line
      local Username=${line%%:*} Password=${line#*:};
      if [ ! -z $Username ] && [ ! -z $Password ]; then
        logmessage -n "Checking key before erasing ${cYel}$Username${cNone}:$Password.. ";
        if ! checkKey -n $Username $Password; then
          echo -ne " -${cRed}remove${cNone}";
          removeKeyFromFile "$Username:$Password" "$VALID_KEYS";
        else
          echo -ne "  ${cYel}skipped${cNone}";
        fi
        echo "";
      else
        logmessage "Error reading '${cYel}$VALID_KEYS${cNone}' - damn line \"${cYel}$lineCounter${cNone}\" is broken";
      fi;
    done < "$VALID_KEYS.lock"; rm -f "$VALID_KEYS.lock";
    removeEmptyLinesInFile "$VALID_KEYS";
  fi
}

testRandomKey() {
  ## Get random key..
  #local randomKey=$(sort -R "$VALID_KEYS" | head --lines=1);
  local randomKey=$(head -$((${RANDOM} % `wc -l < "$VALID_KEYS"` + 1)) "$VALID_KEYS" | tail -1);
  local Username=${randomKey%%:*} Password=${randomKey#*:};
  ## ..and if some error catched, we..
  if [ -z "$randomKey" ] || [ -z $Username ] || [ -z $Password ]; then
    ## .. return error code
    return 1; # err
  else
    if checkKey -n $Username $Password; then
      echo "$Username:$Password";
      return 0; # NO err
    else
      removeKeyFromFile "$Username:$Password" "$VALID_KEYS";
      removeEmptyLinesInFile "$VALID_KEYS";
      return 1; # err
    fi
  fi
}

## Run script with params #####################################################

## --help
if [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$1" == "-H" ]; then
  me=$(basename $0);
  echo -e "This script get valid Nod32 key using pirates web-sites. Now we supports:\n";
  echo -e "  ${cYel}http://nod325.com/${cNone}";
  echo -e "  ${cYel}http://www.nod327.net/${cNone}\n";
  echo -e "You can run with parameters:";
  echo -e "  ${cYel}-u, --update${cNone}        Get new valid keys and write to $VALID_KEYS";
  echo -e "  ${cYel}-r, --remove${cNone}        Remove invalid keys from $VALID_KEYS";
  echo -e "  ${cYel}-h, --help${cNone}          Show this help\n\n";
  echo -e "Valid key (or \"error\") will printed in ${cYel}LAST OUTPUT LINE${cNone} (format 'user:password')";
  echo -e "                                       ${cBlue}^^^^^^^^^^^^^^^^${cNone}";
  echo -e "You can use: \"${cYel}$(basename $0) | tail -n 1${cNone}\" for getting key only\n\n";
  echo -e "Last update: 12.08.2014, MIT License, ${cRed}use for educational or information";
  echo -e "  purposes only!${cNone}";
  exit 0;
fi
## --update
if [ "$1" == "-u" ] || [ "$1" == "--update" ]; then getNewKeysAndSave; exit 0; fi
## --remove
if [ "$1" == "-r" ] || [ "$1" == "--remove" ]; then removeInvalidKeys; exit 0; fi

## Begin work #################################################################

## Create patches
validKeysPath=${VALID_KEYS%/*};
if [ ! -z "$validKeysPath" ] && [ ! -d "$validKeysPath" ]; then mkdir -p "$validKeysPath"; fi
invalidKeysPath=${INVALID_KEYS%/*};
if [ ! -z "$invalidKeysPath" ] && [ ! -d "$invalidKeysPath" ]; then mkdir -p "$invalidKeysPath"; fi
logfilePath=${LOGFILE%/*};
if [ ! -z "$logfilePath" ] && [ ! -d "$logfilePath" ]; then mkdir -p "$logfilePath"; fi

## If keys file not exists - get new keys and save them
if [ ! -f "$VALID_KEYS" ]; then
  getNewKeysAndSave;
fi

## Double file exists check (if getNewKeysAndSave() failed)
if [ ! -f "$VALID_KEYS" ]; then
  logmessage 'File ${cRed}$VALID_KEYS${cNone} not created. Exit';
  exit 1;
fi

## Getting random key and..
randomKey=$(testRandomKey);
## ..check him

if [ -z "$randomKey" ]; then
  logmessage "Getted random key from $VALID_KEYS is invalid";
  ## If he not not valid, we remove all invalid keys from file
  removeInvalidKeys;
  ## Then again get random key from file
  randomKey=$(testRandomKey);
  ## And if now random key invalid (or empty)
  if [ -z "$randomKey" ]; then
    logmessage "Getted random key from $VALID_KEYS again is invalid";
    ## Get new files from web
    getNewKeysAndSave;
    ## And make 3rd test
    randomKey=$(testRandomKey);
    if [ -z "$randomKey" ]; then
      logmessage "We attempted get keys locally; remove broken keys and get local key again;
           get new keys from web - and ${cRed}failed${cNone}. You are lucky man :) Check this
           script source or write to author.";
    else
      ## After getNewKeysAndSave()
      echoKey $randomKey;
      writeLog "Return key "$randomKey" from from web";
    fi
  else
    ## After removeInvalidKeys()
    echoKey $randomKey;
    writeLog "Return key "$randomKey" from local file after remove all invalid keys";
  fi
else
  ## After 1st randomKey()
  echoKey $randomKey;
  writeLog "Return key "$randomKey" from local file";
fi


# If key not found (not setted ) - write 'error'
if [ ! "$KEY_FOUND" = true ] ; then
  echoKey "error";
  writeLog "Fatal error - key not returned";
  exit 1;
fi
exit 0;

