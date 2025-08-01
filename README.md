<img src="https://easyengine.pages.dev/images/easyeengine-docker-gray.svg" alt="Easyengine-Docker" width="auto" height="500" style="display: block; margin-left: 0; margin-right: auto;">

# EasyEngine Docker

## Quick guide

```bash
# Ready to run easyengine with alias ee
sudo mkdir-p /opt/easyengine && \
sudo curl -o /opt/easyengine/docker-compose.yml https://raw.githubusercontent.com/dinhngocdung/easyengine-docker/master/docker-compose.yml && \
sudo curl -o /opt/easyengine/easyengine-wrapper https://raw.githubusercontent.com/dinhngocdung/easyengine-docker/refs/heads/main/easyengine-wrapper && \
sudo chmod +x /opt/easyengine/easyengine-wrapper && \
sudo ln -s /opt/easyengine/easyengine-wrapper /usr/local/bin/ee

# Use same way easyeinge command native, sample:
ee cli info
```

## Deploy on any Linux distribution

The **EasyEngine** container, allowing you to deploy and use EasyEngine on **any Linux distribution**, not just the officially supported Debian/Ubuntu.

It works well with systems like:

* CentOS, RHEL, AlmaLinux
* Arch, OpenSUSE, Fedora
* Minimal/container-focused OSes like:
  **Fedora CoreOS**, **OpenSUSE Leap Micro**, **Alpine**, etc.

## System Requirements

Docker must be installed and running

Check if Docker is installed:

```bash
sudo docker version
```

## What’s in this easyengine image docker?
1. Ubuntu base (latest)
2. Docker compose v2.27.0
3. PHP
4. EasyEngine (customzed for container)
5. Easyengine Tab Completion
6. `tmux`, `rsync`, `rclone`...

## How to Deploy

Run the following command to launch the EasyEngine Docker:

```bash
sudo docker run -it --rm --privileged \
  -v /var/run/docker.sock:/var/run/docker.sock:z \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  -v /opt/easyengine:/opt/easyengine \
  -v /etc/localtime:/etc/localtime:ro \
  -v /opt/easyengine/.ssh-key:/root/.ssh \
  --network host \
  --name easyengine \
  dinhngocdung/easyengine:latest
```

### Explanation of Parameters:

| Parameter                 | Description                                                         |
| ------------------------- | ------------------------------------------------------------------- |
| `--privileged`            | Allows the container to interact with Docker on the host            |
| `--rm`                    | Automatically removes the container when it exits                   |
| `-v /var/run/docker.sock` | Grants access to Docker daemon from within the container            |
| `-v /opt/easyengine`      | Stores EasyEngine configs and website data persistently on the host |
| `--network host`          | Ensures services like web/db run properly with host networking      |
| `-v /etc/localtime `      | Sync time of host and container                                     |

## How to Use

Once inside the container (`easyengine`), you can use EasyEngine commands as usual.

Example Commands:

```bash
ee site create example.com --type=wp
ee site list
ee site disable example.com
ee site delete example.com
```

To exit the container, type:

```bash
exit
```

This will return you to the host OS and the container will be automatically removed.
However, all your EasyEngine data and websites remain **intact** on the host under `/opt/easyengine`.


Whenever you need to use EasyEngine, just **rerun the [`docker run` debloy](#how-to-deploy) command** to launch a new container environment instantly.


## Use Docker Compose

First, download the `docker-compose.yml` configuration file to `/opt/easyengine` :

```bash
sudo mkdir-p /opt/easyengine && \
sudo curl -o /opt/easyengine/docker-compose.yml https://raw.githubusercontent.com/dinhngocdung/easyengine-docker/master/docker-compose.yml
```

To run the container and start using EasyEngine

```bash
sudo docker compose -f /opt/easyengine/docker-compose.yml run --rm easyengine
```

## Use `ee` "native"

Create syslink warpper:
```bash
sudo curl -o /opt/easyengine/easyengine-wrapper https://raw.githubusercontent.com/dinhngocdung/easyengine-docker/refs/heads/main/easyengine-wrapper && \
sudo chmod +x /opt/easyengine/easyengine-wrapper && \
sudo ln -s /opt/easyengine/easyengine-wrapper /usr/local/bin/ee
```
Then, you can run `ee` command same "native"
```bash
#you can run EasyEngine commands such as:
ee site list
ee site create sample.com
ee cron list --all
```

## What’s in this Repo?

* A `Dockerfile` for building the `dinhngocdung/easyengine:latest` image, based on Ubuntu with EasyEngine CLI and all required dependencies pre-installed
* `docker-compose.yml` for use docker compose


## Sync/Clone

`Sync/Clone` is designed for interaction between EasyEngine installations directly on the host. For these commands to work with `easyengine`, you need the following:

### Local easyengine-docker

Create ssh-key for connect remote easyengine

```
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
ssh-copy-id -i ~/.ssh/id_ed25519.pub YOUR-USER@YOUR-REMOTE-SERVER.com
```

### Remote easyengine Host

If remote easyeinge on remote host, it normaly. And if user `root` locked, also easyengine clone reque connect by root, you must forward `YOUR-USER` to `root`:
 ```bash
 vi /home/YOUR-USER/.ssh/authorized_keys
 ```
 
 Add command=... befor ssh-...
 ```bash
 command="if [ -n \"$SSH_ORIGINAL_COMMAND\" ]; then sudo -i bash -c \"$SSH_ORIGINAL_COMMAND\"; else sudo -i; fi" ssh-....
 ```
If remote easyengine also on container, you need foward ssh into `easyengine`

1.  Create a bash Script `/usr/local/bin/ssh_to_ee_container.sh` to forward `ssh` and `rsync` commands:
    ```bash
    #!/bin/bash

    # Name of the Docker container you want to connect to
    CONTAINER_NAME="easyengine"

    # Check if a command was passed via SSH_ORIGINAL_COMMAND
    if [ -n "$SSH_ORIGINAL_COMMAND" ]; then
        docker exec -i "$CONTAINER_NAME" /bin/bash -c "$SSH_ORIGINAL_COMMAND"
    else
        if [ -n "$SSH_TTY" ]; then
            docker exec -it "$CONTAINER_NAME" /bin/bash
        else
            docker exec -i "$CONTAINER_NAME" /bin/bash
        fi
    fi
    ```
2.  Edit `~/.ssh/authorized_keys` on the remote host to run `ssh_to_ee_container.sh` when access by ssh-key:
    ```bash
    vi ~/.ssh/authorized_keys
    ```
    Insert `command="/usr/local/bin/ssh_to_ee_container.sh"` beford `ssh-...`
    ```bash
    command="/usr/local/bin/ssh_to_ee_container.sh" ssh-ed25519 AAAAB3NzaC1yc2EAAAADAQABAAABAQ... your_key_comment_or_email
    ```
    
## Reference
- EasyEngine [Official Site](https://easyengine.io/)
- My [Easyengine Notes](https://easyengine.pages.dev/)
- [Dockerfile](https://github.com/dinhngocdung/easyengine-docker/blob/main/Dockerfile)
