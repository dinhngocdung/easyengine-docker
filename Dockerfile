FROM ubuntu:latest

# Cài đặt các phụ thuộc
RUN apt-get update && apt-get install -y \
    curl \
    docker.io \
    libcrypt1 \
    which \
    php \
    php-cli \
    php-curl \
    php-sqlite3 \
    php-zip \
    php-posix \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Cài đặt docker-compose v1
RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# Cài đặt EasyEngine
RUN curl -o /usr/local/bin/ee https://raw.githubusercontent.com/EasyEngine/easyengine-builds/master/phar/easyengine.phar \
    && chmod +x /usr/local/bin/ee

# Tạo thư mục làm việc
RUN mkdir -p /opt/easyengine
WORKDIR /opt/easyengine

# Thiết lập entrypoint là bash
CMD ["/bin/bash"]
