# docker-cloud-stack
My take on running [Hadoop's HDFS](https://hadoop.apache.org/), [Zookeeper](https://zookeeper.apache.org/), [Kafka](https://kafka.apache.org/) and [Accumulo](https://accumulo.apache.org/) on [Docker](https://www.docker.com/) (see below for alternatives). The setup allows to locally start-up a multi-node cluster on the fly. Porting it to a real cluster is pretty much straightforward (we did it :)). This might not be the most elegant approaches and its not 100% refined but it serves as a working example. Also, note that this config uses defaults where ever possible, so hardening the setup for production is still required. Overall, this setup should still be a good starting point to get the above mentioned stack up and running via Docker.

## Quickstart

### Preparation
```bash
# setup Docker swarm (if not already done so)
docker swarm init --advertise-addr=<your ip>

# prepare
git clone https://github.com/mgbckr/docker-cloud-stack.git
cd docker-cloud-stack
bash build-docker.sh
bash prepare_local.sh reset
```

### Start
```bash
# start stack
docker stack deploy -c docker-compose.yml cloud-stack

# connect to master
docker ps
docker exec -it <node-master-1 NAME> bash

# on node-master-1 (on the first run, you will need to type in a new password for Accumulo's root user)
bash manage.sh start_all
```

You can now attach containers to the `cloudnet` network and connect to the different services. 

### Shut down
```bash
# connect to master
docker ps
docker exec -it <node-master-1 NAME> bash

# on node-master-1
bash manage.sh stop_all
exit

# on docker host
docker stack rm cloud-stack 
```

Note that you can restart the cluster and all your data will be kept if nothing went wrong.

## Cluster (swarm) deployment
The only thing you really have to do to run this on a actual docker swarm is setting the correct placement constraints for each node and adjusting the volume mappings.


## Adding a worker node

For adding a worker node `node-worker-4` encompasses:

* append `node-worker-4` to the file `all_nodes`
* Hadoop:
    * append `node-worker-4` to `node-master-1/app/hadoop/etc/hadoop/workers`
* Zookeeper:
    * append `server.4=node-worker-4:2889:3889` to `node-worker/app/zookeeper/conf/zoo.cfg`
    * add `node-worker-4/data/zookeeper/myid` with content `4`
* Kafka:
    * copy `node-worker-1/app/kafka/config/server.properties` to `node-worker-4/app/kafka/config/server.properties` and change `broker.id=1` to `broker.id=4`
    * in ALL `node-worker-X/app/kafka/config/server.properties` add `node-worker-4:2181` to the comma separated list `zookeeper.connect=` 
 * Accumulo:
    * in `node/app/accumulo/conf/accumulo-site.xml` add `node-worker-4:2181` to `instance.zookeeper.host`
    * in `node-master/app/accumulo/conf/slaves` append `node-worker-4`


## Config

Configuring the cluster happens through the master node by distributing the files in the config folder across all nodes based on their host names. This approach allows to easily integrate new services with custom configs and also enables overwriting binary files or adding custom libraries without redeploying the Docker stack.

### General approach

The configuration approach is based on a hierarchical overlay system using host names (uhhh, sounds so fancy :)).
In other words, the configs are put together from a set of folders which are prefixes of those host names.
That is, all folders which are a prefix (defined by a dash `-`) are merged together whereas files from longer folder names overwrite those from shorter folder names. 
Additionally, the files from the `_default` folder are used for initialization.

#### Example

Let us consider "node-worker-1" for which we build the final config in some temporary folder called `_tmp`.

Initialization

* copy files from `_defaults/node` to `_tmp`
* copy files from `_defaults/node-worker` to `_tmp` overwriting existing files
* copy files from `_defaults/node-worker-1` to `_tmp` overwriting existing files

Config

* copy files from `node` to `_tmp` overwriting existing files
* copy files from `node-worker` to `_tmp` overwriting existing files
* copy files from `node-worker-1` to `_tmp` overwriting existing files

