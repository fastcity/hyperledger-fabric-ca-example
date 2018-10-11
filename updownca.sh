#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0

set -e

function networkUp() {
	echo "start docker-compose  up=================="
	docker-compose -f docker-ca.yaml up -d 
}

function networkDown() {
	echo "start docker-compose  down=================="
	docker-compose -f docker-ca.yaml down --volumes --remove-orphan
}

function printHelp() {
	echo "./updownca.sh  [command]"
	echo "--------------------"
	echo "up      ---启动ca网络"
	echo "down    ---关闭ca网络"
	echo "restart ---重启ca网络"
	echo "--------------------"
}

MODE=$1

if [ "${MODE}" == "up" ]; then
	networkUp
elif [ "${MODE}" == "down" ]; then ## Clear the network
	networkDown
elif [ "${MODE}" == "restart" ]; then ## Restart the network
	networkDown
	networkUp
else
	printHelp
	exit 1
fi
