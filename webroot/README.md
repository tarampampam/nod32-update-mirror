### Set web server root directory path to this directory


Script config:
```shell
# ...
export NOD32MIRROR_MIRROR_DIR="/path/to/this/dir";
# ...
```

nginx config:
```nginx
server {
  # ...
  root /path/to/this/dir;
  # ...
}
```