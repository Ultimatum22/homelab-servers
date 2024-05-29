#!/bin/bash
# unsealing a hashicorp vault (vaultproject.io) secrets store

secretsfile="{{ vault_init_secrets_file }}"
if [ ! -e $secretsfile ]; then
	echo "ERROR: $secretsfile does not exist. exiting."
	exit 1
fi

keys=$(grep "Unseal Key" $secretsfile | awk '{print $4}')
token=$(egrep 'Initial Root Token' $secretsfile | awk '{print $4}')

source /etc/profile

for k in $keys; do
    export VAULT_ADDR=http://127.0.0.1:8200 ; vault operator unseal $k >/dev/null
done

sleep 2

if [ "$(export VAULT_ADDR=http://127.0.0.1:8200 ; vault status | grep Sealed | awk '{print $2}')" == "true" ]; then
    echo "ERROR: vault unsealing failed"
    exit 2
fi

# authenticate using the root token
export VAULT_ADDR=http://127.0.0.1:8200 ; vault login $token >/dev/null

[[ $? -gt 0 ]] && echo "ERROR: vault auth failed" && exit 3

unset keys token

exit 0
