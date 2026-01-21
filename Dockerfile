FROM ubuntu:latest

LABEL org.opencontainers.image.authors="Đinh Ngọc Dũng"
LABEL org.opencontainers.image.title="easyengine-docker"
LABEL org.opencontainers.image.version="latest"
LABEL org.opencontainers.image.description="Easyengine in Docker"
LABEL org.label-schema.url="https://easyengine.pages.dev/notes/easyengine-docker/"

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    which \
    rsync \
    rclone \
    zip \
    p7zip-full \
    unzip \
    bash-completion \
    tmux \
    docker.io \
    php \
    php-cli \
    php-curl \
    php-sqlite3 \
    php-zip \
    php-posix \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install docker-compose v2.27.0
RUN curl -L https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose

# Install EasyEngine customzed for container
RUN curl -L -o /usr/local/bin/ee https://github.com/dinhngocdung/easyengine/releases/latest/download/easyengine.phar \
    && chmod +x /usr/local/bin/ee

# Install EasyEngine Tab Completion
RUN curl -sL -o /etc/bash_completion.d/ee \
       https://raw.githubusercontent.com/EasyEngine/easyengine/master/utils/ee-completion.bash \
    && chmod +x /etc/bash_completion.d/ee \
    && echo '[ -f /etc/bash_completion.d/ee ] && . /etc/bash_completion.d/ee' >> /root/.bashrc

# Create working directory
RUN mkdir -p /opt/easyengine
# Tạo thư mục cấu hình và copy các file mẫu vào image
RUN mkdir -p /opt/easyengine/config/rclone

# Copy default local backup config files from repository into image
COPY templates/config/rclone/rclone.conf /opt/easyengine/config/rclone/rclone.conf
COPY templates/config/config.yml /opt/easyengine/config/config.yml

# Set permissions
RUN chmod 644 /opt/easyengine/config/rclone/rclone.conf /opt/easyengine/config/config.yml || true

WORKDIR /opt/easyengine

# Customize prompt
RUN echo 'PS1="[\[\e[37m\]easyengine: \w\[\e[0m\]]$ "' >> /root/.bashrc

# Set entrypoint to bash
CMD ["/bin/bash"]
