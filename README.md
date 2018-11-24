# docker-cloud-stack
My solution to running HDFS, Zookeeper, Accumulo and Kafka on Docker. This might not be the most elegent version and its not 100% refined but it serves as a working example. The setup allows to locally start-up a multinode cluster on the fly. Porting it to a real cluster is pretty much straightforward (we did it :)). However, note that this config uses defaults whereever possible, so hardening the setup for production is still required. 

## Quickstart

```bash
# prepare
git clone https://github.com/mgbckr/docker-cloud-stack.git
cd docker-cloud-stack
bash build-docker.sh
prepare_local.sh

# start stack
docker stack deploy 

# connect to master
docker ps
docker exec -it <eva-master-1 NAME> bash

# on eva-master-1
bash manage.sh start_all
```

You can now attach containers to the `cloudnet` network and connect to the different services. 

## Related projects
