<?php

/**
 * @author    Samoylov Nikolay
 * @project   KPlus
 * @copyright 2014 <samoylovnn@gmail.com>
 * @version   0.2.5
 */


// **********************************************************************
// ***                           Config                                **
// **********************************************************************

// Setting errors level
error_reporting(0);
//error_reporting(E_ALL);

set_time_limit(0);
ini_set('memory_limit', '-1');

// URLs (array) to files bases, full path
$bases_urls_array = array(
    'http://traxxus.ch.cicero.ch-meta.net/nod32/',
    'http://avbase.tomsk.ru/files/nod32/',
    'http://itsupp.com/downloads/nod_update/'
);

$path_do_save_tmp = '/path/to/www/docs/.tmp';
$path_do_save_base = '/path/to/www/docs';

$wget_wait_sec = 3;

// **********************************************************************
// ***                         END Config                              **
// **********************************************************************

$workBaseUrl = '';

echo('[i] Init script..'."\n");

function checkAvailability($url) {
    $urlHeaders = @get_headers($url);
    if(strpos($urlHeaders[0], '200') === false) {
        return false;
    } else {
        return true;
    }
}


echo('[i] Check servers list..'."\n");

foreach ($bases_urls_array as $baseUrl)
    if(checkAvailability($baseUrl)) {
        $workBaseUrl = $baseUrl;
        break;
    }

if(empty($workBaseUrl)) {
    @fwrite(STDERR, "[NOD32 Update Server] All servers down!\n");
    die();
}

echo('[i] Work server is: '.$workBaseUrl."\n");

$wget_user_agent = 'ESS Update (Windows; U; 32bit; VDB 7001; BPC 4.0.474.0; '.
  'OS: 5.1.2600 SP 3.0 NT; CH 0.0; LNG 1049; x32c; UPD '.$workBaseUrl.'; '.
  'APP ess; BEO 1; CPU 5964; ASP 0.0)';

$parsedUrl = parse_url($baseUrl);

// count of dirs between 'server name' end last '/'
$cut_dirs = count(explode('/', $parsedUrl['path'])) - 2;


$cmd  = 'rm -R -f '.$path_do_save_tmp.'/ && ';
$cmd .= 'mkdir -p '.$path_do_save_tmp.' && ';
$cmd .= 'wget -r -np --cache=off -nv -U "'.$wget_user_agent.'" ';
$cmd .=   '-R html,htm,txt,php --limit-rate=512k ';
$cmd .=   '-e robots=off -w '.$wget_wait_sec.' --random-wait ';
$cmd .=   '-nH --cut-dirs='.$cut_dirs.' ';
$cmd .=   '-P '.$path_do_save_tmp.'/ '.$workBaseUrl.' && ';
$cmd .= 'rm -R -f '.$path_do_save_base.'/* && ';
$cmd .= 'mv '.$path_do_save_tmp.'/* '.$path_do_save_base.'/ && ';
$cmd .= 'rm -R -f '.$path_do_save_tmp.'/ && ';
$cmd .= 'find '.$path_do_save_base.' -name "*.htm*?*=*" -delete';

echo('[i] Exec command:'."\n".'  '.$cmd."\n");

shell_exec($cmd);

@fwrite(STDOUT, "[i] End update - ".date("Y-m-d H:i:s")."\n");

file_put_contents($path_do_save_base.'/lastevent.txt',
  date("Y-m-d H:i:s"));

file_put_contents($path_do_save_base.'/robots.txt',
  "User-agent: *\r\n".
  "Disallow: /\r\n");

