command=${1}

# change to config.sh directory
# source: https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $DIR

function print() {
    echo
    echo "#### "
    echo "#### ${1}"
    echo "#### "
}

init_flag="/app/config/.initialized"
function start_all() {


    print "Setting up an distributing config"
    bash config/config.sh md

    if [ ! -f ${init_flag} ]; then
        print "Initializing HDFS"
        hdfs init
    fi 

    print "Starting HDFS"
    hdfs start

    print "Starting Zookepper"
    zookeeper start

    print "Waiting for Zookepper to start (sleep 10 seconds)"
    sleep 10

    print "Starting Kafka"
    kafka start

    if [ ! -f ${init_flag} ]; then
        print "Initializing Accumulo"
        accumulo init
    fi

    print "Starting Accumulo"
    accumulo start

    if [ ! -f ${init_flag} ]; then
        print "Set .initialized flag: ${init_flag}"
        touch ${init_flag}
    fi
}

function stop_all() {

    print "Stopping Kafka"
    kafka stop

    print "Stopping accumulo"
    accumulo stop


    print "Waiting for Kafka and Accumulo to safely shut down (sleep 10 seconds) "
    sleep 10

    print "Stopping Zookeeper"
    zookeeper stop

    print "Stopping HDFS"
    hdfs stop
}

function hdfs() {

    case "$1" in
        init)
            /app/services/hadoop/bin/hdfs namenode -format -nonInteractive
        ;;
        start)
            /app/services/hadoop/sbin/start-dfs.sh
        ;;
        stop)
            /app/services/hadoop/sbin/stop-dfs.sh
        ;;
    esac
}

function zookeeper() {

    case "$1" in
        start)
            for w in $(cat /app/services/hadoop/etc/hadoop/workers); do
                ssh $w /app/services/zookeeper/bin/zkServer.sh start
            done
        ;;
        stop)
            for w in $(cat /app/services/hadoop/etc/hadoop/workers); do
                ssh $w /app/services/zookeeper/bin/zkServer.sh stop
            done
        ;;
    esac
}

function kafka() {

    case "$1" in
        start)
            for w in $(cat /app/services/hadoop/etc/hadoop/workers); do
                ssh $w "source /app/services/kafka/config/kafka-env.sh; /app/services/kafka/bin/kafka-server-start.sh -daemon /app/services/kafka/config/server.properties"
            done
        ;;
        stop)
            for w in $(cat /app/services/hadoop/etc/hadoop/workers); do
                ssh $w "/app/services/kafka/bin/kafka-server-stop.sh"
            done
        ;;
    esac
}

function accumulo() {

    cmd=$1
    instance=$2
    password=$3

    case "$cmd" in
        init)
            /app/services/accumulo/bin/accumulo init --instance-name $instance --password $password
        ;;
        start)
            /app/services/accumulo/bin/start-all.sh
        ;;
        stop)
            /app/services/accumulo/bin/stop-all.sh
        ;;
    esac
}

function config() {
    bash config/config.sh "${@}"
}

${command} "${@:2}"