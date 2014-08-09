#!/bin/bash

## @author    Samoylov Nikolay
## @project   NOD32 Update Script
## @copyright 2014 <samoylovnn@gmail.com>
## @github    https://github.com/tarampampam/nod32-update-mirror/
## @version   0.3.4
##
## @depends   curl, wget, grep, cut, cat, unrar (if use official mirrors)

# *****************************************************************************
# ***                               Config                                   **
# *****************************************************************************

## Servers list. Format:
##   updServer{N}=('http://mirror.url/path/' 'username' 'password');
##   {N} - is numeric value 0..N (N declared in ~185 line, default '10')
##   'http://mirror.url/path/' - Server URL (with '/' at the end)
##   'username' - (not required) Login for auth
##   'password' - (not required) Password for auth
updServer0=('http://38.90.226.39/eset_eval/v4/' 'TRIAL-0117918823' 'nvm8v57sch');
updServer1=('http://traxxus.ch.cicero.ch-meta.net/nod32/');
updServer2=('http://eset.mega.kg/3/');
updServer3=('http://109.120.165.199/nod32/');
updServer4=('http://antivir.lanexpress.ru/nod32_3/');
updServer5=('http://itsupp.com/downloads/nod_update/');

## Check not only server URL, also - this included sub-dirs (without
##   slash at the end)
also_chek_this_subdirs=('v3' 'v4' 'v5' 'v6' 'v7' 'nod');

## If 'createLinksOnly' = true - we create ONLY 'update.ver' with full
##   links to original update files. Do NOT download updates files.
## If 'createLinksOnly' = false - we write to new 'update.ver' local
##   links (files names only), and DOWNLOAD all updates files.
createLinksOnly=false;

## User-agent for 'wget'. Make some random values in it.
RD=$RANDOM;
USERAGENT="ESS Update (Windows; U; 32bit; VDB $((RD%15000+10000)); \
BPC $((RD%2+6)).0.$((RD%100+500)).0; OS: 5.1.2600 SP 3.0 NT; CH 1.1; \
LNG 1049; x32c; APP eavbe; BEO 1; ASP 0.10; FW 0.0; PX 0; PUA 0; RA 0)";

## Path where we store mirror files. With '/' at the end
PathToSaveBase='/var/www/nod32upd/';

## Path to temp work directory (will created automaticly and removed
##   after update finish)
PathToTempDir=$PathToSaveBase'.tmp/';

## 'wget' limits (required). 
#wget_wait_sec='0';
#wget_limit_rate='51200k';
wget_wait_sec='3';
wget_limit_rate='512k';

# *****************************************************************************
# ***                            END Config                                  **
# *****************************************************************************

## Switch output language to English (DO NOT CHANGE THIS)
export LC_ALL=C;

## Init global variables
WORKURL=''; USERNAME=''; PASSWD='';

cRed='\e[1;31m'; cGreen='\e[0;32m'; cNone='\e[0m'; cYel='\e[1;33m';
cBlue='\e[1;34m'; cGray='\e[1;30m';

## Helpers Functions ##########################################################

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

checkAvailability() {
  ## $1 = (not required) '-n' flag for echo output
  ## $2 = URL for checking (with slash at the and)

  flag=''; URL='';
  if [ "$1" == "-n" ]; then
    flag="-n "; URL=$2;
  else
    URL=$1;
  fi

  headers=$(curl -A "$USERAGENT" --user $USERNAME:$PASSWD -Is $URL'update.ver');
  if [ "$(echo \"$headers\" | head -n 1 | cut -d' ' -f 2)" == '200' ]
  then
    echo -e $flag "${cGreen}Available${cNone}";
    return 0;
  else
    echo -e $flag "${cRed}Faled${cNone}";
    return 1;
  fi
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
  fi

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
    --limit-rate=$wget_limit_rate \
    -e robots=off \
    -w $wget_wait_sec \
    --random-wait \
    -P $saveto \
    $url 2>&1);

  ## ..if we found string 'not retrieving' - download skipped..
  if [[ $wgetResult == *not\ retrieving* ]]; then
    echo -e $flag "${cYel}Skipped${cNone}";
    return 1;
  fi

  ## ..also - if we found 'saved' string - download was executed..
  if [[ $wgetResult == *saved* ]]; then
    echo -e $flag "${cGreen}Downloaded${cNone}";
    return 1;
  fi

  ## if no one substring founded - maybe error?
  echo -e $flag "${cRed}Error =(${cNone}\nWget debug info: \
    \n\n${cYel}$wgetResult${cNone}\n\n";
  return 0;
}

