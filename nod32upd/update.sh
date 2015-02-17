#!/bin/bash

## @author    Samoylov Nikolay
## @project   NOD32 Update Script
## @copyright 2015 <github.com/tarampampam>
## @license   MIT <http://opensource.org/licenses/MIT>
## @github    https://github.com/tarampampam/nod32-update-mirror/
## @version   Look in 'settings.cfg'
##
## @depends   curl, wget, grep, sed, cut, cat, basename, 
##            unrar (if use official mirrors)

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
  echo -e "\e[1;31mCannot load settings ('$PathToSettingsFile') file. Exit\e[0m"; exit 1;
fi;

## Init global variables
WORKURL=''; USERNAME=''; PASSWD='';

## Helpers Functions ##########################################################

## Show log message in console
logmessage() {
  ## $1 = (not required) '-n' flag for echo output
  ## $2 = message to output
	[[ "$quiet" == true ]] && return 1;
	local mytime=[$(date +%H:%M:%S)];
	local flag='-e';
	local outtext='';
	if [[ "$1" == '-'* ]]; then 
      outtext=$2;
	  [[ "$1" == *t* ]] && mytime='';
	  [[ "$1" == *n* ]] && flag='-e -n';
      #local i;
      #for ((i=0; $i<${#1}; i=$(($i+1)))); do
      #  local char=${1:$i:1};
      #  case $char in
      #    t) mytime='';;
      #    n) flag=$flag''$char;;
      #  esac;	
      #done;
	else 
	  outtext=$1;
	fi;
  echo $flag $mytime "$outtext";
}

## Write log file (if filename setted)
writeLog() {
  if [ ! -z "$LOGFILE" ]; then
    echo "[$(date +%Y-%m-%d/%H:%M:%S)] [$(basename $0)] - $1" >> "$LOGFILE";
  fi;
}

checkAvailability() {
  ## $1 = (not required) '-n' flag for echo output
  ## $2 = URL for checking (with slash at the and)

  flag=''; URL='';
  if [ "$1" == "-n" ]; then
    flag="-n "; URL=$2;
  else
    URL=$1;
  fi;

  headers=$(curl -A "$USERAGENT" --user $USERNAME:$PASSWD -Is $URL'update.ver');
  if [ "$(echo \"$headers\" | head -n 1 | cut -d' ' -f 2)" == '200' ]
  then
    logmessage -t $flag "${cGreen}Available${cNone}";
    return 0;
  else
    logmessage -t $flag "${cRed}Failed${cNone}";
    return 1;
  fi;
}

downloadFile() {
  ## $1 = (not required) '-n' flag for echo output
  ## $2 = URL to download
  ## $3 = save to file PATH

  flag=''; url=''; saveto='';
  if [ "$1" == "-n" ]; then
    flag="-n "; url=$2; saveto=$3;
  else
    url=$1; saveto=$2;
  fi;

  if [ -n "$wgetDelay" ] || [ -z "$wgetDelay" ]; then
    wgetDelay='0';
  fi;

  if [ -n "$wgetLimitSpeed" ] || [ -z "$wgetLimitSpeed" ]; then
    wgetLimitSpeed='102400k';
  fi;

  ## wget manual <http://www.gnu.org/software/wget/manual/wget.html>
  ##
  ## --cache=off    When set to off, disable server-side cache
  ## --timestamping Only those new files will be downloaded in the place
  ##                of the old ones.
  ## -v -d          Verbose and Debud output
  ## -U             Identify as agent-string to the HTTP server
  ## --limit-rate   Limit the download speed to amount bytes per second
  ## -e robots=off
  ## -w             Wait the specified number of seconds between the
  ##                retrievals
  ## --random-wait  This option causes the time between requests to vary
  ##                between 0 and 2 * wait seconds
  ## -P             Path to save file (dir)

  ## Save wget output to vareable and..
  wgetResult=$(wget \
    --cache=off \
    --timestamping \
    -v -d \
    -U "$USERAGENT" \
    --http-user="$USERNAME" \
    --http-password="$PASSWD" \
    --limit-rate=$wgetLimitSpeed \
    -e robots=off \
    -w $wgetDelay \
    --random-wait \
    -P $saveto \
    $url 2>&1);

  ## ..if we found string 'not retrieving' - download skipped..
  if [[ $wgetResult == *not\ retrieving* ]]; then
    logmessage -t $flag "${cYel}Skipped${cNone}";
    return 1;
  fi;

  ## ..also - if we found 'saved' string - download was executed..
  if [[ $wgetResult == *saved* ]]; then
    logmessage -t $flag "${cGreen}Complete${cNone}";
    return 1;
  fi;

  ## ..or resource not found
  if [[ $wgetResult == *ERROR\ \4\0\4* ]]; then
    logmessage -t $flag "${cRed}Not found${cNone}";
    return 1;
  fi;

  ## if no one substring founded - maybe error?
  logmessage -t $flag "${cRed}Error =(${cNone}\nWget debug info: \
    \n\n${cYel}$wgetResult${cNone}\n\n";
  return 0;
}

