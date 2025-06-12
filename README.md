# easyengine-container
Install EasyEngine by Docker container, with any Distribution Linux

Requetment: Docker

Install:

```
docker run -it --rm --privileged \
  -v /var/run/docker.sock:/var/run/docker.sock:z \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  -v /etc/hosts:/etc/hosts \
  -v /opt/easyengine:/opt/easyengine \
  --network host \
  -w /opt/easyengine \
  ghcr.io/dinhngocdung/easyengine-container /bin/bash
```
