#!/bin/sh

if [ -z "$ETCD_HOST" ]
then
  echo "Missing ETCD_HOST env var"
  exit -1
fi


mkdir -p /etc/confd/conf.d /etc/confd/templates

cat << EOF > /etc/confd/conf.d/haproxy.toml
[template]
src="haproxy.cfg.tmpl"
dest="/tmp/haproxy.cfg"
mode="0644"
keys = [
  "$SERVICES"
]
check_cmd="sh -c \" \
  echo 'config is:'; \
  cat {{ .src }}; \
  exec haproxy -c -f {{ .src }}; \
\""
reload_cmd="haproxy -f /tmp/haproxy.cfg -p /var/run/haproxy.pid -D -sf \$(cat /var/run/haproxy.pid)"
EOF

cat << EOF > /etc/confd/templates/haproxy.cfg.tmpl
global
  maxconn 256
  user haproxy
  group haproxy
  log $LOG_HOST local0

defaults
  log global
  mode http
  balance roundrobin
  option forwardfor
  option http-server-close
  option abortonclose
  timeout connect 30s
  timeout client 30s
  timeout server 30s
  
listen stats 0.0.0.0:8080
  mode http
  log global
  maxconn 10
  clitimeout 100s
  srvtimeout 100s
  contimeout 100s
  timeout queue 100s
  stats enable
  stats hide-version
  stats refresh 30s
  stats show-node
  stats auth admin:admin
  stats uri /

frontend main
  bind *:80
  {{range gets "$SERVICES/*"}}
  {{\$key := base .Key}}
  acl {{\$key}} hdr_end(host) -i {{\$key}}
  use_backend {{\$key}} if {{\$key}}
  {{end}}
  
{{range gets "$SERVICES/*"}}
{{\$key := base .Key}}
backend {{\$key}}
  server {{\$key}} {{.Value}}
{{end}}
EOF

CONFD_OPTS="-interval=1 -verbose -keep-stage-file -debug"

confd -onetime -node "$ETCD_HOST" $CONFD_OPTS

echo "watching $SERVICES"

exec confd -node "$ETCD_HOST" $CONFD_OPTS
