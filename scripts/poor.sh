#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0

set -e

echo "start test=================="
CHANNEL_NAME=mychannel
CAFILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/fp.com/orderers/orderer.fp.com/tls/ca.crt

CC_DONATE_PATH=github.com/chaincode/poorcom/userdonate
CC_ALLTOKEN_PATH=github.com/chaincode/poorcom/poor
CC_USERTOKEN_PATH=github.com/chaincode/poorcom/backuser

CC_DONATE_NAME=userdonatecc
CC_ALLTOKEN_NAME=alltokencc
CC_USERTOKEN_NAME=userlovetokencc
TLS=false

function channelcreate() {
	echo "====================================================="
	echo "===============start channel create=================="
	echo "====================================================="
	if $TLS; then
		peer channel create -o orderer.fp.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls true --cafile $CAFILE
	else
		peer channel create -o orderer.fp.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx
	fi
}

function peer0join() {
	echo "====================================================="
	echo "===============start peer0join channel=================="
	echo "====================================================="
	sleep 3
	JOIN=$1
	CORE_PEER_ADDRESS=peer0.org1.fp.com:7051
	CORE_PEER_LOCALMSPID=Org1MSP
	CORE_PEER_TLS_ENABLED=$TLS
	CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.fp.com/peers/peer0.org1.fp.com/tls/ca.crt
	CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.fp.com/users/Admin@org1.fp.com/msp

	if $JOIN; then
		echo "===============peer channel join -b $CHANNEL_NAME.block=================="
		peer channel join -b $CHANNEL_NAME.block
	fi
}
function peer1join() {
	echo "====================================================="
	echo "===============start peer1join channel=================="
	echo "====================================================="
	sleep 3
	JOIN=$1
	CORE_PEER_ADDRESS=peer1.org1.fp.com:7051
	CORE_PEER_LOCALMSPID=Org1MSP
	CORE_PEER_TLS_ENABLED=$TLS
	CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.fp.com/peers/peer1.org1.fp.com/tls/ca.crt
	CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.fp.com/users/Admin@org1.fp.com/msp
	if $JOIN; then
		peer channel join -b $CHANNEL_NAME.block

	fi

}
function peer2join() {
	echo "====================================================="
	echo "===============start peer2join channel=================="
	echo "====================================================="
	sleep 2
	JOIN=$1
	CORE_PEER_ADDRESS=peer2.org1.fp.com:7051
	CORE_PEER_LOCALMSPID=Org1MSP
	CORE_PEER_TLS_ENABLED=$TLS
	CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.fp.com/peers/peer2.org1.fp.com/tls/ca.crt
	CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.fp.com/users/Admin@org1.fp.com/msp
	if $JOIN; then
		peer channel join -b $CHANNEL_NAME.block
	fi
	sleep 3
}

function updateanchors() {
	echo "====================================================="
	echo "===============start updateanchors=================="
	echo "====================================================="
	sleep 2
	if $TLS; then
		peer channel update -o orderer.fp.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/Org1MSPanchors.tx --tls true --cafile $CAFILE
	else
		peer channel update -o orderer.fp.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/Org1MSPanchors.tx
	fi
	sleep 2
}

# 安装需要每个节点都进行安装
function installcc() {
	echo "====================================================="
	echo "===============start installcc=================="
	echo "====================================================="
	sleep 2
	peer chaincode install -n $CC_DONATE_NAME -v 1.0 -p $CC_DONATE_PATH
	sleep 2
	peer chaincode install -n $CC_ALLTOKEN_NAME -v 1.0 -p $CC_ALLTOKEN_PATH
	sleep 2
	peer chaincode install -n $CC_USERTOKEN_NAME -v 1.0 -p $CC_USERTOKEN_PATH
	sleep 3
}

