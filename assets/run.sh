context=${1:-none}
node_id=${2:-0}
run_lock=/app/run.lock

accumulo_user=${ACCUMULO_USER:-root}
accumulo_password=${ACCUMULO_PASSWORD:-test}

#source manage/manage.sh
# function _init() {

#     case "${context}" in
#         master)
#             echo "Starting master"

#             # wait for data nodes to come up (start SSH)
#             sleep 10

#             # handle config files
#             /app/config config.sh distribute

#             # hdfs
#             if [ ! -f /app/data/.initialized ]; then
#                 hdfs init
#             fi
#             hdfs start

#             # zookeeper
#             zookeeper start

#             # wait for zookeeper to stabilize
#             sleep 10

#             # kafka
#             kafka start

#             # accumulo
#             if [ ! -f /app/data/.initialized ]; then
#                 accumulo init
#             fi 
#             accumulo start ${accumulo_user} ${accumulo_password}
#         ;;
#         worker)
#             echo "Starting node (nothing to do since we will be waiting for commands from the master)"

#             # delete config files since they should only reside on the master
#             rm -r /app/config
#         ;;
#         *)
#         ;;
#     esac 

#     if [ ! -f /app/data/.initialized ]; then
#         touch /app/data/.initialized
#     fi

# }

function _term() {

    # TODO: here we should try to prevent damage when e.g. docker stack rm is called without previously shutting down all services
    echo "Shutdown sequence initiated. Context: ${context}"
    
    case "${context}" in
        master)
            echo "Shutting down master"
        ;;
        worker)
            echo "Shutting down worker"
        ;;
        *)
        ;;
    esac 

    # TODO: should wait until all processes are closed (e.g., using PIDs) in order to ensure that this node ist shutdown correctly from the manager
    exit 0
}

# start ssh service
sudo service ssh start

# init 
# _init

# trap SIGTERM
trap _term SIGTERM
trap _term SIGINT

# start loop
touch ${run_lock}
while [ -f "${run_lock}" ]; do
    sleep 1
done
echo "Run lock missing (${run_lock}). Done."

