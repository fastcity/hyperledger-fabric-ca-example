#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0

set -e
# SDIR=$(dirname "$0")
# SDIR=$(
# 	cd "$(dirname "$0")"
# 	pwd
# )
ININT_PATH=${PWD}
# 进入到脚本所在目录的上一级目录
cd "$(dirname "$0")"
cd ..
SDIR=${PWD}

HOME_DIR=$SDIR/fabric-ca-files

# 判断路径是否存在
function mkdirPath() {
	if [ ! -d $HOME_DIR ]; then
		echo "======================$HOME_DIR 路径不存在 ,无法复制ca证书=============================="
	fi
	if [ ! -d $SDIR/crypto-config ]; then
		mkdir $SDIR/crypto-config
	fi
	echo "======================先清空文件:  $SDIR/crypto-config/*=============================="

	rm -rf $SDIR/crypto-config/*

	echo "======================创建文件夹crypto-config/*=============================="
	mkdir -p crypto-config/ordererOrganizations/fp.com/users/Admin@fp.com
	mkdir -p crypto-config/ordererOrganizations/fp.com/orderers/orderer.fp.com
	mkdir -p crypto-config/ordererOrganizations/fp.com/msp

	mkdir -p crypto-config/peerOrganizations/org1.fp.com/users/Admin@org1.fp.com
	mkdir -p crypto-config/peerOrganizations/org1.fp.com/peers/peer0.org1.fp.com
	mkdir -p crypto-config/peerOrganizations/org1.fp.com/peers/peer1.org1.fp.com
	mkdir -p crypto-config/peerOrganizations/org1.fp.com/peers/peer2.org1.fp.com
	mkdir -p crypto-config/peerOrganizations/org1.fp.com/msp
}

function copyorderer() {

	echo "======================copy  orderer start=============================="
	cp -rf $HOME_DIR/fp.com/admin/* $SDIR/crypto-config/ordererOrganizations/fp.com/users/Admin@fp.com
	cp -rf $HOME_DIR/fp.com/orderer/* $SDIR/crypto-config/ordererOrganizations/fp.com/orderers/orderer.fp.com
	cp -rf $HOME_DIR/fp.com/msp/* $SDIR/crypto-config/ordererOrganizations/fp.com/msp
	echo "======================copy  orderer down================================="
}

function copypeer() {

	echo "======================copy  peer start================================="
	cp -rf $HOME_DIR/org1.fp.com/admin/* $SDIR/crypto-config/peerOrganizations/org1.fp.com/users/Admin@org1.fp.com
	cp -rf $HOME_DIR/org1.fp.com/peer0/* $SDIR/crypto-config/peerOrganizations/org1.fp.com/peers/peer0.org1.fp.com
	cp -rf $HOME_DIR/org1.fp.com/peer1/* $SDIR/crypto-config/peerOrganizations/org1.fp.com/peers/peer1.org1.fp.com
	cp -rf $HOME_DIR/org1.fp.com/peer2/* $SDIR/crypto-config/peerOrganizations/org1.fp.com/peers/peer2.org1.fp.com
	cp -rf $HOME_DIR/org1.fp.com/msp/* $SDIR/crypto-config/peerOrganizations/org1.fp.com/msp
	echo "======================copy  peer down================================="
}

function control() {
	echo "#####################################################"
	echo "####################copy CA start#######################"
	echo "#####################################################"
	mkdirPath
	copyorderer
	copypeer
	echo "#####################################################"
	echo "####################copy CA down#######################"
	echo "#####################################################"

	# 恢复之前的路径
	cd $ININT_PATH
}

control

exit 0
