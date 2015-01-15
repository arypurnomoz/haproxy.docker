FROM progrium/busybox

RUN \
  opkg-install haproxy \
  && adduser -D haproxy

ADD https://github.com/kelseyhightower/confd/releases/download/v0.6.3/confd-0.6.3-linux-amd64 /usr/local/bin/confd

RUN chmod +x /usr/local/bin/confd

ADD confd.toml /etc/confd/confd.toml
ADD start.sh /tmp/start.sh

ENV LOG_HOST localhost

ENTRYPOINT ["/tmp/start.sh"]