## Parse data from passed content of ini section
function getValueFromINI() {
  local sourceData=$1; local paramName=$2;
  ## 1. Get value "platform=%OUR_VALUE%"
  ## 2. Remove illegal characters
  #echo $(echo "$sourceData" | sed -n '/^'$paramName'=\(.*\)$/s//\1/p' | tr -d "\r" | tr -d "\n");
  echo $(echo "$sourceData" | grep "$paramName=" | sed s/^$paramName=//);
}

## Create some directory
createDir() {
  local dirPath=$1;
  if [ ! -d $dirPath ]; then
    logmessage -n "Create $dirPath.. "; mkdir -p $dirPath >/dev/null 2>&1;
    if [ -d "$dirPath" ]; then
      logmessage -t $msgOk; else logmessage -t $msgErr;
    fi;
  fi;
}

## Remove some directory
removeDir() {
  local dirPath=$1;
  if [ -d $dirPath ]; then
    logmessage -n "Remove $dirPath.. "; rm -R -f $dirPath >/dev/null 2>&1;
    if [ ! -d "$dirPath" ]; then
      logmessage -t $msgOk; else logmessage -t $msgErr;
    fi;
  fi;
}

## Here we go! ################################################################

echo "  _  _         _ _______   __  __ _";
echo " | \| |___  __| |__ /_  ) |  \/  (_)_ _ _ _ ___ _ _";
echo " | .' / _ \/ _' ||_ \/ /  | |\/| | | '_| '_/ _ \ '_|";
echo " |_|\_\___/\__,_|___/___| |_|  |_|_|_| |_| \___/_|  //j.mp/GitNod32Mirror";
echo "";
echo -e " ${cYel}Hint${cNone}: If you want ${cYel}quit${cNone} \
from 'parsing & writing new update.ver file' or
       ${cYel}quit${cNone} from 'Download files' - press 'q'; \
${cGray}for more options use '${cYel}--help ${cGray}'or '${cYel}-h${cGray}'${cNone}";

## Run script with params #####################################################

## render all script param with recursion
handleParam(){
  ## $* - all incoming params of script
  for opt in $*; do
    ## render keys with -- and ''
    if [ $(echo $opt | grep ^\-\-) ] || [ ! $(echo $opt | grep ^\-) ]; then
      case $opt in
        --flush)   flush;;
        --nolimit) nolimit;;
        --quiet)   quiet=true;;
        --nomain)  nomain=true;;
        --help)    helpPrint;;
        *) echo -n $0; echo -e ": illegal param -- ${cYel}$opt${cNone}";
           echo -e "For help you can use flag '${cYel}--help ${cNone}'or '${cYel}-h${cNone}'";
           exit 1;;
      esac;
      continue;
    fi;
    ## render params with -
    while getopts "flqmh" p; do
      case $p in
        f) handleParam --flush;;
        l) handleParam --nolimit;;
        q) handleParam --quiet;;
        m) handleParam --nomain;;
        h) handleParam --help;;
        *) echo -e "For help you can use flag '${cYel}--help ${cNone}'or '${cYel}-h${cNone}'";
           exit 1;;
      esac;
    done;
  done;
}