Thus, files from `_defaults` are used as an initialization whereas files from longer folder names overwrite files from shorter folder names. Afterwards the actual config files (not in `_defaults`) overwrite these files using the same procedure.   

## Versions
I built this on
```
Docker version 18.06.1-ce, build e68fc7a
```

The current versions of the applications are:
```
hadoop_version=3.1.1
zookeeper_version=3.4.13
kafka_version=2.0.0
accumulo_version=1.9.2
```
You can change the application versions in the `assets/build/Dockerfile.build.sh`. Note, however, that this may require changing the configs corresponding to the specific versions as well as may updating the download script `assets/build/Dockerfile.build.sh`.

## TODOs
Some TODOs which I would really like someone else to do :D

* adjust swapiness to 0 for Accumulo (keeps complaining on startup)
* clean up, document, and unify scripts
* expose some ports to the world (e.g., 50070 to check the status of the HDFS)
* optimize CLI of `manage.sh`
* replace timeouts with actual checks in start up sequence (`manage.sh`)
* optimize `run.sh` for graceful shutdown of the cluster when `docker stack rm` is called (even though this might not be possible because currently the first thing Docker does when that command is issued is detaching the network ... grr)
* Also see further notes in `docker-compose.yml`
* Maybe allow to run each service on it's own container, e.g., for better resource management?
* clean and optimize configs?
    * Add the possibility for templates in order to easy the burden on adding worker nodes, e.g., using `envsubst`. Right now, for example, the `myid` files for Zookeeper nodes or even worse the `server.properties` files for Kafka brokers are not nice to manage. We currently did not do this for stability reasons since the corresponding scripts will be more complicated and thus harder to test.
    * Add the concept of roles. Currently we have a strict hierarchy based on host names. Maybe, just maybe, it may make more sense to introduce roles in order to encapsulate configs by role instead of by host names for more flexibility.
    * If we continue this we will get something like [Ambari](https://ambari.apache.org/) ;)


## Background and notes
Here are some random (probably too short) notes for later reference. They may explain some choices I made for this project. Note that I am new to Docker! Thus, please feel free to discuss and provide comments and suggestions via the issue tracker!

### Startup and configuration
I opted to configure and start the cluster from the master node manually rather than using any Docker based configuration or automatic start-up. Some justifications:

* Using Dockers config functionality would have blown up the `docker-compose.yml` file like crazy: When changing a config file, either all config files would change, causing a reboot for all nodes, which is not desirable in a production scenario. To solve this it would have been required to add a massive amount of config entries with different environment variables for each file and each node ().  
* Using volumes, would also blow up the the `docker-compose.yml` and I would have needed a NFS or something the like to mount into each container.
* Similar things are true for coming up with an (arguable pretty nice) system similar to [big-data-europe/docker-hadoop](https://github.com/big-data-europe/docker-hadoop) which allows to configure everything via environment variables. I like it, but considering all the different services with their own configuration variants, the current approach seemed to be the most simple while being perfectly extensible and versatile (see, e.g., the cababilities to also overwrite binary files: `assets/manage/config/node-worker/services/kafka/bin/kafka-server-stop.sh`).
* Finally I really wanted the cluster to start and stop automatically with `docker stack deploy` and `docker stack rm`. However, shutting down automatically in a safe way is not possible since the first thing Docker does when `docker stack rm` is issued seems to be detaching the network. Thus a organized shutdown across several nodes is not possible. Consequently, in order to not imply that the cluster will automatically shut down, I opted for a manual startup as well.

### Docker's replication
At first I wanted to use Docker's replication to manage worker nodes dynamically. Turns out this does not work because the hostnames will not be fixed which is required for the services I run.

### Docker's virtual IP system
This drove me crazy! So it seems that when using virtual IPs (VIPs), the host that is contacted always thinks it is contacted by the gateway responsible for handling those VIPs (mostly the IP ending in .2) instead of the actual host. That's why my nodes use `dnsrr`. I figure that this HAS to be a bug.

## Related projects
Among others, I got inspired by these projects:
* https://github.com/sequenceiq/hadoop-docker
* https://github.com/big-data-europe/docker-hadoop
