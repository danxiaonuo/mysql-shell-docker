#############################
#     设置公共的变量         #
#############################
ARG BASE_IMAGE_TAG=20.04
FROM ubuntu:${BASE_IMAGE_TAG}

# 作者描述信息
MAINTAINER danxiaonuo
# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ
# 语言设置
ARG LANG=en_US.UTF-8
ENV LANG=$LANG
ARG LC_ALL=en_US.UTF-8
ENV LC_ALL=$LC_ALL

# 镜像变量
ARG DOCKER_IMAGE=danxiaonuo/mysql
ENV DOCKER_IMAGE=$DOCKER_IMAGE
ARG DOCKER_IMAGE_OS=ubuntu
ENV DOCKER_IMAGE_OS=$DOCKER_IMAGE_OS
ARG DOCKER_IMAGE_TAG=20.04
ENV DOCKER_IMAGE_TAG=$DOCKER_IMAGE_TAG

# mysql版本号
ARG MYSQL_MAJOR=8.0
ENV MYSQL_MAJOR=$MYSQL_MAJOR
ARG MYSQL_VERSION=${MYSQL_MAJOR}.28
ENV MYSQL_VERSION=$MYSQL_VERSION

# 工作目录
ARG MYSQL_DIR=/var/lib/mysql
ENV MYSQL_DIR=$MYSQL_DIR
# 数据目录
ARG MYSQL_DATA=/var/lib/mysql
ENV MYSQL_DATA=$MYSQL_DATA

# 环境设置
ARG DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_FRONTEND=$DEBIAN_FRONTEND

# 源文件下载路径
ARG DOWNLOAD_SRC=/tmp
ENV DOWNLOAD_SRC=$DOWNLOAD_SRC

# 安装依赖包
ARG PKG_DEPS="\
    locales \
    language-pack-zh-hans \
    zsh \
    bash \
    bash-completion \
    dnsutils \
    iproute2 \
    net-tools \
    ncat \
    git \
    vim \
    tzdata \
    curl \
    wget \
    axel \
    lsof \
    zip \
    unzip \
    rsync \
    iputils-ping \
    telnet \
    procps \
    libaio1 \
    numactl \
    xz-utils \
    gnupg2 \
    psmisc \
    libmecab2 \
    debsums \
    ca-certificates"
ENV PKG_DEPS=$PKG_DEPS

# ***** 安装依赖 *****
RUN set -eux && \
   # 更新源地址并更新系统软件
   apt-get update -qqy && apt-get upgrade -qqy && \
   # 安装依赖包
   apt-get install -qqy --no-install-recommends $PKG_DEPS && \
   apt-get -qqy --no-install-recommends autoremove --purge && \
   apt-get -qqy --no-install-recommends autoclean && \
   rm -rf /var/lib/apt/lists/* && \
   # 更新时区
   ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
   # 更新时间
   echo ${TZ} > /etc/timezone && \
   # 更改为zsh
   sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true && \
   sed -i -e "s/bin\/ash/bin\/zsh/" /etc/passwd && \
   sed -i -e 's/mouse=/mouse-=/g' /usr/share/vim/vim*/defaults.vim && \
   locale-gen en_US.UTF-8 && localedef -f UTF-8 -i en_US en_US.UTF-8 && locale-gen && \
   /bin/zsh
    
# ***** 拷贝文件 *****
COPY ["run.sh", "/run.sh"]

# ***** 下载 *****
RUN set -eux && \
    # 下载mysql
    wget --no-check-certificate https://cdn.mysql.com/Downloads/MySQL-8.0/libmysqlclient21_${MYSQL_VERSION}-1ubuntu20.04_amd64.deb \
    -O ${DOWNLOAD_SRC}/libmysqlclient21_${MYSQL_VERSION}-1ubuntu20.04_amd64.deb && \
    wget --no-check-certificate https://cdn.mysql.com/Downloads/MySQL-8.0/libmysqlclient-dev_${MYSQL_VERSION}-1ubuntu20.04_amd64.deb \
    -O ${DOWNLOAD_SRC}/libmysqlclient-dev_${MYSQL_VERSION}-1ubuntu20.04_amd64.deb && \
    wget --no-check-certificate https://cdn.mysql.com/Downloads/MySQL-8.0/mysql-client_${MYSQL_VERSION}-1ubuntu20.04_amd64.deb \
    -O ${DOWNLOAD_SRC}/mysql-client_${MYSQL_VERSION}-1ubuntu20.04_amd64.deb && \
    wget --no-check-certificate https://cdn.mysql.com/Downloads/MySQL-8.0/mysql-community-client_${MYSQL_VERSION}-1ubuntu20.04_amd64.deb \
    -O ${DOWNLOAD_SRC}/mysql-community-client_${MYSQL_VERSION}-1ubuntu20.04_amd64.deb && \
    wget --no-check-certificate https://cdn.mysql.com/Downloads/MySQL-8.0/mysql-community-client-core_${MYSQL_VERSION}-1ubuntu20.04_amd64.deb \
    -O ${DOWNLOAD_SRC}/mysql-community-client-core_${MYSQL_VERSION}-1ubuntu20.04_amd64.deb && \
    wget --no-check-certificate https://cdn.mysql.com/Downloads/MySQL-8.0/mysql-community-client-plugins_${MYSQL_VERSION}-1ubuntu20.04_amd64.deb \
    -O ${DOWNLOAD_SRC}/mmysql-community-client-plugins_${MYSQL_VERSION}-1ubuntu20.04_amd64.deb  && \   
    wget --no-check-certificate https://cdn.mysql.com/Downloads/MySQL-8.0/mysql-common_${MYSQL_VERSION}-1ubuntu20.04_amd64.deb \
    -O ${DOWNLOAD_SRC}/mysql-common_${MYSQL_VERSION}-1ubuntu20.04_amd64.deb && \
    wget --no-check-certificate https://cdn.mysql.com/Downloads/MySQL-Shell/mysql-shell_${MYSQL_VERSION}-1ubuntu20.04_amd64.deb \
    -O ${DOWNLOAD_SRC}/mysql-shell_${MYSQL_VERSION}-1ubuntu20.04_amd64.deb && \
    # 安装mysql-shell
    dpkg -i ${DOWNLOAD_SRC}/*.deb && chmod 775 /run.sh && \
    # 删除临时文件
    rm -rf /etc/my.cnf /etc/mysql /etc/my.cnf.d && \
    rm -rf /var/lib/apt/lists/* ${DOWNLOAD_SRC}/*.deb

# ***** 容器信号处理 *****
STOPSIGNAL SIGQUIT

# ***** 入口 *****
ENTRYPOINT ["/run.sh"]

# ***** 执行命令 *****
CMD ["mysqlsh"]
