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

# Install EasyEngine customzed for container
RUN curl -L -o /usr/local/bin/ee https://github.com/dinhngocdung/easyengine/releases/latest/download/easyengine.phar \
    && chmod +x /usr/local/bin/ee

# Install EasyEngine Tab Completion
RUN curl -sL -o /etc/bash_completion.d/ee-completion.bash https://raw.githubusercontent.com/EasyEngine/easyengine/master/utils/ee-completion.bash


# Create working directory
RUN mkdir -p /opt/easyengine
WORKDIR /opt/easyengine

# Set entrypoint to bash
CMD ["/bin/bash"]
