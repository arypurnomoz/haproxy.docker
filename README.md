# Usage

ETCD_HOST variable is required

```sh
docker run \
  -e SERVICES=/etcd/dir \
  -e LOG_HOST=localhost \
  -e ETCD_HOST=localhost:4001 \
  arypurnomoz/haproxy
```
