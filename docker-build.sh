#!/bin/sh

#build main app
docker build -f docker/Dockerfile-backend -t nod:backend .
