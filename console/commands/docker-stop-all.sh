#!/usr/bin/env bash
set -euo pipefail

source "$COMPONENTS_DIR"/print_message.sh
source "$COMPONENTS_DIR"/input_info.sh

running_containers=$(docker ps -q)

if [[ "$running_containers" != "" ]]; then
    print_info "Stopping running containers\n"
    docker stop $running_containers
else
    print_warning "No containers running"
fi
