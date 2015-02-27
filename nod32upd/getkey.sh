#!/bin/bash

## @author    Samoylov Nikolay
## @project   Get NOD32 key
## @copyright 2015 <github.com/tarampampam>
## @license   MIT <http://opensource.org/licenses/MIT>
## @github    https://github.com/tarampampam/nod32-update-mirror/
## @version   Look in 'settings.cfg'
##
## @depends   curl, sed, awk, tr, wc, head, basename, iconv


# *****************************************************************************
# ***                               Config                                   **
# *****************************************************************************

## Path to settings file
PathToSettingsFile=$(dirname $0)'/settings.cfg';

# *****************************************************************************
# ***                            END Config                                  **
# *****************************************************************************

## Load setting from file
if [ -f "$PathToSettingsFile" ]; then source $PathToSettingsFile; else
  echo -e "\e[1;31mCannot load settings ('"$PathToSettingsFile"') file. Exit\e[0m"; exit 1;
fi;

## Init global variables
KEY_FOUND=false;

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
  fi;

  echo -e $flag[$(date +%H:%M:%S)] "$outtext";
}

## Write log file (if filename setted)
writeLog() {
  if [ ! -z "$LOGFILE" ]; then
    echo "[$(date +%Y-%m-%d/%H:%M:%S)] [$(basename $0)] - $1" >> "$LOGFILE";
  fi;
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
  local TestPath='/v3-rel-sta/mod_000_loader_1082/em000_32_l0.nup';
  local flag='' Login='' Pass='';
  if [ "$1" == "-n" ]; then
    flag="-en"; Login=$2; Pass=$3;
  else
    flag="-e"; Login=$1; Pass=$2;
  fi;
  
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
  fi;
}

## Getting new keys by pirates
getKeys() {
  local keysList='';
  ## Format:
  ##  TRIAL-0118291735:hsnu26k7hu
  ##  TRIAL-0118393856:n98nk6sm6s
  
  for URL in ${HTML_list[*]}; do
	  
	  ## TODO:
	  ## условие проверки на кодировку страницы в WINDOWS-1251
	  #[ "$(curl -s $URL | grep '<meta.*charset=' | grep -i 'win*')" ] && WIN=1
	  
	  keysList+="$URL";
	  keysList+=$(curl -s $URL |\
		  # нужно еще искать кодировку и в такую кодировку менять iconv
		  iconv -c -f WINDOWS-1251 -t UTF-8 |\
		  #sed -e 's/<[^>]*>//g' |\ - поменял из скрипта с форума asus
		  sed 's/<[^<>]*>/\n/g;s/ *//g' |\
		  # замена локального языка на eng
		  sed 's/Пароль:/Password:/I' |\
		  awk -F: '/((TRIAL|EAV)-[0-9]+)|(Password:[a-z0-9]+)/ {print $2}' |\
		  tr -d "\r" |\
		  awk '{getline b;printf("\n%s:%s",$0,b)}');
	  keysList+="
	  ";
  
  done;

  echo "$keysList";
}

## Remove empty lines from $1 file, and remove spaces at begin and end
removeEmptyLinesInFile() {
  ## $1 = file name (with path)
  if [ -f $1 ]; then
    echo "$(sed 's/^ *//; s/ *$//; /^$/d' $1)" > $1;
  fi;
}

