#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${apiserver_endpoint}' --b64-cluster-ca '${cluster_ca}' --kubelet-extra-args '${kubelet_extra_args}' --enable-docker-bridge '${enable_docker_bridge}' '${name}'
