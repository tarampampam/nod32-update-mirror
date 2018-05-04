FROM alpine:latest

# This is a backend container for nod32-update-mirror
# It uses cron to run nod32-update-mirror tool

# Use following command to build only backend
# $ docker build -t nod32-update:backend .

WORKDIR /backend
ADD ./nod32-mirror ./crontab.conf ./

RUN apk --no-cache --update add bash unrar curl\
 && addgroup workers\
 && adduser -D -G workers worker\
 && mv ./crontab.conf /etc/\
 && crontab -u worker /etc/crontab.conf\

 && chmod +x ./nod32-mirror.sh ./include/*.sh\
 && mkdir /nod32mirror\
 && chown worker:workers /nod32mirror

# single-run mode, uncomment this two lines
#USER worker
#CMD ["/backend/nod32-mirror.sh", "--update"]

# Normal mode: run cron with scheduled tasks
CMD ["/usr/sbin/crond", "-f", "-d", "0"]
