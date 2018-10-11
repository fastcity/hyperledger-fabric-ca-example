#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0

set -e
# SDIR=$(dirname "$0")
SDIR=$(
	cd "$(dirname "$0")"
	pwd
)
HOME_DIR=$SDIR/fabric-ca-files

function copyorderer() {
	echo "======================先删除存在的文件=============================="
	rm -rf $SDIR/crypto-config/ordererOrganizations/fp.com/users/Admin@fp.com/*
	rm -rf $SDIR/crypto-config/ordererOrganizations/fp.com/orderers/orderer.fp.com/*
	rm -rf $SDIR/crypto-config/ordererOrganizations/fp.com/msp/*
	sleep 1
	echo "======================开始copyorderer=============================="
	cp -rf $HOME_DIR/fp.com/admin/* $SDIR/crypto-config/ordererOrganizations/fp.com/users/Admin@fp.com
	cp -rf $HOME_DIR/fp.com/orderer/* $SDIR/crypto-config/ordererOrganizations/fp.com/orderers/orderer.fp.com
	cp -rf $HOME_DIR/fp.com/msp/* $SDIR/crypto-config/ordererOrganizations/fp.com/msp
	echo "======================copyorderer down================================="
}

function copypeer() {
	echo "======================先删除存在的文件=============================="
	rm -rf $SDIR/crypto-config/peerOrganizations/org1.fp.com/users/Admin@org1.fp.com/*
	rm -rf $SDIR/crypto-config/peerOrganizations/org1.fp.com/peers/peer0.org1.fp.com/*
	rm -rf $SDIR/crypto-config/peerOrganizations/org1.fp.com/peers/peer1.org1.fp.com/*
	rm -rf $SDIR/crypto-config/peerOrganizations/org1.fp.com/peers/peer2.org1.fp.com/*
	rm -rf $DIR/crypto-config/peerOrganizations/org1.fp.com/msp/*
	sleep 1
	echo "======================开始:copypeer================================="
	cp -rf $HOME_DIR/org1.fp.com/admin/* $SDIR/crypto-config/peerOrganizations/org1.fp.com/users/Admin@org1.fp.com
	cp -rf $HOME_DIR/org1.fp.com/peer0/* $SDIR/crypto-config/peerOrganizations/org1.fp.com/peers/peer0.org1.fp.com
	cp -rf $HOME_DIR/org1.fp.com/peer1/* $SDIR/crypto-config/peerOrganizations/org1.fp.com/peers/peer1.org1.fp.com
	cp -rf $HOME_DIR/org1.fp.com/peer2/* $SDIR/crypto-config/peerOrganizations/org1.fp.com/peers/peer2.org1.fp.com
	cp -rf $HOME_DIR/org1.fp.com/msp/* $SDIR/crypto-config/peerOrganizations/org1.fp.com/msp
	echo "======================copypeer down================================="
}

function control() {
	copyorderer
	copypeer
}

control

exit 0
