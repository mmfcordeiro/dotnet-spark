FROM ubuntu:18.04


RUN [ -z "$(apt-get indextargets)" ]
RUN set -xe \
   &&  echo '#!/bin/sh' > /usr/sbin/policy-rc.d \
   &&  echo 'exit 101' >> /usr/sbin/policy-rc.d \
   &&  chmod +x /usr/sbin/policy-rc.d \
   &&  dpkg-divert --local --rename --add /sbin/initctl \
   &&  cp -a /usr/sbin/policy-rc.d /sbin/initctl \
   &&  sed -i 's/^exit.*/exit 0/' /sbin/initctl \
   &&  echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup \
   &&  echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > /etc/apt/apt.conf.d/docker-clean \
   &&  echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> /etc/apt/apt.conf.d/docker-clean \
   &&  echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> /etc/apt/apt.conf.d/docker-clean \
   &&  echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/docker-no-languages \
   &&  echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/docker-gzip-indexes \
   &&  echo 'Apt::AutoRemove::SuggestsImportant "false";' > /etc/apt/apt.conf.d/docker-autoremove-suggests
RUN mkdir -p /run/systemd \
   &&  echo 'docker' > /run/systemd/container
CMD ["/bin/bash"]
ENV DAEMON_RUN=true
ENV SPARK_VERSION=2.4.4
ENV HADOOP_VERSION=2.7
ENV DOTNET_CORE_VERSION=2.1
ENV DOTNET_SPARK_VERSION=0.5.0
ENV SPARK_HOME=/spark
ENV DOTNET_WORKER_DIR=/dotnet/Microsoft.Spark.Worker-${DOTNET_SPARK_VERSION}
ENV PATH=/spark/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV SPARK_MASTER_PORT=7077
ENV SPARK_MASTER_WEBUI_PORT=8080
ENV SPARK_WORKER_PORT=7078
ENV SPARK_WORKER_WEBUI_PORT=8081
ENV SPARK_WORKER_INSTANCES=2
RUN apt-get update \
   &&  apt-get install -y wget ca-certificates openjdk-8-jdk bash software-properties-common vim supervisor \
   &&  mkdir -p /dotnet/HelloSpark \
   &&  wget http://mirror.netcologne.de/apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
   &&  tar -xvzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
   &&  mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark \
   &&  rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
   &&  wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
   &&  dpkg -i packages-microsoft-prod.deb \
   &&  add-apt-repository universe \
   &&  apt-get install -y apt-transport-https \
   &&  apt-get update \
   &&  apt-get install -y dotnet-sdk-${DOTNET_CORE_VERSION} \
   &&  apt-get clean \
   &&  rm -rf /var/lib/apt/lists/* \
   &&  rm -rf packages-microsoft-prod.deb \
   &&  wget https://github.com/dotnet/spark/releases/download/v${DOTNET_SPARK_VERSION}/Microsoft.Spark.Worker.netcoreapp${DOTNET_CORE_VERSION}.linux-x64-${DOTNET_SPARK_VERSION}.tar.gz \
   &&  tar -xvzf Microsoft.Spark.Worker.netcoreapp${DOTNET_CORE_VERSION}.linux-x64-${DOTNET_SPARK_VERSION}.tar.gz \
   &&  mv Microsoft.Spark.Worker-${DOTNET_SPARK_VERSION} /dotnet/ \
   &&  rm Microsoft.Spark.Worker.netcoreapp${DOTNET_CORE_VERSION}.linux-x64-${DOTNET_SPARK_VERSION}.tar.gz
COPY ./dotnet/HelloSpark /dotnet/HelloSpark
COPY ./etc/supervisor.conf /etc/supervisor.conf
EXPOSE 6066 7077 8080 8081 8082 9900-9999
CMD /usr/bin/supervisord -c /etc/supervisor.conf
RUN /spark/sbin/start-shuffle-service.sh
