#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0

set -e
ININT_PATH=${PWD}
cd "$(dirname "$0")"
cd ..
SDIR=${PWD}

export FABRIC_CFG_PATH=$SDIR
CHANNEL_NAME=mychannel

echo "#############################################################################"
echo "############################## 生成创世块 ####################################"
echo "#############################################################################"

configtxgen -profile OneOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block
configtxgen -profile OneOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
configtxgen -profile OneOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP

echo "################################ 创世块生成 成功###############################"

# 恢复之前的路径
cd $ININT_PATH

exit 0
