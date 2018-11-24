#!/bin/bash
command=$1

# change to config.sh directory
# source: https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $DIR

function merge() {

    local node=$1
    local in=$2
    local out=$3

#    echo -e "      * merging files for node: \e[100m${node}\e[0m"

    # create output dir for node
    if [ ! -d ${out}/${node} ]; then
        mkdir ${out}/${node}
    fi

    # read node name
    IFS='-' read -ra parts <<< "${node}"

    # loop through prefixes
    prefix=""
    for part in "${parts[@]}"; do
        prefix=$(echo "$prefix-$part" | sed "s/^-//g")
        if [ -d ${in}/${prefix} ]; then
            echo -e "        * merging prefix:        \e[32m${prefix}\e[0m" 
            
            # merge folders
            # 'shopt -s dotglib; cp ...' is supposed to enable dotfile merging; I tested it though, and it seems to work without shopt, too.
            # not sure if this is required  
            cp -RT ${in}/${prefix}/ ${out}/${node}
        else
            echo -e "        * prefix does not exist: \e[93m${prefix}\e[0m"
        fi
    done

}

function merge_init() {

    node=$1

    echo -e "  * merging configs for node:    \e[100m${node}\e[0m"

    # initializing via default
    echo "    * initializing with defaults:"
    merge $node ./_default _out

    # merge configs
    echo "    * merging configs:"
    merge $node . _out

}

function merge_all() {

    echo -e "* merging configs for \e[100mall nodes\e[0m"

    # reset output dir
    if [ -d _out ]; then
        rm -r _out
    fi
    mkdir _out

    # merging
    while IFS="" read -r node || [ -n "$node" ]; do
        merge_init $node
    done < all_nodes

}

function delete() {

    dst=${1}
    node=${2}

    # delete files across clusters
    echo -e "  * deleting on \e[100m${node}\e[0m: \e[101m${dst}\e[0m"
    ssh ${node} "rm -r ${dst}" < /dev/null
}

function delete_all() {

    dst=${1}
    echo -e "* deleting on \e[100mall nodes\e[0m: \e[101m${dst}\e[0m"
    while IFS="" read -r node || [ -n "$node" ]; do
        delete ${dst} ${node}
    done < all_nodes
}

function distribute() {

    node=${1}
    src=${2}
    dst=${3}

    echo -e "  * distributing config to:      \e[100m${node}\e[0m"

    # distribute files; deletion is not possible
    rsync -r ${src}/${node}/ ${node}:/app/

}

function distribute_all() {

    echo -e "* distributing config to: \e[100mall nodes\e[0m."

    # distributing
    while IFS="" read -r node || [ -n "$node" ]; do
        distribute $node ./_out /
    done < all_nodes

}

case "${command}" in

    md)
        node=${2}
        if [ -z "${node}" ]; then
            merge_all
            distribute_all
        else
            merge_init $node
            distribute $node _out /
        fi 
    ;;

    merge)
        node=${2}
        if [ -z "${node}" ]; then
            merge_all
        else
            merge_init $node
        fi
    ;;

    distribute)
        node=${2}
        if [ -z "${node}" ]; then
            distribute_all
        else
            distribute $node _out /
        fi
    ;;

    delete)
        dst=${2}
        node=${3}

        on=${3:-all nodes}
        echo -n -e "Are you you want to delete \e[101m${dst}\e[0m on \e[101m${on}\e[0m? [yY]"
        read -n 1 -r
        #echo    # (optional) move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo
            if [ -z "${node}" ]; then
                delete_all ${dst}
            else
                delete ${dst} ${node}
            fi
        else
            echo "* deletion cancelled"
        fi

    ;;

esac