## --flush
## Remove all files (temp and base) (except .hidden)
flush(){
  ## Remove temp directory
  if [ -d "$pathToTempDir" ]; then
    logmessage -n "Remove $pathToTempDir.. ";
    rm -R -f $pathToTempDir;
    logmessage -t $msgOk;
  fi;

  if [ "$(ls $pathToSaveBase)" ]; then
    logmessage -n "Remove all files (except .hidden) in $pathToSaveBase.. ";
    rm -R -f $pathToSaveBase*;
    logmessage -t $msgOk;
  fi;
  writeLog "Files storage erased";
  exit 0;
}

## --nolimit
## Disable download speed limit and off delay
nolimit(){
  wgetDelay=''; wgetLimitSpeed='';
}

## --quiet
## quiet mode
quiet=false;

#--help
helpPrint(){
  echo ;
  echo "-f, --flush    - remove all files (except .hidden) in $pathToSaveBase";
  echo "-l, --nolimit  - unlimit download speed & disable delay";
  echo "-q, --quiet    - quiet mode";
  echo -e "-m, --nomain   - do not create main mirror (if you need v4 or v8,
                 that may be you don need main mirror with v3 updates)";
  echo "-h, --help     - this help"
  exit 1;
}

quit() {
  read -s -t 0.1 -n 1 INPUT;
    if [[ "$INPUT" = q ]];then
      logmessage -t "${cGray}>${cNone}";
      local version=$(echo "$saveToPath" | sed "s|${pathToSaveBase}||" | sed 's/\///');
      [ -z "$version" ] && version=v3;
      logmessage "${cRed}Stop update NOD32 $version${cNone}";
    return 0;
  fi;
  return 1;
}
## Prepare ####################################################################

## render all script params with recursion
handleParam $*;

###############################################################################
## If you want get updates from official servers using 'getkey.sh' ############
## (freeware keys), leave this code (else - comment|remove). ##################
## Use it for educational or information purposes only! #######################

