FROM ubuntu:latest

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    which \
    rsync \
    docker.io \
    php \
    php-cli \
    php-curl \
    php-sqlite3 \
    php-zip \
    php-posix \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install docker-compose v1.29.2
RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# Install EasyEngine
RUN curl -o /usr/local/bin/ee https://raw.githubusercontent.com/EasyEngine/easyengine-builds/master/phar/easyengine.phar \
    && chmod +x /usr/local/bin/ee

# Create working directory
RUN mkdir -p /opt/easyengine
WORKDIR /opt/easyengine

# Set entrypoint to bash
CMD ["/bin/bash"]