# 实例化只需要一次即可
function instantiatecc() {
	echo "====================================================="
	echo "===============start instantiatecc=================="
	echo "====================================================="
	sleep 2
	if $TLS; then
		peer chaincode instantiate -n $CC_DONATE_NAME -C $CHANNEL_NAME -v 1.0 -o orderer.fp.com:7050 -c '{"Args":["init"]}' --tls --cafile $CAFILE
		sleep 10
		peer chaincode instantiate -n $CC_ALLTOKEN_NAME -C $CHANNEL_NAME -v 1.0 -o orderer.fp.com:7050 -c '{"Args":["init"]}' --tls --cafile $CAFILE
		sleep 10
		peer chaincode instantiate -n $CC_USERTOKEN_NAME -C $CHANNEL_NAME -v 1.0 -o orderer.fp.com:7050 -c '{"Args":["init"]}' --tls --cafile $CAFILE

	else
		peer chaincode instantiate -n $CC_DONATE_NAME -C $CHANNEL_NAME -v 1.0 -o orderer.fp.com:7050 -c '{"Args":["init"]}'
		sleep 10
		peer chaincode instantiate -n $CC_ALLTOKEN_NAME -C $CHANNEL_NAME -v 1.0 -o orderer.fp.com:7050 -c '{"Args":["init"]}'
		sleep 10
		peer chaincode instantiate -n $CC_USERTOKEN_NAME -C $CHANNEL_NAME -v 1.0 -o orderer.fp.com:7050 -c '{"Args":["init"]}'

	fi
	sleep 10
}

function invokeTest() {
	echo "====================================================="
	echo "===============start invokeTest=================="
	echo "====================================================="
	sleep 2
	for ((i = 1; i <= 4; i++)); do
		echo "$CC_DONATE_NAME invoke $i====="
		sleep 1
		if $TLS; then
			peer chaincode invoke -n $CC_DONATE_NAME -C $CHANNEL_NAME -c '{"Args":["donate", "a","100"]}' --tls true --cafile $CAFILE --peerAddresses peer0.org1.fp.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.fp.com/peers/peer0.org1.fp.com/tls/ca.crt
		else
			peer chaincode invoke -n $CC_DONATE_NAME -C $CHANNEL_NAME -c '{"Args":["donate", "a","100"]}'
		fi
		sleep 5
	done

}

function queryTest() {
	echo "====================================================="
	echo "===============start queryTest=================="
	echo "====================================================="
	sleep 1
	echo "***************$CC_DONATE_NAME query 1-4 invokes***********"
	peer chaincode query -n $CC_DONATE_NAME -C $CHANNEL_NAME -c '{"Args":["query","1","4"]}'
	sleep 1

	#peer chaincode invoke -n $CC_NAME -c '{"Args":["setState", "1","true"]}' -C myc
	echo "****************$CC_ALLTOKEN_NAME query token**************"
	peer chaincode query -n $CC_ALLTOKEN_NAME -c '{"Args":["query"]}' -C $CHANNEL_NAME
	sleep 1

	# peer chaincode invoke -n userlovetokencc -c '{"Args":["invoke", "a","100"]}' -C mychannel
	echo "****************$CC_USERTOKEN_NAME query  token*************"
	peer chaincode query -n $CC_USERTOKEN_NAME -c '{"Args":["query","a"]}' -C $CHANNEL_NAME
	sleep 1
}

function control() {
	echo "=================start tls:$TLS=================="
	channelcreate
	peer0join true
	updateanchors
	installcc
	instantiatecc
	# invokeTest
	# queryTest

	peer1join true
	installcc
	# queryTest
	sleep 10

	peer2join true
	installcc
	# queryTest
	sleep 10
	echo "=================success=================="
}

MODE=$1

if [ "${MODE}" == "t" ]; then
	TLS=true
elif [ "${MODE}" == "f" ]; then
	TLS=false
else
	TLS=true
fi

control
exit 0
# export CC_NAME=userdonatecc

# peer chaincode install -n userdonatecc -v 1.0 -p github.com/chaincode/poorcom/userdonate

# export CHANNEL_NAME=mychannel
# export CC_NAME=alltokencc
# peer chaincode install -n $CC_NAME -v 1.0 -p github.com/chaincode/poorcom/poor

# export CHANNEL_NAME=mychannel
# export CC_NAME=userlovetokencc
# peer chaincode install -n $CC_NAME -v 1.0 -p github.com/chaincode/poorcom/backuser
# peer1:

# peer channel join -b mychannel.block

# export CHANNEL_NAME=mychannel
# export CC_NAME=userdonatecc
# peer chaincode install -n userdonatecc -v 1.0 -p github.com/chaincode/poorcom/userdonate
# peer chaincode instantiate -o orderer.fp.com:7050  -C $CHANNEL_NAME -n $CC_NAME -v 1.0 -c '{"Args":["init"]}'

# export CC_NAME=alltokencc
# export CHANNEL_NAME=mychannel
# peer chaincode install -n $CC_NAME -v 1.0 -p github.com/chaincode/poorcom/poor
# peer chaincode instantiate -o orderer.fp.com:7050  -C $CHANNEL_NAME -n $CC_NAME -v 1.0 -c '{"Args":["init"]}'

