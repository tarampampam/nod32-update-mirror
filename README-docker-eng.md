# Packing in docker

## Notice

Edit `./.dockerignore` before add extra files in docker container:
  - Legal keys;
  - Custom config;
  - Etc.

Any files will be ignored, but excluded ones.

## Simply run without any building

You can use pre-built [kran0/nod32-update-mirror:latest](https://hub.docker.com/r/kran0/nod32-update-mirror/tags/) docker container.

- Create work directory like `$HOME/nod-32-mirror`. Make sure you have docker and docker-compose installed;
- Get files `docker-compose.run.yaml`, `nginx.server.conf` from the project and optionally settings.conf;
- If you have no settings.conf, delete the line with ./settings.conf volume from backend service in `docker-compose.run.yaml`;
- Run `docker-compoe --file docker-compose.run.yaml up -d`. Done.

## Simply Run backend standalone without any building

```bash
 $ docker run -d\
     -v $PWD/nod32mirror:/worker/nod32mirror\
     -v /optional/path/to/custom/settings.conf:/backend/settings.conf:ro kran0/nod32-update-mirror:latest
```

## Run backend standalone

* Build using the `Dockerfile`:
```bash
 $ docker build -t nod32-update:backend .
```
  - Look into the Dockerfile ! Change the CMD options, if you want.

* Choose the `<target directory>`. Where to place downloaded files.
  - Use full path to the target tirectory: /home/user/nod32mirror
  - Make sure user with uid=100 and/or gid=101
    have permission to write and enter target directory:
```bash
 $ chown -R 100:101 <target directory> # EXAMLPE: chown -R 100:101 /home/user/nod32mirror
 $ chmod ug+rwx <target directory>     # EXAMLPE: chmod ug+rwx /home/user/nod32mirror
```

* Run docker container:
```bash
 $ docker run -d\
     -v <target directory>:/worker/nod32mirror\
     -v /optional/path/to/custom/settings.conf:/backend/settings.conf:ro nod32-update:backend
```

* After the cron job triggers,
  your `<target directory>` will contain downloaded files.

## Run with docker-compose

* Edit `<target directory>` in docker-compose.yml
  - replace `/path/to/storage/nod32mirror` with the directory path (./webroot?).

* Build and run

```
 $ docker-compose build
 $ docker-compose up -d
```

* Test webui on http://127.0.0.1.
  - After bakend's cronjob triggers, `<target directory>` will fill up with update files.
    You can add there files from `./webroot` distr directory
  - Make sure frontend nginx process can read
    from target directory uid=100, gid=101.
  - Make sure backend cron job worker process can write
    to target directory uid=100, gid=101.
