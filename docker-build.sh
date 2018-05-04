#!/bin/sh

#build main app
docker build\
 -f docker/Dockerfile-backend\
 --build-arg UID=2000\
 --build-arg GID=2000\
 -t nod:backend .
