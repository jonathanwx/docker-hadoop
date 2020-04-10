FROM openjdk:8u232-jdk

LABEL maintainer="jonathanlichi@gmail.com"

ARG HADOOP_VERSION=2.9.2

WORKDIR /tmp

RUN apt-get update && apt-get install -y openssh-server wget iputils-ping telnet dnsutils bzip2 ntp
RUN update-rc.d ntp defaults

RUN groupadd hadoop
RUN useradd -d /home/hadoop -g hadoop -m hadoop --shell /bin/bash

# SSH without key
RUN mkdir /home/hadoop/.ssh
RUN ssh-keygen -t rsa -f /home/hadoop/.ssh/id_rsa -P '' && \
    cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys

# Installing Hadoop
RUN wget https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz
RUN tar -xzvf hadoop-${HADOOP_VERSION}.tar.gz -C /usr/local/
RUN mv /usr/local/hadoop-${HADOOP_VERSION} /usr/local/hadoop
ENV HADOOP_HOME=/usr/local/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop

# Setting the PATH environment variable globally and for the Hadoop user
ENV PATH=$PATH:$JAVA_HOME/bin:/usr/local/hadoop/bin:/usr/local/hadoop/sbin
RUN echo "PATH=$PATH:$JAVA_HOME/bin:/usr/local/hadoop/bin:/usr/local/hadoop/sbin" >> /home/hadoop/.bashrc

# Hadoop configuration
COPY config/sshd_config /etc/ssh/sshd_config
COPY config/ssh_config /home/hadoop/.ssh/config
COPY config/hadoop-env.sh config/hdfs-site.xml config/hdfs-site.xml config/core-site.xml \
     config/core-site.xml config/mapred-site.xml config/yarn-site.xml config/yarn-site.xml \
     $HADOOP_CONF_DIR/

# Adding initialisation scripts
RUN mkdir $HADOOP_HOME/bin/init
COPY init-scripts/init-hadoop.sh $HADOOP_HOME/bin/init/
COPY init-scripts/start-hadoop.sh init-scripts/stop-hadoop.sh $HADOOP_HOME/bin/init/
COPY init-scripts/hadoop /etc/init.d/

# Adding utilities
RUN mkdir -p /home/hadoop/utils
COPY utils/run-wordcount.sh utils/format-namenode.sh /home/hadoop/utils/

# Replacing Hadoop slave file with provided one and changing logs directory
RUN rm $HADOOP_CONF_DIR/slaves
RUN ln -s /config/slaves $HADOOP_CONF_DIR/slaves

# Setting up log directories
RUN ln -s /data/logs/hadoop $HADOOP_HOME/logs
RUN ln -s $HADOOP_HOME/logs /var/log/hadoop

# Set permissions on Hadoop home
RUN chown -R hadoop:hadoop $HADOOP_HOME
RUN chown -R hadoop:hadoop /home/hadoop

# Cleanup
RUN rm -rf /tmp/*

WORKDIR /root

EXPOSE  2222 4040 8020 8030 8031 8032 8033 8042 8088 9001 50010 50020 50070 50075 50090 50100

# VOLUME /data
# VOLUME /config
# VOLUME /deployments


ENTRYPOINT ["service ssh start; bash"]