## Run script with params #####################################################

## --flush
## Remove all files (temp and base) (except .hidden)
if [ "$1" == "--flush" ]; then
  ## Remove temp directory
  if [ -d "$PathToTempDir" ]; then
    logmessage -n "Remove $PathToTempDir.. ";
    rm -R -f $PathToTempDir;
    echo -e "${cGreen}Ok${cNone}";
  fi

  if [ "$(ls $PathToSaveBase)" ]; then
    logmessage -n "Remove all files (except .hidden) in $PathToSaveBase.. ";
    rm -R -f $PathToSaveBase*;
    echo -e "${cGreen}Ok${cNone}";
  fi
  exit 0;
fi

## Prepare ####################################################################

echo -e "${cYel}Hint${cNone}: For remove all files (except .hidden) \
in $PathToSaveBase you can use flag '${cYel}--flush${cNone}'";

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
    fi
  fi
done

## If no one is available
if [ "$WORKURL" == "" ]; then
  logmessage "${cRed}No available server, exit${cNone}"
  exit 1;
fi

## Remove old temp directory
if [ -d "$PathToTempDir" ]; then
  logmessage "Remove $PathToTempDir"
  rm -R -f $PathToTempDir
fi

## Create base directory
if [ ! -d $PathToSaveBase ]; then
  logmessage "Create $PathToSaveBase"; mkdir -p $PathToSaveBase
fi

## Create temp directory
if [ ! -d $PathToTempDir ]; then
  logmessage "Create $PathToTempDir"; mkdir -p $PathToTempDir
fi


## Begin work #################################################################