## Remove line containing $1 from file $2
removeKeyFromFile() {
  ## $1 = substring for search
  ## $2 = file name (with path)
  if [ -f "$2" ]; then
    ## Save invalid key (if path is setted)
    if [ ! -z "$invalidKeysFile" ] && [ "$2" == "$validKeysFile" ]; then
      echo "$1" >> "$invalidKeysFile";
    fi;
    local result=$(sed "/$1/d" $2);
    echo "$result" > $2;
    writeLog "Remove key \"$1\" from \"$2\"";
  fi;
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
  logmessage "${cYel}Getting new keys and save valid in '$validKeysFile'${cNone}";
  writeLog "Getting new keys and save valid in '$validKeysFile'";
  ## Get list of warez keys, and read result 'line by line'
  while read line; do
    ## Get user:pass from line
    local Username=${line%%:*} Password=${line#*:};

	 if [[ $Username == *http* ]]; then
		logmessage "--------------------------------------------------";
		logmessage "${cBold}Checking server ${cYel}$Username:$Password${cNone}";
		logmessage "--------------------------------------------------";
		continue;
	 fi;
	 
	 #echo "проверка" Username=${line%%:*} Password=${line#*:};
    ## Check values for != empty
    if [ ! -z $Username ] && [ ! -z $Password ]; then
      logmessage -n "Checking key ${cYel}$Username${cNone}:$Password.. ";
      if checkKey -n $Username $Password; then
        ## If tested key valid and not exists in keys file - add it (or skip)
        if [ -f "$validKeysFile" ] && grep -Fq $Username "$validKeysFile"; then
          echo -ne "  ${cYel}skipped${cNone}";
        else
          echo "$Username:$Password" >> "$validKeysFile";
          echo -ne " +${cGreen}added${cNone}";
        fi;
      else
        echo -ne " -${cRed}invalid${cNone}";
      fi;
      echo "";
    else
      logmessage "${cRed}Error${cNone} reading new key ('${cRed}$Username${cNone}':'${cRed}$Password${cNone}')";
    fi;
  done <<< "$(getKeys)"; removeEmptyLinesInFile "$validKeysFile";
}

removeInvalidKeys() {
  if [ -f "$validKeysFile" ]; then
    ## Make a copy of file..
    cp -f "$validKeysFile" "$validKeysFile.lock";
    local lineCounter=0;
    ## ..and work with it
    logmessage "${cYel}Removing invalid keys from '$validKeysFile'${cNone}";
    writeLog "Removing invalid keys from '$validKeysFile'";
    while read line; do
      lineCounter=$((lineCounter+1));
      ## Get user:pass from line
      local Username=${line%%:*} Password=${line#*:};
      if [ ! -z $Username ] && [ ! -z $Password ]; then
        logmessage -n "Checking key before erasing ${cYel}$Username${cNone}:$Password.. ";
        if ! checkKey -n $Username $Password; then
          echo -ne " -${cRed}remove${cNone}";
          removeKeyFromFile "$Username:$Password" "$validKeysFile";
        else
          echo -ne "  ${cYel}skipped${cNone}";
        fi;
        echo "";
      else
        logmessage "Error reading '${cYel}$validKeysFile${cNone}' - damn line \"${cYel}$lineCounter${cNone}\" is broken";
      fi;
    done < "$validKeysFile.lock"; rm -f "$validKeysFile.lock";
    removeEmptyLinesInFile "$validKeysFile";
  fi;
}

testRandomKey() {
  ## Get random key..
  #local randomKey=$(sort -R "$validKeysFile" | head --lines=1);
  local randomKey=$(head -$((${RANDOM} % `wc -l < "$validKeysFile"` + 1)) "$validKeysFile" | tail -1);
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
      removeKeyFromFile "$Username:$Password" "$validKeysFile";
      removeEmptyLinesInFile "$validKeysFile";
      return 1; # err
    fi;
  fi;
}

createDirByFilePath() {
  ## $1 = file path
  local CreatePath=${1%/*};
  if [ ! -z "$CreatePath" ] && [ ! -d "$CreatePath" ]; then
    mkdir -p "$CreatePath";
  fi;
}

## Here we go! ################################################################

echo "  _  _         _ _______    ___     _   _  __";
echo " | \| |___  __| |__ /_  )  / __|___| |_| |/ /___ _  _";
echo " | .' / _ \/ _' ||_ \/ /  | (_ / -_)  _| ' </ -_) || |";
echo " |_|\_\___/\__,_|___/___|  \___\___|\__|_|\_\___|\_, | //j.mp/GitNod32Mirror";
echo "                                                 |__/";
echo "";

## Run script with params #####################################################

## --help
if [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$1" == "-H" ]; then
  me=$(basename $0);
  echo -e "This script get valid Nod32 key using pirates web-sites. Now we supports:";
  for URL in ${HTML_list[*]}; do
	  echo -e "  ${cYel}$URL${cNone}";
  done;
  echo -e "\nYou can run with parameters:";
  echo -e "  ${cYel}-u, --update${cNone}     Get new valid keys and write to $validKeysFile";
  echo -e "  ${cYel}-r, --remove${cNone}     Remove invalid keys from $validKeysFile";
  echo -e "  ${cYel}-s, -p, --show${cNone}   Print keys from $validKeysFile";
  echo -e "  ${cYel}-d, --delete${cNone}     Delete $validKeysFile";
  echo -e "  ${cYel}-h, --help${cNone}       Show this help\n\n";
  echo -e "Valid key (or \"error\") will printed in ${cYel}LAST OUTPUT LINE${cNone} (format 'user:password')";
  echo -e "                                       ${cBlue}^^^^^^^^^^^^^^^^${cNone}";
  echo -e "You can use: \"${cYel}$(basename $0) | tail -n 1${cNone}\" for getting key only\n\n";
  echo -e "Last update: 12.02.2015, MIT License, ${cRed}use for educational or information";
  echo -e "  purposes only!${cNone}";
  exit 0;
fi;
## --update
if [ "$1" == "-u" ] || [ "$1" == "--update" ]; then getNewKeysAndSave; exit 0; fi;
## --remove
if [ "$1" == "-r" ] || [ "$1" == "--remove" ]; then removeInvalidKeys; exit 0; fi;
## --show --print
if [ "$1" == "-s" ] || [ "$1" == "--show" ] || [ "$1" == "-p" ] || [ "$1" == "--print" ]; then
  if [ -f "$validKeysFile" ]; then cat "$validKeysFile"; fi; exit 0;
fi;
## --delete
if [ "$1" == "-d" ] || [ "$1" == "--delete" ]; then
  if [ -f "$validKeysFile" ]; then
	  rm "$validKeysFile";
	  echo -e "File $validKeysFile ${cYel}deleted${cNone}";
  else
    echo "Nothing to remove";
  fi;
  exit 0;
fi;
## Begin work #################################################################

## Create patches
createDirByFilePath $validKeysFile;
createDirByFilePath $invalidKeysFile;
createDirByFilePath $LOGFILE;

## If keys file not exists - get new keys and save them
if [ ! -f "$validKeysFile" ]; then
  getNewKeysAndSave;
fi;

## Double file exists check (if getNewKeysAndSave() failed)
if [ ! -f "$validKeysFile" ]; then
  logmessage "File ${cRed}$validKeysFile${cNone} not created. Exit";
  echoKey "error";
  writeLog "File \"$validKeysFile\" not created. Exit";
  exit 1;
fi;

## Getting random key and..
randomKey=$(testRandomKey);
## ..check him

if [ -z "$randomKey" ]; then
  logmessage "Getted random key from $validKeysFile is invalid";
  ## If he not not valid, we remove all invalid keys from file
  removeInvalidKeys;
  ## Then again get random key from file
  randomKey=$(testRandomKey);
  ## And if now random key invalid (or empty)
  if [ -z "$randomKey" ]; then
    logmessage "Getted random key from $validKeysFile again is invalid";
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
      writeLog "Return key \"$randomKey\" from from web";
    fi;
  else
    ## After removeInvalidKeys()
    echoKey $randomKey;
    writeLog "Return key \"$randomKey\" from local file after remove all invalid keys";
  fi;
else
  ## After 1st randomKey()
  echoKey $randomKey;
  writeLog "Return key \"$randomKey\" from local file";
fi;


# If key not found (not setted ) - write 'error'
if [ ! "$KEY_FOUND" = true ] ; then
  echoKey "error";
  writeLog "FATAL error - key not returned";
  exit 1;
fi;
exit 0;

