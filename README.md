[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/tarampampam/nod32-update-mirror/master/LICENSE) ![OS](https://img.shields.io/badge/OS-unix-green.svg)

# ESET Nod32 Update Mirror

Набор скриптов для создания зеркала базы обновления антивируса "Eset Nod32". Для работы требуется:

  - Unix-система (тестировался на CentOS 7, FreeNas 9.3 и FreeBSD 8.3);
  - Bash (тестировался на версиях 4.1.11(2), 4.2.24(1) и 4.2.45(1));
  - Установленные `curl` или `wget`, `unrar` (опционально), и некоторые другие стандартные приложения.

Параметры запуска и дополнительные функции смотри запустив скрипт с флагом `--help`.

> This is a set of scripts for creation "Eset Nod32" antivirus updates database mirror. Depends:
> 
>  - Unix-system (tested on CentOS 7, FreeNas 9.3 and FreeBSD 8.3);
>  - Bash (tested on versions 4.1.11(2), 4.2.24(1) and 4.2.45(1));
>  - Installed `curl` or `wget`, `unrar` (for getting updates from official mirrors), and some other standard applications.
>  
>Another options and additional features look by running script with the flag `--help`.

![Console screenshot](https://cloud.githubusercontent.com/assets/7326800/16690457/8617ac88-4541-11e6-84ee-270e1593e54f.png)

----------
### <i class="icon-download"></i>Установка / Installation

- Скачиваем крайнюю версию и распаковываем:
```
$ cd /tmp
$ wget https://github.com/tarampampam/nod32-update-mirror/archive/master.zip
$ unzip master.zip; cd ./nod32-update-mirror-master/
```
- Переносим набор скриптов в директорию недоступную "извне", но доступную для пользователя, который будет его запускать:
```
$ mv -f ./nod32-mirror/ ~
```
- Переходим в новое расположение скриптов и выполняем их [настройку](#настройка):
```
$ cd ~/nod32-mirror/
$ nano ./settings.conf
```
- Даем права на запуск скриптов:
```
$ chmod +x ./*.sh
```
- Проверяем наличие `unrar`, если планируем обновляться с официальных зеркал Eset NOD32:
```
$ type -P unrar
```
> Для установки `unrar` в **CentOS 7** можете воспользоваться следующим способом:
> ```
> $ wget http://pkgs.repoforge.org/unrar/unrar-4.0.7-1.el6.rf.x86_64.rpm 
> $ rpm -Uvh unrar-4.0.7-1.el6.rf.x86_64.rpm; rm unrar-4.0.7-1.el6.rf.x86_64.rpm
> ```

- Выполняем пробный запуск:
```
$ ./nod32-mirror.sh
$ ./nod32-mirror.sh --update
```
> Если у вас возникнут проблемы с запуском - вы всегда можете [сообщить нам об этом](https://github.com/tarampampam/nod32-update-mirror/issues/new).
> К сообщению **обязательно** прикладывайте содержимое файла `settings.conf`, версии используемого ПО (`cat /proc/version`, `bash --version`, `wget -V`, `curl -V`), и вывод работы скрипта **в не измененном виде**!

----------
### <i class="icon-cog"></i>Настройка / Configuration

Все настройки указываются в файле `settings.conf`. Каждая опция сопровождается подробным описанием и примером использования. Пожалуйста, будьте внимательны при его настройке.

> All settings are specified in the file `settings.conf`. Each option is accompanied by a detailed description and example of usage. Please be careful while modify settings.

----------
#### <i class="icon-file"></i>Особенности / Features

 - Работает как с `curl`, так и `wget` не зависимо друг от друга;
 - Если произошла ошибка при обновлении с сервера, который указан, например, в `NOD32MIRROR_SERVER_0` - производится попытка обновиться с сервера, указанного в `NOD32MIRROR_SERVER_1`, `NOD32MIRROR_SERVER_2`..`NOD32MIRROR_SERVER_9`;
 - Скачивает только обновленные файлы;
 - В комплекте идет веб-интерфейс и шаблон настроек для **nginx** *(без больших трудностей настройки переписываются под apache при необходимости)*

----------
#### <i class="icon-upload"></i>Прочие ссылки
 - [Пост в блоге](http://blog.kplus.pro/?p=29)
 - [Пост на хабре](http://habrahabr.ru/post/232163/)
 - [Редактор readme.md](https://stackedit.io/)

----------
#### <i class="icon-pencil"></i>История изменений
* **1.0.1.0** - Объемное изменение. Добавлены опции `NOD32MIRROR_BASE_URI`, `NOD32MIRROR_URI_PATH`и некоторые другие. Возвращена поддержка секции `[HOSTS]` в файле `update.ver` *(для неё-то и нужно указание URI сервера)*. Добавлена поддержка `pcu` *(Program Component Update)*. Изменены некоторые настройки "по умолчанию". Протестирована работа ESET Nod32 v5 с зеркалом. Корректность работы более поздних версий антивируса не представляется возможным на данный момент, так как лень;
* **1.0.0.1** - Issue #43 fix;
* **1.0.0.0** - Полностью переписан. Новый web-интерфейс. **Изменены параметры запуска**;
* **0.4.5.1** - Обновлен веб-интерфейс, обновлен пример конфига для nginx, конфиги для apache обновляться более не будут;
* **0.4.5** - Исправлена ошибка обновленного пути для проверки валидности ключей (Issue #38);
* **0.4.4** - Исправлена ошибка обновленного пути для проверки валидности ключей (Issue #26);
* **0.4.3.1** - Добавлена поддержка web-сервера **nginx**, добавлен примерный конфиг;
* **0.4.3** - Переработан веб-интерфейс, убрано лишнее из `.htaccess` файла, добавлены свои страницы ошибок (401,403,404,500,502,503). Вебмордочка сейчас простая и минималистичная няшка ([демо](https://googledrive.com/host/0B8jho7c8kaRhWVBoeTJzVnowUW8/)). Добавлен параметр `--delete` к файлу `getkey.sh`, который удаляет все рабочие ключи;
* **0.4.2** - Исправлена ошибка обновления с официальных зеркал, отказался от использования `grep -P` потому как под freebsd и centos7 - не работает из коробки, добавил возможность исключения некоторых секций из парсинга, `getFreeKey=true;` теперь включен по-умолчанию;
* **0.4.1** - Масштабное обновление, не совместимое с предыдущими версиями. Произведен рефакторинг, изменены имена переменных, переработана логика работы (теперь не просто ищется строка, начинающаяся на 'file=', а разбирается файл по секциям и собивается заново). Доступна возможность выбора необходимых языков и типов обновлений. Версия - не стабильная, при обнаружении ошибок - пожалуйста, создавайте соответствующие тикеты;
* **0.3.11** - Исправление ошибки с определением пути к файлу настроек (`$(pwd)` изменен на `$(dirname $0)`), исправлен путь проверки для валидации ключа (`../mod_000_loader_1080/..` на `../mod_000_loader_1082/..`), вместо умершего `www.nod327.net` используем `tnoduse2.blogspot.ru`, для отключения ограничений wget достаточно установить значения `wget_wait_sec` и `wget_limit_rate` пустыми (или закомментировать их вовсе);
* **0.3.9** - Решение проблемы валидации ключей (скрипт `get-nod32-key.sh`);
* **0.3.8** - Решение проблемы обновления с официальных зеркал для версий v5..v7;
* **0.3.7** - Рефакторинг, вынос настроек в отдельный файл, добавление логирования в скрипт обновления, незначительные доработки и изменения;
* **0.3.6** - Чертовски мощный апдейт. В комплект добавлен скрипт "**get-nod32-key.sh**" который самостоятельно получает валидный ключ к официальным серверам. Более того - исправлена ошибка с отсутствием в пути пары логин:пароль при выполнении двух условий - 'createLinksOnly' включен и обновляемся с официального зеркала;
* **0.3.4** - Поправки в GUI, 'footer.html' и 'header.html' перенесены в '.\.webface\', добавлена поддержка 'mod_geoip' в .htaccess, сам скрипт обновления не изменен;
* **0.3.3** - Незначительные поправки;
* **0.3.2** - Незначительные поправки;
* **0.3.1** - Добавлен "цветной" вывод сообщений, добавлена опция 'createLinksOnly' которая позволяет НЕ скачивать все файлы обновления целиком, а только лишь указывать ссылки на них в 'update.ver'. Улучшено комментирование кода, исправлена пара мелких ошибок, выявленных после теста на боевом сервере. Мелкие исправления;
* **0.3** - Полностью переписан **bash** скрипт, иной алгоритм работы;
* **0.2.5-sh** - **PHP** версия более не поддерживается, скрипт переписан на **bash**;
* **0.2.5** - Масса мелких исправлений в .htaccess и верстке;
* **0.2.4** - Релиз на гитхабе.

----------

#### <i class="icon-refresh"></i>Лицензия MIT


> Copyright (c) 2014-2016 [github.com/tarampampam](http://github.com/tarampampam/)

> Данная лицензия разрешает лицам, получившим копию данного программного обеспечения и сопутствующей документации (в дальнейшем именуемыми «Программное Обеспечение»), безвозмездно использовать Программное Обеспечение без ограничений, включая неограниченное право на использование, копирование, изменение, добавление, публикацию, распространение, сублицензирование и/или продажу копий Программного Обеспечения, также как и лицам, которым предоставляется данное Программное Обеспечение, при соблюдении следующих условий:

> Указанное выше уведомление об авторском праве и данные условия должны быть включены во все копии или значимые части данного Программного Обеспечения.

> ДАННОЕ ПРОГРАММНОЕ ОБЕСПЕЧЕНИЕ ПРЕДОСТАВЛЯЕТСЯ «КАК ЕСТЬ», БЕЗ КАКИХ-ЛИБО ГАРАНТИЙ, ЯВНО ВЫРАЖЕННЫХ ИЛИ ПОДРАЗУМЕВАЕМЫХ, ВКЛЮЧАЯ, НО НЕ ОГРАНИЧИВАЯСЬ ГАРАНТИЯМИ ТОВАРНОЙ ПРИГОДНОСТИ, СООТВЕТСТВИЯ ПО ЕГО КОНКРЕТНОМУ НАЗНАЧЕНИЮ И ОТСУТСТВИЯ НАРУШЕНИЙ ПРАВ. НИ В КАКОМ СЛУЧАЕ АВТОРЫ ИЛИ ПРАВООБЛАДАТЕЛИ НЕ НЕСУТ ОТВЕТСТВЕННОСТИ ПО ИСКАМ О ВОЗМЕЩЕНИИ УЩЕРБА, УБЫТКОВ ИЛИ ДРУГИХ ТРЕБОВАНИЙ ПО ДЕЙСТВУЮЩИМ КОНТРАКТАМ, ДЕЛИКТАМ ИЛИ ИНОМУ, ВОЗНИКШИМ ИЗ, ИМЕЮЩИМ ПРИЧИНОЙ ИЛИ СВЯЗАННЫМ С ПРОГРАММНЫМ ОБЕСПЕЧЕНИЕМ ИЛИ ИСПОЛЬЗОВАНИЕМ ПРОГРАММНОГО ОБЕСПЕЧЕНИЯ ИЛИ ИНЫМИ ДЕЙСТВИЯМИ С ПРОГРАММНЫМ ОБЕСПЕЧЕНИЕМ.

----------

> Copyright 2014-2016 [github.com/tarampampam](http://github.com/tarampampam/)

> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
