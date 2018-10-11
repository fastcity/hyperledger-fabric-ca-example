#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0

set -e

SDIR=$(dirname "$0")
export FABRIC_CFG_PATH=$SDIR 
export CHANNEL_NAME=mychannel
configtxgen -profile OneOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block
configtxgen -profile OneOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
configtxgen -profile OneOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
exit 0