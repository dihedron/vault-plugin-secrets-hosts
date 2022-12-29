#!/bin/bash

set -m

VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
export VAULT_ADDR

echo "ensure directory tree..."
mkdir -p ./data/plugins

echo "start server..."
vault server -config=config.hcl &

echo "wait 5 seconds for server to start up..."
sleep 5

echo "check if server needs to be initialised..."
if [ ! -f "./data/init.json" ]; then
    # server has not been initialised
    echo "initialise server..."
    vault operator init --format=json > ./data/init.json    
fi

echo "unseal server..."
for i in {0..2}; do
    KEY=$(cat data/init.json | jq .unseal_keys_b64[$i] | tr -d '"')
     echo "$opt" | tr -d '"'

    echo "... unsealing with $KEY..."
    vault operator unseal $KEY
done

echo "wait 5 seconds for server to unseal..."
sleep 5

echo "login with root token..."
TOKEN=$(cat data/init.json | jq .root_token | tr -d '"')
vault login -non-interactive $TOKEN

echo "wait for server to terminate..."
jobs -l
fg %1 
# wait does not bring job to foreground, it won't get signals

echo "... DONE!"

