#!/bin/bash

## @author    Samoylov Nikolay
## @project   NOD32 Update Script
## @copyright 2015 <github.com/tarampampam>
## @license   MIT <http://opensource.org/licenses/MIT>
## @github    https://github.com/tarampampam/nod32-update-mirror/
## @version   Look in 'settings.cfg'
##
## @depends   curl, wget, grep, cut, cat, basename, 
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
    echo -e $flag "${cGreen}Available${cNone}";
    return 0;
  else
    echo -e $flag "${cRed}Failed${cNone}";
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
    echo -e $flag "${cYel}Skipped${cNone}";
    return 1;
  fi;

  ## ..also - if we found 'saved' string - download was executed..
  if [[ $wgetResult == *saved* ]]; then
    echo -e $flag "${cGreen}Complete${cNone}";
    return 1;
  fi;

  ## ..or resource not found
  if [[ $wgetResult == *ERROR\ \4\0\4* ]]; then
    echo -e $flag "${cRed}Not found${cNone}";
    return 1;
  fi;

  ## if no one substring founded - maybe error?
  echo -e $flag "${cRed}Error =(${cNone}\nWget debug info: \
    \n\n${cYel}$wgetResult${cNone}\n\n";
  return 0;
}

## Here we go! ################################################################

echo "  _  _         _ _______   __  __ _";
echo " | \| |___  __| |__ /_  ) |  \/  (_)_ _ _ _ ___ _ _";
echo " | .' / _ \/ _' ||_ \/ /  | |\/| | | '_| '_/ _ \ '_|";
echo " |_|\_\___/\__,_|___/___| |_|  |_|_|_| |_| \___/_|  //j.mp/GitNod32Mirror";
echo "";

## Run script with params #####################################################

## --flush
## Remove all files (temp and base) (except .hidden)
if [ "$1" == "--flush" ]; then
  ## Remove temp directory
  if [ -d "$pathToTempDir" ]; then
    logmessage -n "Remove $pathToTempDir.. ";
    rm -R -f $pathToTempDir;
    echo -e $msgOk;
  fi;

  if [ "$(ls $pathToSaveBase)" ]; then
    logmessage -n "Remove all files (except .hidden) in $pathToSaveBase.. ";
    rm -R -f $pathToSaveBase*;
    echo -e $msgOk;
  fi;
  writeLog "Files storage erased";
  exit 0;
else
  echo -e "${cYel}Hint${cNone}: For remove all files (except .hidden) \
in $pathToSaveBase you can use flag '${cYel}--flush${cNone}'";
fi;

## --nolimit
## Disable download speed limit and off delay
if [ "$1" == "--nolimit" ]; then
  wgetDelay=''; wgetLimitSpeed='';
else
  if [ ! -z "$wgetDelay" ] && [ ! -z "$wgetLimitSpeed" ]; then
    echo -e "${cYel}Hint${cNone}: For umlimit download speed & disable delay \
you can use flag '${cYel}--nolimit${cNone}'";
  fi;
fi;
## Prepare ####################################################################

###############################################################################
## If you want get updates from official servers using 'getkey.sh' #####
## (freeware keys), leave this code (else - comment|remove). ##################
## Use it for educational or information purposes only! #######################

