# args
ARG user_id=999
ARG group_id=999

ARG user_name=cluster
ARG group_name=cluster

###########################################
# build stage
###########################################
FROM java:8 as build

# args
ARG user_id
ARG group_id
ARG user_name
ARG group_name

# get files
WORKDIR /app
COPY Dockerfile.build.sh /app

# run build
RUN ls -al; bash /app/Dockerfile.build.sh
RUN apt-get update; apt-get install -y make g++; ls .; ./services/accumulo/bin/build_native_library.sh


###########################################
# deploy
###########################################
FROM java:8

# args
ARG user_id
ARG group_id
ARG user_name
ARG group_name

# for debugging
RUN apt-get update; apt-get install -y less vim dnsutils net-tools; echo "alias ll='ls -la'" | tee -a /root/.bashrc /etc/skel/.bashrc

# set workdir
WORKDIR /app

# creating a user
RUN echo "Creating user ${user_name} (${user_id}) in group ${group_name} (${group_id})." ; \
    groupadd -g ${group_id} ${group_name} ; \
    useradd -r -u ${user_id} -g ${group_name} -s /bin/bash -m ${user_name}

# ssh
RUN apt-get install -y sudo openssh-server rsync; mkdir /var/run/sshd; \
    echo "%${user_name} ALL= NOPASSWD: /usr/sbin/sshd" >> /etc/sudoers; \
    echo "%${user_name} ALL= NOPASSWD: /usr/sbin/sshd -D" >> /etc/sudoers; \
    echo "%${user_name} ALL= NOPASSWD: /usr/sbin/service ssh status" >> /etc/sudoers; \
    echo "%${user_name} ALL= NOPASSWD: /usr/sbin/service ssh start" >> /etc/sudoers; \
    echo "%${user_name} ALL= NOPASSWD: /usr/sbin/service ssh stop" >> /etc/sudoers; \
    mkdir -p /home/${user_name}/.ssh; \
    yes y | ssh-keygen -t rsa -b 4096 -P "" -f /home/${user_name}/.ssh/id_rsa; \
    chown -R ${user_name}:${user_name} /home/${user_name}/.ssh; \
    cat /home/${user_name}/.ssh/id_rsa.pub >> /home/${user_name}/.ssh/authorized_keys; \
    echo "Host *\n    LogLevel=error\n    StrictHostKeyChecking=no\n    UserKnownHostsFile=/dev/null" >> /home/${user_name}/.ssh/config

# copy files
COPY --from=build /app/services /app/services
#COPY run.sh /app
#COPY config /app/config

# own app dir
# this is essentially as expensive as the original COPY instruction (with regard to image size)
# cloud be resolved after this bug is fixed: https://github.com/moby/moby/issues/35018
RUN echo "Owning /app directory. This may take a while ..." ; \
    chown -R ${user_name}:${user_name} /app

# switch to user
USER ${user_name}

# start ssh server as main process
CMD [ "/usr/sbin/sshd", "-D" ]