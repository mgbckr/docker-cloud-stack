docker_image_name=docker-cloud-stack

user_name=${USER}
user_id=`id -u ${user_name}`
group_name=${user_name}
group_id=`id -g ${user_name}`
echo "Building Dockerfile for ${user_name} (${user_id}) in group ${group_name} (${group_id})."

# build docker image
docker build \
    --build-arg user_name=${user_name} \
    --build-arg user_id=${user_id} \
    --build-arg group_name=${group_name} \
    --build-arg group_id=${group_id} \
    -t $docker_image_name -f Dockerfile ./assets/build
