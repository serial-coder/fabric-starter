#!/usr/bin/env bash

./consortium-add-org.sh org1
./channel-create.sh common
./channel-join.sh common

./chaincode-install.sh example02 1.0 chaincode_example02 golang
./chaincode-instantiate.sh common example02 '["init","a","10","b","0"]'

sleep 2
./chaincode-query.sh common example02 '["query","a"]'
sleep 2
./chaincode-invoke.sh common example02 '["move","a","b","1"]'
sleep 2
./chaincode-query.sh common example02 '["query","a"]'