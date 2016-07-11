#### Шаги для воспроизведения проблемы *(steps to reproduce)*
 1. 
 2. 
 3. 

#### Какое действие ожидалось *(expected behaviour)*
Расскажите, какое поведение от скрипта вы ожидали *(tell us what should happen)*


#### Что произошло на самом деле *(actual behaviour)*
Расскажите что произошло на самом деле *(tell us what happens instead)*

---------

#### Данные системы *(system information)*
**Операционная система (operating system)**:
```bash
$ cat /proc/version
```

**Bash**:
```bash
$ bash --version
```

**wget / curl**:
```bash
$ wget -V
$ curl -V
```

---------

#### Настройки (settings):
**Настройки скрипта (script settings)**:
```bash
$ cat ./settings.conf ./conf.d/*.conf | grep -v -e '^#' -e '^$'
```
```shell
export NOD32MIRROR_DEBUG_MODE=0;
export NOD32MIRROR_COLOR_OUTPUT=1;
export NOD32MIRROR_USE_FREE_KEY=0;
...
```

**Лог-файл (log-file):**
```bash
$ cat ./nod32mirror.log | tail -n 30
```
```log
[YYYY-MM-DD/HH:MM:SS] [Type] Some log message.. 
...
```
