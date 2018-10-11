#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
set -e

CAFILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/fp.com/orderers/orderer.fp.com/tls/ca.crt
CHANNEL_NAME=mychannel

function test() {
	echo "=================start test offical cc=================="
	echo "peer channel create:peer channel create -o orderer.fp.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls true --cafile $CAFILE"
	peer channel create -o orderer.fp.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls true --cafile $CAFILE
	echo "peer channel join -b mychannel.block"
	peer channel join -b mychannel.block
	sleep 2
	echo "peer channel update -o orderer.fp.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/Org1MSPanchors.tx --tls --cafile $CAFILE"
	peer channel update -o orderer.fp.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/Org1MSPanchors.tx --tls --cafile $CAFILE
	sleep 2
	echo "peer chaincode install -n mycc -v 1.0 -p github.com/chaincode/chaincode_example02/go/"
	peer chaincode install -n mycc -v 1.0 -p github.com/chaincode/chaincode_example02/go/

	echo "peer chaincode instantiate -o orderer.fp.com:7050 --tls --cafile $CAFILE -C $CHANNEL_NAME -n mycc -v 1.0 -c '{"Args":["init","a", "100", "b","200"]}'"
	peer chaincode instantiate -o orderer.fp.com:7050 --tls --cafile $CAFILE -C $CHANNEL_NAME -n mycc -v 1.0 -c '{"Args":["init","a", "100", "b","200"]}'
	sleep 5

	echo "peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}'"
	peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}'

	echo "peer chaincode invoke -o orderer.fp.com:7050 --tls true --cafile $CAFILE -C $CHANNEL_NAME -n mycc"
	peer chaincode invoke -o orderer.fp.com:7050 --tls true --cafile $CAFILE -C $CHANNEL_NAME -n mycc --peerAddresses peer0.org1.fp.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.fp.com/peers/peer0.org1.fp.com/tls/ca.crt -c '{"Args":["invoke","a","b","10"]}'
	sleep 5
	echo "peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}'"
	peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}'
	echo "=================test offical cc down=================="
}
test
exit 0
