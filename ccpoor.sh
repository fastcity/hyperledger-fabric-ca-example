#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0

set -e

function printHelp() {
	echo "./ccpoor.sh  [command]"
	echo "t     --- 有tls的测试 默认带tls"
	echo "f     --- 没有tls的测试"
	echo "help  --- 帮助"
	echo "-----------------------------"
}

MODE=$1

if [ "${MODE}" == "help" ]; then
	printHelp
	exit 1
else
	docker exec cli scripts/poor.sh $MODE
fi
