
# Packing in docker

## Notice

Edit `./.dockerignore` before add extra files in docker container:
  - Legal keys;
  - Custom config;
  - Etc.

Any files will be ignored, but excluded ones.

## Run backend standalone

* Build using the `Dockerfile`:
```bash
 $ docker build -t nod32-update:backend .
```
  - Look into the Dockerfile ! Change the CMD options, tf you want.

* Choose the `<target directory>`. Where to place downloaded files.
  - Use full path to the target tirectory: /home/user/nod32mirror
  - Make sure user with uid=2000 and/or gid=2000
    have permission to write and enter target directory:
```bash
 $ chown -R 2000:2000 <target directory> # EXAMLPE: chown -R 2000:2000 /home/user/nod32mirror
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
  - replace `../volumes/nod32mirror` with the directory path.

* Build and run

```
 $ docker-compose build
 $ docker-compose up -d
```

* Test webui on http://127.0.0.1.
  - Do not test on http://localhost, it contains nginx start pages.
  - `<target directory>` now contains update files.
    You can add there files from `./webroot` distr directory.
