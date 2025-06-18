FROM ubuntu:latest

# Cài đặt các phụ thuộc
RUN apt-get update && apt-get install -y \
    curl \
    which \
    rsync \
    bash-completion \
    docker.io \
    php \
    php-cli \
    php-curl \
    php-sqlite3 \
    php-zip \
    php-posix \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Cài đặt docker-compose v2.27.0
RUN curl -L https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# Cài đặt EasyEngine
RUN curl -o /usr/local/bin/ee https://github.com/dinhngocdung/easyengine/releases/download/v4.8.1-custom-20250618-5cadaa8/easyengine.phar \
    && chmod +x /usr/local/bin/ee
    
# Cài đặt EasyEngine Tab Completion
RUN curl -sL -o /etc/bash_completion.d/ee \
       https://raw.githubusercontent.com/EasyEngine/easyengine/master/utils/ee-completion.bash \
    && chmod +x /etc/bash_completion.d/ee \
    && echo '[ -f /etc/bash_completion.d/ee ] && . /etc/bash_completion.d/ee' >> /root/.bashrc

# Tạo thư mục làm việc
RUN mkdir -p /opt/easyengine
WORKDIR /opt/easyengine

# Thiết lập entrypoint là bash
CMD ["/bin/bash"]
