#!/usr/bin/env bash

set -euo pipefail

identifier="$(< /dev/urandom tr -dc 'a-z0-9' | fold -w 5 | head -n 1)" ||:
NAME="compute-node-sim-${identifier}"
base_dir="$(dirname "$(readlink -f "$0")")"

function cleanup() {
    container_id=$(docker inspect --format="{{.Id}}" "${NAME}" ||:)
    if [[ -n "${container_id}" ]]; then
        echo "Cleaning up container ${NAME}"
        docker rm --force "${container_id}"
    fi
    if [[ -n "${TEMP_DIR:-}" && -d "${TEMP_DIR:-}" ]]; then
        echo "Cleaning up tepdir ${TEMP_DIR}"
        rm -rf "${TEMP_DIR}"
    fi
}

function setup_tempdir() {
    TEMP_DIR=$(mktemp --directory "/tmp/${NAME}".XXXXXXXX)
    export TEMP_DIR
}

function create_temporary_ssh_id() {
    ssh-keygen -b 2048 -t rsa -C "${USER}@email.com" -f "${TEMP_DIR}/id_rsa" -N ""
    chmod 600 "${TEMP_DIR}/id_rsa"
    chmod 644 "${TEMP_DIR}/id_rsa.pub"
}

function start_container() {
    docker build --tag "compute-node-sim" \
        --build-arg USER \
        --file "${base_dir}/Dockerfile" \
        "${TEMP_DIR}"
    docker run -d -P --name "${NAME}" "compute-node-sim"
    CONTAINER_ADDR=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${NAME}")
    export CONTAINER_ADDR
}

function setup_test_inventory() {
    TEMP_INVENTORY_FILE="${TEMP_DIR}/hosts"

    cat > "${TEMP_INVENTORY_FILE}" << EOL
[target_group]
${CONTAINER_ADDR}:22
[target_group:vars]
ansible_ssh_private_key_file=${TEMP_DIR}/id_rsa
EOL
    export TEMP_INVENTORY_FILE
}

function run_ansible_playbook() {
    ANSIBLE_CONFIG="${base_dir}/ansible.cfg"
    ansible-playbook -i "${TEMP_INVENTORY_FILE}" -vvv "${base_dir}/playbooks/nas.yml"
}

setup_tempdir
trap cleanup EXIT
trap cleanup ERR
create_temporary_ssh_id
start_container
setup_test_inventory
run_ansible_playbook