# export CC_NAME=userlovetokencc
# export CHANNEL_NAME=mychannel
# peer chaincode install -n $CC_NAME -v 1.0 -p github.com/chaincode/poorcom/backuser
# peer chaincode instantiate -o orderer.fp.com:7050  -C $CHANNEL_NAME -n $CC_NAME -v 1.0 -c '{"Args":["init"]}'

# export CORE_PEER_ADDRESS=peer2.org1.fp.com:7051
# export CORE_PEER_LOCALMSPID=Org1MSP
# export CORE_PEER_TLS_ENABLED=false
# export CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.fp.com/peers/peer2.org1.fp.com/tls/server.crt
# export CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.fp.com/peers/peer2.org1.fp.com/tls/server.key
# export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.fp.com/peers/peer2.org1.fp.com/tls/ca.crt
# export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.fp.com/users/Admin@org1.fp.com/msp

# peer2：
# export CHANNEL_NAME=mychannel

# peer channel join -b mychannel.block

# export CC_NAME=userdonatecc
# peer chaincode install -n userdonatecc -v 1.0 -p github.com/chaincode/poorcom/userdonate

# peer chaincode instantiate -o orderer.fp.com:7050  -C $CHANNEL_NAME -n $CC_NAME -v 1.0 -c '{"Args":["init"]}'

# export CC_NAME=alltokencc

# peer chaincode install -n $CC_NAME -v 1.0 -p github.com/chaincode/poorcom/poor

# peer chaincode instantiate -o orderer.fp.com:7050  -C $CHANNEL_NAME -n $CC_NAME -v 1.0 -c '{"Args":["init"]}'

# export CC_NAME=userlovetokencc

# peer chaincode install -n $CC_NAME -v 1.0 -p github.com/chaincode/poorcom/backuser

# peer chaincode instantiate -o orderer.fp.com:7050  -C $CHANNEL_NAME -n $CC_NAME -v 1.0 -c '{"Args":["init"]}'

# peer channel update -o orderer.fp.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/Org1MSPanchors.tx

#peer chaincode query -C mychannel -n $CC_NAME -c '{"Args":["query","a"]}'

# export CC_NAME=userdonatecc
# CORE_PEER_ADDRESS=peer:7052 CORE_CHAINCODE_ID_NAME=$CC_NAME:0 ./sacc

# export CHANNEL_NAME=myc
# export CC_NAME=userdonatecc
# peer chaincode install -n $CC_NAME -v 0 -p chaincodedev/chaincode/poorcom/userdonate
# peer chaincode instantiate  -C $CHANNEL_NAME -n $CC_NAME -v 0 -c '{"Args":["a","10"]}'

# export CC_NAME=userdonatecc
# peer chaincode invoke -n $CC_NAME -c '{"Args":["donate", "a","100.1"]}' -C myc
# peer chaincode query -n $CC_NAME -c '{"Args":["query","1","4"]}' -C myc

# peer chaincode instantiate -n mycc -v 0 -c '{"Args":["a","10"]}' -C myc
# peer chaincode install -p chaincodedev/chaincode/poorcom/userdonate -n mycc -v 0
# peer chaincode instantiate -n mycc -v 0 -c '{"Args":[]}' -C myc

# export CC_NAME=alltokencc
# CORE_PEER_ADDRESS=peer:7052 CORE_CHAINCODE_ID_NAME=$CC_NAME:0 ./sacc
# export CC_NAME=alltokencc
# export CHANNEL_NAME=myc
# peer chaincode install -n $CC_NAME -v 0 -p chaincodedev/chaincode/poorcom/poor
# peer chaincode instantiate -C $CHANNEL_NAME -n $CC_NAME -v 0 -c '{"Args":["init"]}'

# export CC_NAME=alltokencc
# peer chaincode query -n $CC_NAME -c '{"Args":["query"]}' -C myc

# export CC_NAME=userlovetokencc
# CORE_PEER_ADDRESS=peer:7052 CORE_CHAINCODE_ID_NAME=$CC_NAME:0 ./sacc
# export CC_NAME=userlovetokencc
# export CHANNEL_NAME=myc
# peer chaincode install -n $CC_NAME -v 0 -p chaincodedev/chaincode/poorcom/backuser
# peer chaincode instantiate  -C $CHANNEL_NAME -n $CC_NAME -v 0 -c '{"Args":["init"]}'

# export CC_NAME=userlovetokencc
# peer chaincode query -n $CC_NAME -c '{"Args":["query","a"]}' -C myc
