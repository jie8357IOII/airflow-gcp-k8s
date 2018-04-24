# VERSION 1.9.0-2
FROM python:2.7-slim
MAINTAINER jie8357ioii

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
ARG AIRFLOW_VERSION=1.9.0
ARG AIRFLOW_HOME=/usr/local/airflow

# Spark
ARG SPARK_VER=spark-2.1.2
ARG HADOOP_VER=hadoop2.6
ARG SPARK_TARBALL_URL=http://ftp.twaren.net/Unix/Web/apache/spark/${SPARK_VER}/${SPARK_VER}-bin-${HADOOP_VER}.tgz

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

RUN set -ex \
    && buildDeps=' \
        python-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        build-essential \
        libblas-dev \
        liblapack-dev \
        libpq-dev \
        git \
    ' \
    && apt-get update -yqq \
    && apt-get upgrade -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        python-pip \
        python-requests \
        apt-utils \        
        curl \
        rsync \
        netcat \
        locales \
        libmysqlclient-dev \ 
        mysql-client \
        wget \
        tar \
        pandoc \ 
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && pip install -U pip setuptools wheel \
    && pip install MySQL-python \
    && pip install Cython \
    && pip install pytz \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install apache-airflow==$AIRFLOW_VERSION \    
    && pip install pypandoc \
    && pip install apache-airflow[celery,mysql]==$AIRFLOW_VERSION \
    && pip install celery[redis]\
    && apt-get purge --auto-remove -yqq $buildDeps \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base


RUN wget -q -O /tmp/${SPARK_VER}-bin-${HADOOP_VER}.tgz ${SPARK_TARBALL_URL} \
    && tar zxf /tmp/${SPARK_VER}-bin-${HADOOP_VER}.tgz -C /tmp/ \
    && mv /tmp/${SPARK_VER}-bin-${HADOOP_VER} /usr/lib/spark \
    && cd /usr/lib/spark/python && python setup.py install
RUN rm -f /tmp/${SPARK_VER}-bin-${HADOOP_VER}.tgz

COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

RUN mkdir -p ${AIRFLOW_HOME}/dags 
COPY dags/*  ${AIRFLOW_HOME}/dags

RUN chown -R airflow: ${AIRFLOW_HOME}

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["/entrypoint.sh"]
