# Fixing this issue: https://issues.apache.org/jira/browse/KAFKA-4931
SIGNAL=${SIGNAL:-TERM}
PIDS=$(jps | grep -i 'Kafka' | awk '{print $1}')

if [ -z "$PIDS" ]; then
  echo "No kafka server to stop"
  exit 1
else
  kill -s $SIGNAL $PIDS
fi