if [ "$getFreeKey" = true ] && [ -f "$pathToGetFreeKey" ]; then
  logmessage -n "Getting valid key from '$pathToGetFreeKey'.. "
  nodKey=$(bash "$pathToGetFreeKey" | tail -n 1);
  if [ ! "$nodKey" == "error" ]; then
    nodUsername=${nodKey%%:*} nodPassword=${nodKey#*:};
    if [ ! -z $nodUsername ] && [ ! -z $nodPassword ]; then
      updServer0=('http://update.eset.com/eset_upd/' $nodUsername $nodPassword);
      logmessage -t "$msgOk ($nodUsername:$nodPassword)";
    else
      logmessage -t $msgErr;
    fi;
  else
    logmessage -t $msgErr;
  fi;
fi;

## End of code for 'getkey.sh' ################################################
###############################################################################


## Check URL in 'updServer{N}[0]' for availability
##   Limit of servers in settings = {0..N}
for i in {0..10}; do
  ## Get server URL
  eval CHECKSERVER=\${updServer$i[0]};

  ## Begin checking server
  if [ ! "$CHECKSERVER" == "" ]; then
    logmessage -n "Checking server $CHECKSERVER.. "
    ## Make check
    eval USERNAME=\${updServer$i[1]};
    eval   PASSWD=\${updServer$i[2]};
    if checkAvailability $CHECKSERVER; then
      ## If avaliable - set global values..
      WORKURL=$CHECKSERVER;
      ## ..by array items
      break;
    fi;
  fi;
done

## If no one is available
if [ "$WORKURL" == "" ]; then
  logmessage "${cRed}No available server, exit${cNone}"
  writeLog "FATAL - No available server";
  exit 1;
fi;

## Remove old temp directory
removeDir $pathToTempDir;
## Create base directory
createDir $pathToSaveBase;
## Create temp directory
createDir $pathToTempDir;

## Begin work #################################################################

## MAIN function - Making mirror by url (read 'update.ver', take sections
##   (validate/edit), write new 'update.ver', download files, declared in new
##   'update.ver')
function makeMirror() {
  ## $1 = From (url,  ex.: http://nod32.com/not_upd/)
  local sourceUrl=$1;
  ## $2 = To   (path, ex.: /home/username/nod_upd/)
  local saveToPath=$2;

  ## Path to DOWNLOADED 'update.ver' file
  local mainVerFile=$pathToTempDir'update.ver';
  ## Path to RESULT 'update.ver' file
  local newVerFile=$saveToPath'update.ver.new';
  ## Here we will store all parsed filenames from 'update.ver'
  local filesArray=();
  local isOfficialUpdate=false;

  ## Download source 'update.ver' file
  logmessage -n "Downloading $sourceUrl""update.ver.. ";
  downloadFile $sourceUrl'update.ver' $pathToTempDir;
  if [ ! -f $mainVerFile ]; then
    logmessage "${cRed}$mainVerFile after download not exists, stopping${cNone}";
    writeLog "Download \"$sourceUrl""update.ver\" failed";
    return 1;
  fi;

  ## Delete old file, if exists
  if [ -f $newVerFile ]; then rm -f $newVerFile; fi;

  ## Check - 'update.ver' packed with RAR or not?
  ## Get first 3 chars if file..
  fileHeader=$(head -c 3 $mainVerFile);
  ## ..and compare with template
  if [ "$fileHeader" == "Rar" ]; then
    ## Check - installed 'unrar' or not
    if [[ ! -n $(type -P unrar) ]]; then
      logmessage "${cRed}$mainVerFile packed by RAR, but i cannot find 'unrar' in your system :(, exit${cNone}"
      writeLog "Unpacking .ver file error (unrar not exists)";
      exit 1;
    else
      mv $pathToTempDir'update.ver' $pathToTempDir'update.rar';
      logmessage -n "Unpacking update.ver.. ";
      ## Make unpack (without 'cd' not working O_o)
      cd $pathToTempDir; unrar x -y -inul 'update.rar' $pathToTempDir;
      if [ -f $pathToTempDir'update.ver' ]; then
        logmessage -t $msgOk;
        isOfficialUpdate=true;
        rm -f 'update.rar';
      else
        logmessage -t "${cRed}Error while unpacking update.ver file, exit${cNone}";
        writeLog "Unpacking .ver file error (operation failed)";
        exit 1;
      fi;
    fi;
  fi;

  #cat $mainVerFile;
  ## Use function from read_ini.sh
  logmessage -n "Parsing & writing new update.ver file ${cGray}(gray dots = skipped sections)${cNone} "

  echo -e "[HOSTS]\nOther=200@http://um01.eset.com/eset_upd/v7/, \
200@http://91.228.166.14/eset_upd/v7/, 200@http://um03.eset.com/eset_upd/v7/, \
200@http://91.228.166.16/eset_upd/v7/, 200@http://um05.eset.com/eset_upd/v7/, \
200@http://91.228.167.133/eset_upd/v7/, 200@http://um07.eset.com/eset_upd/v7/, \
200@http://38.90.226.37/eset_upd/v7/, 200@http://um09.eset.com/eset_upd/v7/, \
200@http://38.90.226.39/eset_upd/v7/, 200@http://um11.eset.com/eset_upd/v7/, \
200@http://38.90.226.40/eset_upd/v7/, 200@http://um21.eset.com/eset_upd/v7/, \
200@http://91.228.167.21/eset_upd/v7/\n\
;; This mirror created by <github.com/tarampampam/nod32-update-mirror> ;;\n" > $newVerFile;

  OLD_IFS=$IFS; IFS=[
  for section in `cat $mainVerFile | sed '1s/\[//; s/^ *//'`; do
    IFS=$OLD_IFS;
    ## for exit from makeMirror, return 1
    quit && return 1;
    #logmessage $SectionName;
    ## 1. Get section content (text between '[' and next '[')
    local sectionContent="[$section";
    # echo "$sectionContent"; exit 1;
    local filePlatform=$(getValueFromINI "$sectionContent" "platform");
    #echo $filePlatform; exit 1;
    if [ ! -z $filePlatform ] && [[ "`echo ${updPlatforms[@]}`" == *$filePlatform* ]]; then
      ## $filePlatform founded in $updPlatforms
      ## Second important field - is 'type='
      local fileType=$(getValueFromINI "$sectionContent" "type");
      #echo "$fileType"; exit 1;
      if [ ! -z $fileType ] && [[ `echo ${updTypes[@]}` == *$fileType* ]]; then
        ## $fileType founded in $updTypes
        ## And 3rd fields - 'level=' or 'language='

        ## Whis is flag-var
        local writeSection=false;

        ## Check update file level
        local fileLevel=$(getValueFromINI "$sectionContent" "level");
        ## NOD32 **Base** Update File <is here>
        [ ! -z $fileLevel ] && [[ "`echo ${updLevels[@]}`" == *$fileLevel* ]] && writeSection=true;

        ## Check component language
        local fileLanguage=$(getValueFromINI "$sectionContent" "language");
        ## NOD32 **Component** Update File <is here>
        [ ! -z $fileLanguage ] && [[ "`echo ${updLanguages[@]}`" == *$fileLanguage* ]] && writeSection=true;

        ## Write active section to new update.ver file
        if [ "$writeSection" = true ]; then
          #echo "$sectionContent"; echo;
          ## get 'file=THIS_IS_OUR_VALUE'
          local fileNamePath=$(getValueFromINI "$sectionContent" "file");
          if [ ! -z "$fileNamePath" ]; then
            ## If path contains '://'
            if [[ $fileNamePath == *\:\/\/* ]]; then
              ## IF path is FULL
              ## (ex.: http://nod32mirror.com/nod_upd/em002_32_l0.nup)
              ## Save value 'as is' - with full path
              filesArray+=($fileNamePath);
            else
              if [[ $fileNamePath == \/* ]]; then
                ## IF path with some 'parent directory' (is slash in path)
                ## (ex.: /nod_upd/em002_32_l0.nup)
                ## Write at begin server name
                ## Anyone know how faster trin string to parts?!
                local protocol=$(echo $WORKURL | awk -F/ '{print $1}');
                local host=$(echo $WORKURL | awk -F/ '{print $3}');
                filesArray+=($protocol'//'$host''$fileNamePath);
              else
                ## IF filename ONLY
                ## (ex.: em002_32_l0.nup)
                ## Write at begin full WORKURL (passed in $sourceUrl)
                filesArray+=($sourceUrl''$fileNamePath);
              fi;
            fi;
            ## Replace fileNamePath
            local newFileNamePath='';
            if [ "$createLinksOnly" = true ]; then
              ## get full path to file (pushed in $filesArray)
              if [ "$isOfficialUpdate" = true ]; then
                ## If is official update - add user:pass to url string
                ##   (ex.: http://someurl.com/path/file.nup ->
                ##   -> http://user:pass@someurl.com/path/file.nup)
                local inputUrl=${filesArray[@]:(-1)};
                ## Anyone know how faster trin string to parts?!
                local protocol=$(echo $inputUrl | awk -F/ '{print $1}');
                local host=$(echo $inputUrl | awk -F/ '{print $3}');
                local mirrorHttpAuth='';
                if [ ! -z $USERNAME''$PASSWD ]; then
                  mirrorHttpAuth=$USERNAME':'$PASSWD'@';
                fi;
                newFileNamePath=$protocol'//'$mirrorHttpAuth''$host''$fileNamePath;
              else
                ## Else - return full url (ex.: http://someurl.com/path/file.nup)
                newFileNamePath=${filesArray[@]:(-1)};
              fi;
            else
              justFileName=${fileNamePath##*/};
              newFileNamePath=$justFileName;
            fi;
          fi;
          ## Echo (test) last (recently added) download task
          #echo ${filesArray[${#filesArray[@]}-1]};
          #echo $newFileNamePath;
          ## Mare replace 'file=...' in section
          sectionContent=$(echo "${sectionContent/$fileNamePath/$newFileNamePath}");
          logmessage -t "$sectionContent" >> $newVerFile;
        fi;
      fi;
    fi;
    if [ "$writeSection" = true ]; then
      logmessage -nt '.';
    else
      logmessage -nt "${cGray}.${cNone}";
    fi;
  done; logmessage -t " $msgOk";
  IFS=$OLD_IFS;

  if [ "$createLinksOnly" = true ]; then
    logmessage "'createLinksOnly' is 'true', download files is ${cYel}skipped${cNone}"
  else
    local dlNum=0;
    local dlTotal=${#filesArray[@]};
    ## Download all files from 'filesArray'
    for item in ${filesArray[*]}; do
      ## for exit from makeMirror, return 1
      quit && return 1;
      # Inc counter
      dlNum=$((dlNum+1));
      logmessage -n "Download file $item ($dlNum of $dlTotal).. ";
      downloadFile $item $saveToPath;
    done;
    logmessage "Mirroring \"$sourceUrl\" -> \"$saveToPath\" ${cGreen}complete${cNone}";
    writeLog "Mirroring \"$sourceUrl\" -> \"$saveToPath\" complete";
  fi;

  ## Delete old file, if exists local
  if [ -f $saveToPath'update.ver' ]; then rm -f $saveToPath'update.ver'; fi;
  mv $newVerFile $saveToPath'update.ver';
  logmessage "${cYel}File ${saveToPath}update.ver update${cNone}";
  writeLog "File ${saveToPath}update.ver update";
}

## Create (update) main mirror
if [[ "$nomain" == true ]]; then
  logmessage "Do not create main mirror";
  writeLog "Do not create main mirror";
else
  makeMirror $WORKURL $pathToSaveBase;
fi;

## Create (update) (if available) subdirs with updates
if [ ! -z "$checkSubdirsList" ]; then
  for item in ${checkSubdirsList[*]}; do
    ## for exit from makeMirror, return 1
    quit;
    checkUrl=$WORKURL''$item'/';

    logmessage -n "Checking $checkUrl.. ";
    if checkAvailability $checkUrl; then
      downloadPath=$pathToSaveBase''$item'/';
      mkdir -p $downloadPath;
      makeMirror $checkUrl $downloadPath;
    fi;
  done;
fi;

## Finish work ################################################################

## Remove old temp directory
removeDir $pathToTempDir;

if [ "$createTimestampFile" = true ]; then
  logmessage -n "Create timestamp file.. ";
  timestampFile=$pathToSaveBase'lastevent.txt';
  echo $(date "+%Y-%m-%d %H:%M:%S") > $timestampFile;
  if [ -f "$timestampFile" ]; then
    logmessage -t $msgOk; else logmessage -t $msgErr;
  fi;
fi;

if [ "$createRobotsFile" = true ]; then
  robotsTxtFile=$pathToSaveBase'robots.txt';
  if [ ! -f $robotsTxtFile ]; then
    logmessage -n "Create 'robots.txt'.. ";
    echo -e "User-agent: *\r\nDisallow: /\r\n" > $robotsTxtFile;
    if [ -f "$robotsTxtFile" ]; then
      logmessage -t $msgOk; else logmessage -t $msgErr;
    fi;
  fi;
fi;