if [ "$getFreeKey" = true ] && [ -f "$pathToGetFreeKey" ]; then
  logmessage -n "Getting valid key from '$pathToGetFreeKey'.. "
  nodKey=$(bash "$pathToGetFreeKey" | tail -n 1);
  if [ ! "$nodKey" == "error" ]; then
    nodUsername=${nodKey%%:*} nodPassword=${nodKey#*:};
    if [ ! -z $nodUsername ] && [ ! -z $nodPassword ]; then
      updServer0=('http://update.eset.com/eset_upd/' $nodUsername $nodPassword);
      echo -e "$msgOk ($nodUsername:$nodPassword)";
    else
      echo -e $msgErr;
    fi;
  else
    echo -e $msgErr;
  fi;
fi;

## End of code for 'getkey.sh' #########################################
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
if [ -d "$pathToTempDir" ]; then
  logmessage -n "Remove $pathToTempDir.. "; rm -R -f $pathToTempDir;
  if [ ! -d "$pathToTempDir" ]; then
    echo -e $msgOk; else echo -e $msgErr;
  fi;
fi;

## Create base directory
if [ ! -d $pathToSaveBase ]; then
  logmessage -n "Create $pathToSaveBase.. "; mkdir -p $pathToSaveBase;
  if [ -d "$pathToSaveBase" ]; then
    echo -e $msgOk; else echo -e $msgErr;
  fi;
fi;

## Create temp directory
if [ ! -d $pathToTempDir ]; then
  logmessage -n "Create $pathToTempDir.. "; mkdir -p $pathToTempDir;
  if [ -d "$pathToTempDir" ]; then
    echo -e $msgOk; else echo -e $msgErr;
  fi;
fi;


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
  local newVerFile=$saveToPath'update.ver';
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
        echo -e $msgOk;
        isOfficialUpdate=true;
        rm -f 'update.rar';
      else
        echo -e "${cRed}Error while unpacking update.ver file, exit${cNone}";
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

  # Get sections names from update.ver file, and store in array
  verSectionsNamesArray=($(grep -Po '(?<=^\[).*(?=\]$)' $mainVerFile));
  for SectionName in ${verSectionsNamesArray[*]}; do
    #logmessage $SectionName;
    local sectionContent="";
    ## Get section content (text between '[%section_name%]' and next '[')
    sectionContent=$(sed -e '/^\['$SectionName'\]/,/^\[/!d' $mainVerFile);
    ## Remove first line with '[%section_name%]'
    sectionContent=$(echo "$sectionContent" | tail -n +2);
    ## Remove last line, if it begins from next section name
    if [[ $(echo "$sectionContent" | tail -1) =~ ^\[ ]]; then
      sectionContent=$(echo "$sectionContent" | head -n -1);
    fi;
    ## And now we begin make selection - what we will write in new .ver file
    ##  and download, and what - passed. We make check some sections fields.
    ## And our fist important field - is 'platform='
    ## Get substring with word 'platform'
    local filePlatformRaw=$(echo "$sectionContent" | grep 'platform\=');
    ## And remove all before char '='
    local filePlatform=${filePlatformRaw#*=};
    ## Find $filePlatform in $updPlatforms
    if [ ! -z $filePlatform ]; then
      for i in "${updPlatforms[@]}"; do
        if [ "$i" == "$filePlatform" ]; then
          ## $filePlatform founded in $updPlatforms
          ## Second important field - is 'type='
          local fileTypeRaw=$(echo "$sectionContent" | grep 'type\=');
          local fileType=${fileTypeRaw#*=};
          #echo $fileType;
          if [ ! -z $fileType ]; then 
            for j in "${updTypes[@]}"; do
              if [ "$j" == "$fileType" ]; then
                ## $fileType founded in $updTypes
                ## And 3rd fields - 'level=' or 'language='
                local fileLevelRaw=$(echo "$sectionContent" | grep 'level\=');
                local fileLevel=${fileLevelRaw#*=};
                ## Whis is flag-var
                local writeSection=false;
                ## Check update file level
                if [ ! -z $fileLevel ]; then
                  for k in "${updLevels[@]}"; do
                    if [ "$k" == "$fileLevel" ]; then
                      ## NOD32 **Base** Update File <is here>
                      writeSection=true;
                      break;
                    fi;
                  done;
                fi;
                ## Check component language
                local fileLanguageRaw=$(echo "$sectionContent" | grep 'language\=');
                local fileLanguage=${fileLanguageRaw#*=};
                if [ ! -z $fileLanguage ]; then
                  for k in "${updLanguages[@]}"; do
                    if [ "$k" == "$fileLanguage" ]; then
                      ## NOD32 **Component** Update File <is here>
                      writeSection=true;
                      break;
                    fi;
                  done;
                fi;
                ## Write active section to new update.ver file
                if [ "$writeSection" = true ]; then
                  #echo "$sectionContent"; echo;
                  ## get 'file=THIS_IS_OUR_VALUE'
                  local fileNamePathRaw=$(echo "$sectionContent" | grep 'file\=');
                  local fileNamePath=${fileNamePathRaw#*=};
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
                  echo "["$SectionName"]" >> $newVerFile;
                  echo -e "$sectionContent\n" >> $newVerFile;
                fi;
                break;
              fi;
            done;
          fi;
          break;
        fi;
      done;
    fi;
    #echo "$sectionContent"; echo;
    if [ "$writeSection" = true ]; then
      echo -n '.';
    else
      echo -ne "${cGray}.${cNone}";
    fi;
  done; echo -e " $msgOk";


  if [ "$createLinksOnly" = true ] ; then
    logmessage "'createLinksOnly' is 'true', download files is ${cYel}skipped${cNone}"
  else
    local dlNum=0;
    local dlTotal=${#filesArray[@]};
    ## Download all files from 'filesArray'
    for item in ${filesArray[*]}; do
      # Inc counter
      dlNum=$((dlNum+1));
      logmessage -n "Download file $item ($dlNum of $dlTotal).. ";
      downloadFile $item $saveToPath;
    done;
    logmessage "Mirroring \"$sourceUrl\" -> \"$saveToPath\" ${cGreen}complete${cNone}";
    writeLog "Mirroring \"$sourceUrl\" -> \"$saveToPath\" complete";
  fi;
}

## Create (update) main mirror
makeMirror $WORKURL $pathToSaveBase;

## Create (update) (if available) subdirs with updates
if [ ! -z "$checkSubdirsList" ]; then
  for item in ${checkSubdirsList[*]}; do
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

## Remove temp directory
if [ -d "$pathToTempDir" ]; then
  logmessage -n "Remove $pathToTempDir.. ";
  rm -R -f $pathToTempDir;
  if [ ! -d "$pathToTempDir" ]; then
    echo -e $msgOk; else echo -e $msgErr;
  fi;
fi;

if [ "$createTimestampFile" = true ]; then
  logmessage -n "Create timestamp file.. ";
  timestampFile=$pathToSaveBase'lastevent.txt';
  echo $(date "+%Y-%m-%d %H:%M:%S") > $timestampFile;
  if [ -f "$timestampFile" ]; then
    echo -e $msgOk; else echo -e $msgErr;
  fi;
fi;

if [ "$createRobotsFile" = true ]; then
  robotsTxtFile=$pathToSaveBase'robots.txt';
  if [ ! -f $robotsTxtFile ]; then
    logmessage -n "Create 'robots.txt'.. ";
    echo -e "User-agent: *\r\nDisallow: /\r\n" > $robotsTxtFile;
    if [ -f "$robotsTxtFile" ]; then
      echo -e $msgOk; else echo -e $msgErr;
    fi;
  fi;
fi;
