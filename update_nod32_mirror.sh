#!/bin/bash

## @author    Samoylov Nikolay
## @project   NOD32 Update Script
## @copyright 2014 <samoylovnn@gmail.com>
## @github    https://github.com/tarampampam/nod32-update-mirror/
## @version   0.3
##
## @depend   curl, wget, grep, cut, cat, unrar (if use official mirrors)

# **********************************************************************
# ***                           Config                                **
# **********************************************************************

# with slash at the end of url
updServer0=('http://38.90.226.39/eset_eval/v4/'           'TRIAL-0117918823' 'nvm8v57sch');
updServer1=('http://traxxus.ch.cicero.ch-meta.net/nod32/'  '' '');
updServer2=('http://eset.mega.kg/3/'                       '' '');
updServer3=('http://109.120.165.199/nod32/'                '' '');
updServer4=('http://antivir.lanexpress.ru/nod32_3'         '' '');
updServer5=('http://itsupp.com/downloads/nod_update/'      '' '');

# without slash at the end
also_chek_this_subdirs=('v3' 'v4' 'v5' 'v6' 'v7' 'nod');

RD=$RANDOM;
USERAGENT="ESS Update (Windows; U; 32bit; VDB $((RD%15000+10000)); \
BPC $((RD%2+6)).0.$((RD%100+500)).0; OS: 5.1.2600 SP 3.0 NT; CH 1.1; \
LNG 1049; x32c; APP eavbe; BEO 1; ASP 0.10; FW 0.0; PX 0; PUA 0; RA 0)";

PathToSaveBase='/home/kplus/s.kplus.pro/docs/';
## Will be removed after update finish
PathToTempDir=$PathToSaveBase'.tmp/';

wget_wait_sec='0';
wget_limit_rate='51200k';

#wget_wait_sec='3';
#wget_limit_rate='512k';

# **********************************************************************
# ***                         END Config                              **
# **********************************************************************

## Switch output language to English (DO NOT CHANGE THIS)
export LC_ALL=C;

## Init global variables init
WORKURL=''; USERNAME=''; PASSWD='';

## Helpers Functions ###################################################

logmessage() {
  ## $1 = (not necessary) '-n' flag for echo output
  ## $2 = message to output
  
  flag=''; outtext='';
  if [ "$1" == "-n" ]; then
    flag="-n "; outtext=$2;
  else
    outtext=$1;
  fi
  
  echo $flag[$(date +%H:%M:%S)] "$outtext";
}

checkAvailability() {
  ## $1 = (not necessary) '-n' flag for echo output
  ## $2 = URL for checking (with slash at the and)
  
  flag=''; URL='';
  if [ "$1" == "-n" ]; then
    flag="-n "; URL=$2;
  else
    URL=$1;
  fi
  
  headers=$(curl -Is $URL'update.ver' --user $USERNAME:$PASSWD);
  if [ $(echo \"$headers\" | head -n 1 | cut -d' ' -f 2) == '200' ]
  then
    echo $flag "Available";
    return 0;
  else
    echo $flag "Faled";
    return 1;
  fi
}

downloadFile() {
  ## $1 = (not necessary) '-n' flag for echo output
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
    echo $flag "Skipped";
    return 1;
  fi
  
  ## ..also - if we found 'saved' string - download was executed..
  if [[ $wgetResult == *saved* ]]; then
    echo $flag "Downloaded";
    return 1;
  fi

  

  ## if no one substring founded - maybe error?
  echo $flag "Error =\(";
  echo "Wget debug info: ---------------------------------------------";
  echo $wgetResult;
  echo "--------------------------------------------------------------";
  return 0;
}

## Run script with params ##############################################

## --flush
## Remove all files (temp and base) (except .hidden)
if [ "$1" == "--flush" ]; then
  ## Remove temp directory
  if [ -d "$PathToTempDir" ]; then 
    logmessage "Remove $PathToTempDir"; rm -R -f $PathToTempDir;
  fi
  
  if [ "$(ls $PathToSaveBase)" ]; then 
    logmessage -n "Remove all files (except .hidden) in $PathToSaveBase.. ";
    rm -R -f $PathToSaveBase*;
    echo "Ok";
  fi
  exit 0;
fi

## Prepare #############################################################

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
  logmessage "No available server, exit"
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


## Begin work ##########################################################

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
    logmessage "$mainVerFile after download not exists, exit"
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
        echo "Ok";
        rm -f 'update.rar';
      else
        echo "Error, exit";
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
      tempFileName=$(echo $line | grep file= | cut -d "=" -f2);
      if [ ! "$tempFileName" == '' ]; then
        ## Take only /some/url/CUIT_THIS.SHIT
        lineWithoutPath=${tempFileName##*/};
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
      #  filesArray+=($tempFileName);
        ## Replace line
        line='file='$lineWithoutPath;
      fi
    fi
    ## Write new line info new file
    echo $line >> $newVerFile;
    echo -n '.';
  done < $mainVerFile; echo ' Ok'; rm -f $mainVerFile;

  dlNum=0;
  dlTotal=${#filesArray[@]};
  ## Download all files from 'filesArray'
  for item in ${filesArray[*]}; do
    # Inc counter
    dlNum=$((dlNum+1));
    logmessage -n "Download file $item ($dlNum of $dlTotal).. "
    downloadFile $item $2;
  done;
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


logmessage "Remove $PathToTempDir"
rm -R -f $PathToTempDir

logmessage "Create timestamp file"
echo $(date "+%Y-%m-%d %H:%M:%S") > $PathToSaveBase'lastevent.txt';

logmessage "Create 'robots.txt'"
printf "User-agent: *\r\nDisallow: /\r\n" > $PathToSaveBase'robots.txt';

