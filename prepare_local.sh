function mk() {
    
    node=$1

    echo "Preparing folders for: ${node}"

    mkdir -p /tmp/docker/$node/data/a
    mkdir -p /tmp/docker/$node/data/b
    mkdir -p /tmp/docker/$node/data/c

    mkdir -p /tmp/docker/$node/data/zookeeper
    
    mkdir -p /tmp/docker/$node/logs

}

reset=${1}
init_flag=assets/manage/config/.initialized
id_rsa=assets/manage/config/id_rsa

if [ "${reset}" = "reset" ]; then
    rm -r /tmp/docker
    rm -r ${init_flag}
fi

# setup id_rsa
ssh-keygen -t rsa -b 4096 -P "" -f ${id_rsa}

# setup folders
mk node-master-1
mk node-worker-1
mk node-worker-2
mk node-worker-3
