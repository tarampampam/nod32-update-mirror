<p align="center">
  <img alt="logo" src="https://hsto.org/webt/vm/1f/uo/vm1fuoyexrm8zylbtdfbm_hyi4m.png" width="180" />
</p>

# ESET Nod32 Update Mirror

[![Build][badge_build]][link_build]
[![Size][badge_image_size]][link_build]
[![Layers][badge_image_layers]][link_build]
[![Stars][badge_pulls]][link_pulls]
[![License][badge_license]][link_license]
[![Issues][badge_issues]][link_issues]

![Console screenshot][console_screenshot]

Docker-образ со скриптом для создания зеркала баз обновлений антивируса "Eset Nod32". Для его полноценного функционирования потребуется установленные:

- [Docker][install_docker]
- [Docker compose][install_docker_compose]

## Особенности :octocat:

 - Запускается в docker-контейнере, довольно экономично относится к ресурсам системы;
 - Успешно работает с различными версиями антивирусов Eset Nod32 *(для определения "рабочих" директорий различных версий Eset Nod32 используется проверки `User-Agent` и редиректы средствами `nginx`)*;
 - Умеет автоматически искать и использовать *(поддерживая их список в актуальном состоянии)* бесплатные ключи обновлений (**ВНИМАНИЕ! ДАННЫЙ ФУНКЦИОНАЛ ТОЛЬКО ДЛЯ ОЗНАКОМЛЕНИЯ И ТЕСТИРОВАНИЯ РАБОТЫ! ИСПОЛЬЗУЙТЕ ТОЛЬКО ЛЕГАЛЬНО КУПЛЕННЫЕ КЛЮЧИ!**)
 - Возможно размещение базы обновлений как в корневой директории домена, так и в произвольной под-директории *(не тестировал, но функционал заложил)*;
 - При указании не официальных серверов обновлений *(их можно указывать до 10 шт.)* и возникновении ошибки в процессе с первого указанного сервера - обновление произойдет со второго, иначе - с третьего, и так далее;
 - Реализована возможность скачивать обновления только для определенных программных продуктов, платформ, языков и версий Eset Nod32;
 - Поддерживается отладочный режим работы для быстрого выявления источников возможных проблем;
 - Пишет подробный лог;
 - Возможно указание лимитов скорости и задержек при скачивании файлов обновлений;
 - При завершении обновления пишет в отдельные файлы версию базы обновлений и дату обновления *(имена файлов настраиваются)*;
 - Скачивает только обновленные файлы.

## Установка и обновление

Ранее (до использования docker) приходилось довольно много всего ставить и настраивать, теперь же - достаточно иметь установленный `docker` и `docker-compose`. При необходимости - вы можете разобрать `Dockerfile` и `entrypoint*`-скрипты, запустив данный скрипт на вашем `busybox` (базовый docker-браз как раз основан на `alpine`).

Для запуска приложения достаточно выполнить:

```bash
$ docker run --rm tarampampam/nod32-update-mirror:latest --help
```

Или для запуска контейнера авто-обновления с `nginx` для "раздачи" фалов обновления:

```bash
$ curl https://raw.githubusercontent.com/tarampampam/nod32-update-mirror/master/docker-compose.live.yml --output ./docker-compose.yml
$ docker-compose up -d
```

После чего можно окрыть в браузере [127.0.0.1:8080](http://127.0.0.1:8080/) и увидеть веб-интерфейс приложения. В "фоновом" режиме (в отдельном контейнере) уже началось скачивание файлов обновления для зеркала.

> Перед запуском рекомендую ознакомиться с доступными параметрами кофигурации (базовые параметры описаны в самом файле `docker-compose.yml`, за деталями - поиск по исходникам).

Для остановки контейнеров достаточно в директории с файлом `docker-compose.yml` выполнить:

```bash
$ docker-compose down -v
```

> Флаг `-v` необходим для удаления всех `volume`, что были созданы внутри контейнеров. Если вы хотите оставить все скаченные файли и логи - не используйте флаг `-v`.

Так же следует уделить особое внимание переменным окружения контейнера `nginx` - `NGINX_SERVER_SCHEME` и `NGINX_SERVER_NAME` - их необходимо установить исходя из настроек домена, "на котором крутится" зеркало обновлений для корректных редиректов - это важно.

## История изменений

Доступна по [этой ссылке](./CHANGESLOG.md).

## Ссылки

- [Пост в блоге](https://blog.hook.sh/dev/make-nod32-mirror-updated/)
- [Пост на хабре](https://habr.com/post/232163/)

## License

MIT. Use anywhere for your pleasure.

[badge_build]:https://img.shields.io/docker/build/tarampampam/nod32-update-mirror.svg?style=flat-square&maxAge=30
[badge_image_size]:https://img.shields.io/microbadger/image-size/tarampampam/nod32-update-mirror.svg?style=flat-square&maxAge=30
[badge_image_layers]:https://img.shields.io/microbadger/layers/tarampampam/nod32-update-mirror.svg?style=flat-square&maxAge=30
[badge_pulls]:https://img.shields.io/docker/pulls/tarampampam/nod32-update-mirror.svg?style=flat-square&maxAge=30
[badge_license]:https://img.shields.io/github/license/tarampampam/nod32-update-mirror.svg?style=flat-square&maxAge=30
[badge_issues]:https://img.shields.io/github/issues/tarampampam/nod32-update-mirror.svg?style=flat-square&maxAge=30
[link_build]:https://hub.docker.com/r/tarampampam/nod32-update-mirror/builds/
[link_pulls]:https://hub.docker.com/r/tarampampam/nod32-update-mirror/
[link_license]:https://github.com/tarampampam/nod32-update-mirror/blob/master/LICENSE
[link_issues]:https://github.com/tarampampam/nod32-update-mirror/issues
[docker_hub]:https://hub.docker.com/r/tarampampam/nod32-update-mirror/
[console_screenshot]:https://cloud.githubusercontent.com/assets/7326800/16709324/ee055c38-4626-11e6-832e-17f40576d8c2.png
[install_docker]:https://docs.docker.com/install/
[install_docker_compose]:https://docs.docker.com/compose/install/
