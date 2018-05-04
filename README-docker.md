
# Packing in docker

## Run backend standalone

* Build using the `Dockerfile`:
```bash
 $ docker build -t nod32-update:backend .
```
  - Look into the Dockerfile ! Change the CMD options, tf you want.

* Choose the `<target directory>`. Where to place downloaded files.
  - Use full path to the target tirectory: /home/user/nod32mirror
  - Make user with uid=2000 and/or gid=2000 can write and enter this directory:
```bash
 $ chown -R 2000:2000 <target directory> # EXAMLPE: chown -R 2000:2000 /home/user/nod32mirror
```

* Run docker container:
```bash
 $ docker run --rm -v <target directory>:/nod32mirror nod32-update:backend
```

* After the cron job triggers,
  your <target directory> will contain downloaded files

## Run with docker-compose

* Build and run

```
 $ docker-compose build
 $ docker-compose up -d
```

* Test webui on http://127.0.0.1.
  Do not test on http://localhost, it contains nginx start pages.

