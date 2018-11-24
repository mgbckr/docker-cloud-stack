#!/bin/bash

# params
hadoop_version=3.1.1
zookeeper_version=3.4.13
kafka_version=2.0.0
accumulo_version=1.9.2

# functions
function download {

    url=$1
    filename=$2
    out=$3
    destination=$4

    # download and extract
    if [ ! -d ${destination} ]; then
        wget ${url}/${filename}
        tar -xzf ${filename}
        rm ${filename}
        mkdir -p ${destination}
        mv ${out}/* ${destination}
    else
        echo "'${destination}' already exists."
    fi
}

#
# HDFS
#
download "http://mirror.synyx.de/apache/hadoop/common/hadoop-${hadoop_version}" \
    hadoop-${hadoop_version}.tar.gz \
    hadoop-${hadoop_version} \
    services/hadoop

#
# Zookeeper
#
download "http://ftp-stud.hs-esslingen.de/pub/Mirrors/ftp.apache.org/dist/zookeeper/zookeeper-${zookeeper_version}" \
    zookeeper-${zookeeper_version}.tar.gz \
    zookeeper-${zookeeper_version} \
    services/zookeeper

#
# Kafka
#
download "http://ftp.halifax.rwth-aachen.de/apache/kafka/${kafka_version}" \
    kafka_2.11-${kafka_version}.tgz \
    kafka_2.11-${kafka_version} \
    services/kafka

#
# Accumulo
#
download "http://mirrors.ae-online.de/apache/accumulo/${accumulo_version}" \
    accumulo-${accumulo_version}-bin.tar.gz \
    accumulo-${accumulo_version} \
    services/accumulo

# get commons conifguation (1) lib which Accumulo requires and Hadoop 3 is not providing
if [ ! -f "services/accumulo/lib/commons-configuration-1.10.jar" ]; then 
    cd services/accumulo/lib
    wget http://apache.mirror.digionline.de//commons/configuration/binaries/commons-configuration-1.10-bin.tar.gz
    tar -xzf commons-configuration-1.10-bin.tar.gz
    cp commons-configuration-1.10/commons-configuration-1.10.jar .
    rm -r commons-configuration-1.10
    rm -r commons-configuration-1.10-bin.tar.gz
    cd -
fi

