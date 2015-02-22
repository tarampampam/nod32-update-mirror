#!/bin/bash


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
FILES='';
HASHES=''

## Helpers Functions ##########################################################

hashsum() { md5sum $*; }
updateVer(){
  local mainVerFile=${pathToSaveBase}$1;
  if [ -f ${pathToSaveBase}$1 ]; then
	  sed \
      -e '/HOST/d' \
      -e '/\[.*/b' \
      -e '/file=/b' \
      -e '/date=/b' \
      -e '/size=/b' \
      -e '/version=/b' \
      -e d $mainVerFile |\
      tr '\n' ' ' |\
      sed 's/\[/\n\[/g'\
    ;
	fi;
}
testHash() {
  
  local updateVer3=`updateVer 'update.ver'`;
  local updateVer4=`updateVer 'v4/update.ver'`;
  local updateVer5=`updateVer 'v5/update.ver'`;
  local updateVer6=`updateVer 'v6/update.ver'`;
  local updateVer7=`updateVer 'v7/update.ver'`;
  local updateVer8=`updateVer 'v8/update.ver'`;

	echo -e "\nGroup from filename:";
	echo "file / hash / size / size from update.ver";

  for str in $HASHES; do

		local hash=$(echo $str | cut -f1 -d'#');
    local file=$(echo $str | cut -f2 -d'#');
		local size=$(du -bL $file | awk '{print $1}');

    local lastFilename=$(echo $lastFile | cut -f $countSlashes -d'/');
    local lastFile=$file;
		local filename=$(echo $file | cut -f $countSlashes -d'/');

    file=${file/\/\//\/};
    
		local v=3;
    [[ "$file" == */v4/* ]] && v=4;
    [[ "$file" == */v5/* ]] && v=5;
    [[ "$file" == */v6/* ]] && v=6;
    [[ "$file" == */v7/* ]] && v=7;
    [[ "$file" == */v8/* ]] && v=8;
		eval local updateVer=\$updateVer$v;
		updateVer=`echo "$updateVer" | grep $filename | tr ' ' '\n'`;
		
		local verSize=`echo "$updateVer" | grep size | sed 's/.*size=//'`;
    local version=`echo "$updateVer" | grep version | sed 's/.*version=//'`;
    local verDate=`echo "$updateVer" | grep date | sed 's/.*date=//'`;

		if [[ "$verSize" == *$size* ]]; then cVer=$cGray; else cVer=$cNone	; fi
		
    if [ ! "$lastFilename" = "$filename" ];then 
	  echo ; # разделитель
      local firstHash=$hash;
      local firstSize=$size;
      local cHash=$cNone;
      local cSize=$cNone;
    else
      if [ "$firstHash" = "$hash" ]; then
	     local cHash=$cNone;
       else
       [ "$firstSize" = "$size" ] && local cHash=$cRed;
       [ ! "$firstSize" = "$size" ] && local cHash=$cYel;
      fi;
      if [ "$firstSize" = "$size" ]; then
        cSize=$cNone;
      else
        cSize=$cYel;
      fi;
    fi;
    
    [ -z $(echo $file | grep './v') ] && file="   $file";
    echo -ne $cGray'file:'$cHash "$file";
    echo -ne $cGray' hash:'$cHash''$hash $cNone;
    echo -ne $cGray' size:'$cSize''$size $cNone;
		
    if [ -z "$updateVer" ]; then
      echo -ne $cRed"- need delete!!!"$cNone;
    else
      echo -ne $cVer[$verSize]$cNone;
      echo -ne $cGray' v:'$version $cNone;
      echo -ne $cGray' date:'$verDate $cNone;
    fi;
			echo;
  done;
}
result() {
  # проценты
  local countH=$(echo "$HASHES" | tr '#' ' ' | awk '{print $1}' | wc -l);
  local sortH=$(echo "$HASHES"  | tr '#' ' ' | awk '{print $1}' | sort -u | wc -l);
  local procH=$(echo $(( ( $countH - $sortH ) * 100 / $countH )));

  local sortS=$(du -bL $FILES | awk '{print $1}' | sort -u | wc -l);
  echo =================================================================;
  echo "   Проверенно $countH файлов *.nup в $pathToSaveBase,
   уникальных хэшей: $sortH [ $procH% одинаковых хэшей]
   уникальных размеров: $sortS"
  echo =================================================================;
}
makeSymlinks(){
  # удалим все симлинки
  find $pathToSaveBase -iname \*nup -type l -delete;
	
	local i=0;
  for hash in `echo "$HASHES" | tr '#' ' ' | awk '{print $1}' | sort -u`;do
    ## файлы с одинаковым хэшем
    local files=`echo "$HASHES" | grep $hash | tr '#' ' ' | awk '{print $2}'`;
    ## выбрали оригинальный файл 
    local origFile=`echo "$files" | head -1`;
    ## удалим оригинальный файл из массива
    local files=`echo "$files" | sed "s|$origFile||"`;
    for str in $files; do
	  if [ -f "$str" ]; then
	    i=$(($i+1));
	    rm -f $str;
	    ln -s $origFile $str;
	    echo "ln -s $origFile -> $str";
	  fi;
    done;
  done;
  echo -e "${cGreen}Create $i symlink${cNone}";
}

## Run script with params #####################################################

echo -e '\e[1;33mHint:\e[0m Подробный вывод теста хэшей -t или --test';
echo -e "\e[1;33mHint:\e[0m Сделать симлинки одинаковых по хэшу файлов \
-ms или --symlink в $pathToSaveBase";

###############################################################################

# *****************************************************************************
# ***                               BEGIN                                    **
# *****************************************************************************

## count slashes
countSlashes=$(echo $pathToSaveBase | sed s/[^/]//g | wc -c);
countSlashes=$(($countSlashes + 1));
## get files ~/nod32mirror//em022_32_l2.nup
FILES=$(find $pathToSaveBase -iname \*.nup |\
        sed "s|${pathToSaveBase}e|${pathToSaveBase}\/e|g");
## sort FILES by filename
if [ -z "$(sort --help | grep '\-k')" ]; then echo -e $cRed"sort do not do key -k, upgrade sort"$cNone;exit 1; fi;
FILES=$( echo "$FILES" | sort -t '/' -k $countSlashes );

## отсортированные строки по имени файла:
## a543cd9d693ff4fce54e52391d71a3f98e75dd77#~/nod32mirror/v7/em023_32_l1.nup
## ' *' -> '#'
HASHES=$(hashsum $FILES | sed 's/ ./#/');

## for script params **********************************************************

if [[ "$*" == -*t* ]] || [[ "$*" == *--test* ]];     then testHash; fi;
if [[ "$*" == -*ms* ]] || [[ "$*" == *--symlink* ]]; then makeSymlinks; fi;

result;
