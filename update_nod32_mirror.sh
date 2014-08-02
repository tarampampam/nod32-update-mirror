#!/bin/bash

## @author    Samoylov Nikolay
## @project   KPlus
## @copyright 2014 <samoylovnn@gmail.com>
## @github    https://github.com/tarampampam/nod32-update-mirror/
## @version   0.2.5-sh

# **********************************************************************
# ***                           Config                                **
# **********************************************************************

# slash at end url
bases_urls_array=(
  'http://traxxus.ch.cicero.ch-meta.net/nod32/'
  'http://eset.mega.kg/3/'
  'http://antivir.lanexpress.ru/nod32_3'
  'http://itsupp.com/downloads/nod_update/'
)

wget_user_agent='ESS Update (Windows; U; 32bit; VDB 19272; BPC 4.0.474.0; OS: 5.1.2600 SP 3.0 NT; CH 1.1; LNG 1049; x32c; APP eavbe; BEO 1; ASP 0.10; FW 0.0; PX 0; PUA 0; RA 0)';

path_do_save_base='/home/reKot/nod/'
path_do_save_tmp=$path_do_save_base'.tmp/'

wget_wait_sec='3'
wget_limit_rate='512k'

# **********************************************************************
# ***                         END Config                              **
# **********************************************************************

workBaseUrl=''

logmessage() {
  echo [$(date +%H:%M:%S)] $1
}

checkAvailability() {
  headers=$(curl -Is $1'update.ver' --user $2:$3);
  if [ $(echo \"$headers\" | head -n 1 | cut -d' ' -f 2) == '200' ]
  then
    return 0
  else
    return 1
  fi
}

for item in ${bases_urls_array[*]}
do
  logmessage "Checking server $item"
  if checkAvailability $item
  then
    workBaseUrl=$item
    break
  fi
done

if [ "$workBaseUrl" == '' ]
then
  logmessage "No available server, exit"
  exit 1
fi

## Get http://some.server/THIS/FUCKING/PATH/ (without shash at begin)
url_files_path="$(echo $workBaseUrl | grep / | cut -d/ -f4-)"
## Count of dirs between 'server name' end last '/'
cut_dirs="$(echo $url_files_path | awk 'BEGIN{FS="/"} {print NF-1}')"

if [ -d "$path_do_save_tmp" ]; then
  logmessage "Remove $path_do_save_tmp"
  rm -R -f $path_do_save_tmp
fi

logmessage "Make $path_do_save_tmp and $path_do_save_base"
mkdir -p $path_do_save_tmp; mkdir -p $path_do_save_base

## -r          Turn on recursive retrieving
## -np         Do not ever ascend to the parent directory when retrieving recursively
## --cache=off When set to off, disable server-side cache
## -nv         Non-verbose output
## -U          Identify as agent-string to the HTTP server
## -R html,htm,txt,php Specify comma-separated lists of file name suffixes or patterns to accept or reject
## --limit-rate Limit the download speed to amount bytes per second
## -e robots=off \  Do not get robots file
## -w          Wait the specified number of seconds between the retrievals
## --random-wait This option causes the time between requests to vary between 0 and 2 * wait seconds
## -nH         Disable generation of host-prefixed directories
## --cut-dirs  Ignore number directory components
## -P          Directory where all other files and subdirectories will be saved to

logmessage "Download base to $path_do_save_tmp"
wget \
  -r  \
  -np \
  --cache=off \
  -nv \
  -U "$wget_user_agent" \
  -R html,htm,txt,php \
  --limit-rate=$wget_limit_rate \
  -e robots=off \
  -w $wget_wait_sec \
  --random-wait \
  -nH \
  --cut-dirs=$cut_dirs \
  -P $path_do_save_tmp \
  $workBaseUrl

logmessage "Remove some trash in $path_do_save_tmp"
find $path_do_save_tmp -iname "*.htm*?*=*;*.txt" -delete

logmessage "Delete all files in $path_do_save_base (except .hidden)"
rm -R -f $path_do_save_base*

logmessage "Move files from $path_do_save_tmp to $path_do_save_base"
mv $path_do_save_tmp* $path_do_save_base

logmessage "Remove $path_do_save_tmp"
rm -R -f $path_do_save_tmp

logmessage "Create timestamp file"
echo $(date "+%Y-%m-%d %H:%M:%S") > $path_do_save_base'lastevent.txt';

logmessage "Create 'robots.txt'"
printf "User-agent: *\r\nDisallow: /\r\n" > $path_do_save_base'robots.txt';