## MAIN function - Making mirror by url (read 'update.ver', take
##   filenames, write new 'update.ver' (without pathes to files),
##   download all files, declared in 'update.ver')
function makeMirror() {
  ## $1 = From (url,  ex.: http://nod32.com/not_upd/)
  ## $2 = To   (path, ex.: /home/kot/nod_upd/)

  #cd $PathToTempDir;
  logmessage -n "Downloading .ver file from $1.. "
  downloadFile $1'update.ver' $PathToTempDir;

  mainVerFile=$PathToTempDir'update.ver';
  newVerFile=$2'update.ver';

  ## If main .ver file not exists (ex.: download || save error)
  if [ ! -f $mainVerFile ]; then
    logmessage "${cRed}$mainVerFile after download not exists, exit${cNone}"
    return 1;
  fi

  ## Here we will store all parsed filenames from 'update.ver'
  filesArray=();


  ## Delete old file, if exists
  if [ -f $newVerFile ]; then rm -f $newVerFile; fi

  ## Check - 'update.ver' packed with RAR or not?
  ## Get first 3 chars if file..
  fileHeader=$(head -c 3 $mainVerFile);
  ## ..and comrate with template
  if [ "$fileHeader" == "Rar" ]; then
    ## Check - installed 'unrar' or not
    if [[ ! -n $(type -P unrar) ]]; then
      logmessage "$mainVerFile packed by RAR, but i cannot find 'unrar' in your system :(, exit"
      exit 1;
    else
      mv $PathToTempDir'update.ver' $PathToTempDir'update.rar';
      logmessage -n "Unpacing version file.. ";
      ## Make unpack (without 'cd' not working O_o)
      cd $PathToTempDir; unrar x -y -inul 'update.rar' $PathToTempDir;
      if [ -f $PathToTempDir'update.ver' ]; then
        echo -e "${cGreen}Ok${cNone}";
        rm -f 'update.rar';
      else
        echo -e "${cRed}Error, exit${cNone}";
        exit 1;
      fi
    fi
  fi

  logmessage -n "Reading original and writing new .ver file "
  ## Delete old local 'update.ver' and read new .ver file
  ##   'line by line'
  while read line; do
    ## Find 'file=' in line
    if [[ $line == *file=* ]]; then
      ## get 'file=THIS_IS_OUR_VALUE'
      tempFileName=$(echo $line | grep file= | cut -d "=" -f2 | tr -d '\r');
      if [ ! "$tempFileName" == '' ]; then
        ## Take only /some/url/CUIT_THIS.SHIT
        lineToNewVerFile=${tempFileName##*/};
        ## Add to files array
        ## If path contains '://'
        if [[ $tempFileName == *\:\/\/* ]]; then
          ## IF path is FULL
          ## (ex.: http://nod32mirror.com/nod_upd/em002_32_l0.nup)
          ## Save value 'as is' - with full path
          filesArray+=($tempFileName);
        else
          if [[ $tempFileName == *\/* ]]; then
            ## IF path with some 'parent directory' (is slash in path)
            ## (ex.: /nod_upd/em002_32_l0.nup)
            ## Write at begin server name
            protocol=$(echo $WORKURL | awk -F/ '{print $1}');
            host=$(echo $WORKURL | awk -F/ '{print $3}');
            filesArray+=($protocol'//'$host''$tempFileName);
          else
            ## IF filename ONLY
            ## (ex.: em002_32_l0.nup)
            ## Write at begin full WORKURL (passed in $1)
            filesArray+=($1''$tempFileName);
          fi
        fi
        
        ## Replace line
        if [ "$createLinksOnly" = true ] ; then
          ## gwt full path to file (pushed in $filesArray)
          line='file='${filesArray[@]:(-1)};
        else
          line='file='$lineToNewVerFile;
        fi
      fi
    fi
    ## Write new line info new file
    echo $line >> $newVerFile;
    echo -n '.';
  done < $mainVerFile; echo -e " ${cGreen}Ok${cNone}"; rm -f $mainVerFile;

  if [ "$createLinksOnly" = true ] ; then
    logmessage "'createLinksOnly' is 'true', download files is ${cYel}skipped${cNone}"
  else
    dlNum=0;
    dlTotal=${#filesArray[@]};
    ## Download all files from 'filesArray'
    for item in ${filesArray[*]}; do
      # Inc counter
      dlNum=$((dlNum+1));
      logmessage -n "Download file $item ($dlNum of $dlTotal).. "
      downloadFile $item $2;
    done;
  fi
}

## Create (update) main mirror
makeMirror $WORKURL $PathToSaveBase;

## Create (update) (if available) subdirs with updates
for item in ${also_chek_this_subdirs[*]}; do
  checkUrl=$WORKURL''$item'/';

  logmessage -n "Checking $checkUrl.. "
  if checkAvailability $checkUrl; then
    downloadPath=$PathToSaveBase''$item'/';
    mkdir -p $downloadPath;
    makeMirror $checkUrl $downloadPath;
  fi
done;

## Finish work ################################################################

## Remove temp directory
if [ -d "$PathToTempDir" ]; then
  logmessage -n "Remove $PathToTempDir.. ";
  rm -R -f $PathToTempDir;
  echo -e "${cGreen}Ok${cNone}";
fi

logmessage -n "Create timestamp file.. ";
echo $(date "+%Y-%m-%d %H:%M:%S") > $PathToSaveBase'lastevent.txt'; echo -e "${cGreen}Ok${cNone}";

robotsTxtFile=$PathToSaveBase'robots.txt';
if [ ! -f $robotsTxtFile ]; then
  logmessage -n "Create 'robots.txt'";
  printf "User-agent: *\r\nDisallow: /\r\n" > $robotsTxtFile;
  echo -e " ${cGreen}Ok${cNone}";
fi
