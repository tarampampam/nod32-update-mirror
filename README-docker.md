# Завернуть в докер

## Обратите внимение

Многие файлы игнорируются в `./.dockerignore`. Чтобы пересобрать контейнер
 со своими файлами, добавьте их в исключения:
  - Ключи обновления;
  - Кастомный конфиг;
  - Прочее.

Иначе ваши файлы будут игнорироваться при сборке

## Запуск контейнера обновлений отдельно

* Сборка с использованием `Dockerfile`:
```bash
 $ docker build -t nod32-update:backend .
```
  - Обратите внимание, в Dockerfile  предусмотрен режим без cron. См внизу CMD.

* Выберите каталог `<target directory>`. Куда будут загружаться обновления.
  - Используйте полный путь до каталога, например: /home/user/nod32mirror
  - Убедитесь, что у пользователя с uid=100 и/или gid=101
    есть право на запись и право входить в каталог:
```bash
 $ chown -R 100:101 <target directory> # Например: chown -R 100:101 /home/user/nod32mirror
 $ chmod ug+rwx <target directory>     # Например: chmod ug+rwx /home/user/nod32mirror
```

* Запуск контейнера:
```bash
 $ docker run -d\
     -v <target directory>:/worker/nod32mirror\
     -v /optional/path/to/custom/settings.conf:/backend/settings.conf:ro nod32-update:backend
```

* Дождитесь срабатывания задания cron,
  и в `<target directory>` будут загружены файлы обновлений.

## Запуск с использованием docker-compose

* Измените `<target directory>` в docker-compose.yml
  - замените `/path/to/storage/nod32mirror` на путь до директория (./webroot?).

* Сборка и запуск

```
 $ docker-compose build
 $ docker-compose up -d
```

* Проверьте webui на http://127.0.0.1.
  - Дождитесь срабатывания задания cron,
    и в `<target directory>` будут загружены файлы обновлений.
    Туда же можно добавить файлы из `./webroot`
  - Убедитесь, что процесс nginx может читать
    из целевого каталога uid=100, gid=101.
  - Убедитесь, что скрипт обновлений может писать
    в целевой каталог uid=100, gid=101.
