#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0

set -e
# SDIR=$(dirname "$0")

# 中间ca的url
ENROLLURL=localhost:7055
SDIR=$(
	cd "$(dirname "$0")"
	pwd
)
# 生成的ca的文件的相对根目录
HOME_DIR=$SDIR/fabric-ca-files

function finishMSPSetup() {
	if [ $# -ne 1 ]; then
		fatal "Usage: finishMSPSetup <targetMSPDIR>"
	fi
	if [ ! -d $1/tlscacerts ]; then
		mkdir $1/tlscacerts
		cp $1/cacerts/* $1/tlscacerts
		if [ -d $1/intermediatecerts ]; then
			mkdir $1/tlsintermediatecerts
			cp $1/intermediatecerts/* $1/tlsintermediatecerts
		fi
	fi
}

# Copy the org's admin cert into some target MSP directory
# This is only required if ADMINCERTS is enabled.
function copyAdminCert() {
	if [ $# -ne 2 ]; then
		fatal "Usage: copyAdminCert <adminCertDir> <targetMSPDIR>"
	fi
	if $ADMINCERTS; then
		dstDir=$2/admincerts
		mkdir -p $dstDir
		cp $1/signcerts/* $dstDir
	fi
}

function copyTls() {
	if [ $# -ne 1 ]; then
		fatal "Usage: copyTls <targetMSPDIR>"
	fi
	cp $1/keystore/* $1/server.key
	sleep 1
	cp $1/signcerts/* $1/server.crt

}

function copyRootCA() {
	if [ $# -ne 1 ]; then
		fatal "Usage: copyTls <targetMSPDIR>"
	fi
	if [ -f $SDIR/ca/middleCA/ca-chain.pem ]; then
		echo "=======copyrootca：路径是:$SDIR/ca/middleCA/ca-chain.pem======"
		cp -rf $SDIR/ca/middleCA/ca-chain.pem $1/ca.crt
	else
		echo "=======copyrootca：没有rootca 需要手动复制======"
	fi
}

function initCAAdmin() {
	echo "==============initCAAdmin======="
	export FABRIC_CA_CLIENT_HOME=$HOME_DIR/caAdmin
	fabric-ca-client enroll -d -u http://admin:vsaCNbZGpOtR@$ENROLLURL
}

function addOrg() {
	echo "==============Add orgs======="
	fabric-ca-client affiliation list
	fabric-ca-client affiliation remove --force org1
	fabric-ca-client affiliation remove --force org2
	fabric-ca-client affiliation add org1
}

function ordererRegister() {

	echo "==============ordererRegister======="
	# id:
	# name: orderer.fp.com
	# type: orderer
	# affiliation: org1
	# maxenrollments: 0
	# attributes:

	# POST https://ica-fp.com:7054/register
	# {"id":"orderer1.fp.com","type":"orderer","secret":"orderer1.fp.compw","affiliation":"org1"}
	sleep 1
	fabric-ca-client register -d --id.secret orderer.fp.compw --id.name orderer.fp.com --id.type orderer --id.affiliation org1

	# id:
	# name: Admin@fp.com
	# type: client
	# affiliation: org1
	# maxenrollments: 0
	# attributes:
	# - name: admin
	# value: true
	# ecert: true

	# POST https://ica-fp.com:7054/register
	# {"id":"admin-fp.com","type":"client","secret":"admin-fp.compw","affiliation":"org1","attrs":[{"name":"admin","value":"true","ecert":true}]}
	sleep 1
	fabric-ca-client register -d --id.secret Admin.fp.compw --id.name Admin@fp.com --id.type client --id.affiliation org1 --id.attrs admin=true:ecert
}

function orderergetcacert() {
	echo "==============orderergetcacert======="
	# id:
	# name:
	# type: client
	# affiliation: org1
	# maxenrollments: 0
	# attributes:
	sleep 1
	fabric-ca-client getcacert -d -u http://$ENROLLURL -M $HOME_DIR/fp.com/msp --id.type client --id.affiliation org1

	# cp $HOME_DIR/fp.com/msp/cacerts/* $HOME_DIR/fp.com/msp/tlscacerts
	# cp $HOME_DIR/fp.com/msp/intermediatecerts/* $HOME_DIR/fp.com/msp/tlsintermediatecerts
	echo "============home_dir $HOME_DIR============"
	sleep 1
	finishMSPSetup $HOME_DIR/fp.com/msp
}

function ordererenrolladmin() {
	echo "==============ordererenrolladmin======="
	export FABRIC_CA_CLIENT_HOME=$HOME_DIR/fp.com/admin
	fabric-ca-client enroll -d -u http://Admin@fp.com:Admin.fp.compw@$ENROLLURL --id.affiliation org1

	# cp $HOME_DIR/fp.com/admin/msp/signcerts/* $HOME_DIR/fp.com/msp/admincerts/cert.pem
	# cp $HOME_DIR/fp.com/admin/msp/signcerts/* $HOME_DIR/fp.com/admin/msp/admincerts
	sleep 1
	copyAdminCert $HOME_DIR/fp.com/admin/msp $HOME_DIR/fp.com/msp
	sleep 1
	copyAdminCert $HOME_DIR/fp.com/admin/msp $HOME_DIR/fp.com/admin/msp

}

function orderertls() {
	echo "==============orderertls======="
	export FABRIC_CA_CLIENT_HOME=$HOME_DIR/fp.com/orderer
	fabric-ca-client enroll -d --enrollment.profile tls -u http://orderer.fp.com:orderer.fp.compw@$ENROLLURL -M $HOME_DIR/fp.com/orderer/tls --csr.hosts orderer.fp.com --id.affiliation org1

	# cp $HOME_DIR/fp.com/orderer/tls/keystore/* $HOME_DIR/fp.com/orderer/tls/server.key
	# cp $HOME_DIR/fp.com/orderer/tls/signcerts/* $HOME_DIR/fp.com/orderer/tls/server.crt
	# cp $SDIR/ca/middleCA/ca-chain.pem  $HOME_DIR/fp.com/orderer/tls/ca.crt
	sleep 1
	copyTls $HOME_DIR/fp.com/orderer/tls
	sleep 1
	copyRootCA $HOME_DIR/fp.com/orderer/tls
	# rm -rf /tmp/tls
}

function ordererenroll() {
	echo "==============ordererenroll======="
	fabric-ca-client enroll -d -u http://orderer.fp.com:orderer.fp.compw@$ENROLLURL -M $HOME_DIR/fp.com/orderer/msp --id.affiliation org1

	# cp $HOME_DIR/fp.com/orderer/msp/cacerts/* $HOME_DIR/fp.com/orderer/msp/tlscacerts
	# cp $HOME_DIR/fp.com/orderer/msp/intermediatecerts/* $HOME_DIR/fp.com/orderer/msp/tlsintermediatecerts
	sleep 1
	finishMSPSetup $HOME_DIR/fp.com/orderer/msp
	sleep 1
	copyAdminCert $HOME_DIR/fp.com/admin/msp $HOME_DIR/fp.com/orderer/msp

}

function peerregister() {
	# id:
	# name: peer0.org1.fp.com
	# type: peer
	# affiliation: org1
	# maxenrollments: 0
	# attributes:

	export FABRIC_CA_CLIENT_HOME=$HOME_DIR/caAdmin

	# POST https://ica-org1.fp.com:7054/register
	# {"id":"peer3.org1.fp.com","type":"peer","secret":"peer3.org1.fp.compw","affiliation":"org1"}
	sleep 1
	fabric-ca-client register -d --id.secret peer0.org1.fp.compw --id.name peer0.org1.fp.com --id.type peer --id.affiliation org1
	sleep 1
	fabric-ca-client register -d --id.secret peer1.org1.fp.compw --id.name peer1.org1.fp.com --id.type peer --id.affiliation org1
	sleep 1
	fabric-ca-client register -d --id.secret peer2.org1.fp.compw --id.name peer2.org1.fp.com --id.type peer --id.affiliation org1

	# POST https://ica-org1.fp.com:7054/register
	# {"id":"admin-org1.fp.com","type":"client","secret":"admin-org1.fp.compw","affiliation":"org1","attrs":[{"name":"hf.Registrar.Roles","value":"client"},{"name":"hf.Registrar.Attributes","value":"*"},{"name":"hf.Revoker","value":"true"},{"name":"hf.GenCRL","value":"true"},{"name":"admin","value":"true","ecert":true},{"name":"abac.init","value":"true","ecert":true}]}

	# name: Admin@fp.com
	# type: client
	# affiliation: org1
	# maxenrollments: 0
	# attributes:
	# - name: admin
	# value: true
	# ecert: true
	sleep 1
	fabric-ca-client register -d --id.name Admin@org1.fp.com --id.secret Admin.org1.fp.compw --id.type client --id.attrs hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert --id.affiliation org1

	# POST https://ica-org1.fp.com:7054/register
	# {"id":"user-org1.fp.com","type":"client","secret":"user-org1.fp.compw","affiliation":"org1"}
	sleep 1
	fabric-ca-client register -d --id.name user@org1.fp.com --id.secret user.org1.fp.compw --id.type client --id.affiliation org1
}

function peergetcacert() {
	fabric-ca-client getcacert -d -u http://$ENROLLURL -M $HOME_DIR/org1.fp.com/msp

	# cp $HOME_DIR/fp.com/msp/cacerts/* $HOME_DIR/fp.com/msp/tlscacerts
	# cp $HOME_DIR/fp.com/msp/intermediatecerts/* $HOME_DIR/fp.com/msp/tlsintermediatecerts
	sleep 1
	finishMSPSetup $HOME_DIR/org1.fp.com/msp
}
function peergetenrolladmin() {
	export FABRIC_CA_CLIENT_HOME=$HOME_DIR/org1.fp.com/admin
	fabric-ca-client enroll -d -u http://Admin@org1.fp.com:Admin.org1.fp.compw@$ENROLLURL --id.affiliation org1

	# mkdir -p $HOME_DIR/org1.fp.com/msp/admincerts
	# cp $HOME_DIR/org1.fp.com/admin/msp/signcerts/* $HOME_DIR/org1.fp.com/msp/admincerts/cert.pem
	# mkdir $HOME_DIR/org1.fp.com/admin/msp/admincerts
	# cp $HOME_DIR/org1.fp.com/admin/msp/signcerts/* $HOME_DIR/org1.fp.com/admin/msp/admincerts
	sleep 1
	copyAdminCert $HOME_DIR/org1.fp.com/admin/msp $HOME_DIR/org1.fp.com/admin/msp
	sleep 1
	copyAdminCert $HOME_DIR/org1.fp.com/admin/msp $HOME_DIR/org1.fp.com/msp

	export FABRIC_CA_CLIENT_HOME=$HOME_DIR/org1.fp.com/user
	fabric-ca-client enroll -d -u http://user@org1.fp.com:user.org1.fp.compw@$ENROLLURL --id.affiliation org1
}

function peerTLS() {
	for ((i = 0; i < 3; i++)); do
		peer=peer$i
		echo "==============start peerTLS  $peer====="
		sleep 1
		export FABRIC_CA_CLIENT_HOME=$HOME_DIR/org1.fp.com/$peer
		fabric-ca-client enroll -d --enrollment.profile tls -u http://$peer.org1.fp.com:$peer.org1.fp.compw@$ENROLLURL -M $HOME_DIR/org1.fp.com/$peer/tls --csr.hosts $peer.org1.fp.com --id.affiliation org1
		sleep 1
		copyTls $HOME_DIR/org1.fp.com/$peer/tls
		sleep 1
		copyRootCA $HOME_DIR/org1.fp.com/$peer/tls
		sleep 1
		fabric-ca-client enroll -d -u http://$peer.org1.fp.com:$peer.org1.fp.compw@$ENROLLURL -M $HOME_DIR/org1.fp.com/$peer/msp --id.affiliation org1

		# cp$HOME_DIR/org1.fp.com/peer0/msp/cacerts/* $HOME_DIR/org1.fp.com/peer0/msp/tlscacerts
		# cp $HOME_DIR/org1.fp.com/peer0/msp/intermediatecerts/* $HOME_DIR/org1.fp.com/peer0/tlsintermediatecerts
		sleep 1
		finishMSPSetup $HOME_DIR/org1.fp.com/$peer/msp
		sleep 1
		copyAdminCert $HOME_DIR/org1.fp.com/admin/msp $HOME_DIR/org1.fp.com/$peer/msp

	done
}

# Ask user for confirmation to proceed
function askProceed() {
	read -p "Continue? [Y/n] " ans
	case "$ans" in
	y | Y | "")
		echo "proceeding ..."
		;;
	n | N)
		echo "exiting..."
		exit 1
		;;
	*)
		echo "invalid response"
		askProceed
		;;
	esac
}
function printHelp() {
	echo "======./caget.sh url  例: ./caget.sh localhost:7055======"
}
function control() {
	echo "==========start get ca=========="
	initCAAdmin
	addOrg
	ordererRegister
	orderergetcacert
	ordererenrolladmin
	orderertls
	ordererenroll

	peerregister
	peergetcacert
	peergetenrolladmin
	peerTLS
	echo "===========success ================="
}

MODE=$1

if [ "${MODE}" == "help" ]; then 
	printHelp
	exit 1
elif [ "${MODE}" != "" ]; then
	ENROLLURL=$MODE
fi

echo "==============use:ca--url:$ENROLLURL=========="
askProceed
control

exit 0
# function peer0tls() {
# 	export FABRIC_CA_CLIENT_HOME=$HOME_DIR/org1.fp.com/peer0
# 	fabric-ca-client enroll -d --enrollment.profile tls -u http://peer0.org1.fp.com:peer0.org1.fp.compw@$ENROLLURL -M $HOME_DIR/org1.fp.com/peer0/tls --csr.hosts peer0.org1.fp.com --id.affiliation org1

# 	copyTls $HOME_DIR/org1.fp.com/peer0/tls
# 	copyRootCA $HOME_DIR/org1.fp.com/peer0/tls/ca.crt

# }

# function peer0enroll() {
# 	fabric-ca-client enroll -d -u http://peer0.org1.fp.com:peer0.org1.fp.compw@$ENROLLURL -M $HOME_DIR/org1.fp.com/peer0/msp --id.affiliation org1

# 	# cp$HOME_DIR/org1.fp.com/peer0/msp/cacerts/* $HOME_DIR/org1.fp.com/peer0/msp/tlscacerts
# 	# cp $HOME_DIR/org1.fp.com/peer0/msp/intermediatecerts/* $HOME_DIR/org1.fp.com/peer0/tlsintermediatecerts
# 	finishMSPSetup $HOME_DIR/org1.fp.com/peer0/msp
# 	copyAdminCert $HOME_DIR/org1.fp.com/admin $HOME_DIR/org1.fp.com/peer0/msp
# }
# function peer1tls() {
# 	export FABRIC_CA_CLIENT_HOME=$HOME_DIR/org1.fp.com/peer1
# 	fabric-ca-client enroll -d --enrollment.profile tls -u http://peer1.org1.fp.com:peer1.org1.fp.compw@$ENROLLURL -M $HOME_DIR/org1.fp.com/peer1/tls --csr.hosts peer1.org1.fp.com --id.affiliation org1

# 	copyTls $HOME_DIR/org1.fp.com/peer1/tls
# 	copyRootCA $HOME_DIR/org1.fp.com/peer0/peer1/ca.crt
# }

# function peer1enroll() {
# 	fabric-ca-client enroll -d -u http://peer1.org1.fp.com:peer1.org1.fp.compw@$ENROLLURL -M $HOME_DIR/org1.fp.com/peer1/msp --id.affiliation org1

# 	# cp $HOME_DIR/org1.fp.com/peer1/msp/cacerts/* $HOME_DIR/org1.fp.com/peer1/msp/tlscacerts
# 	# cp$HOME_DIR/org1.fp.com/peer1/msp/intermediatecerts/* $HOME_DIR/org1.fp.com/peer1/msp/tlsintermediatecerts

# 	finishMSPSetup $HOME_DIR/org1.fp.com/peer1/msp

# 	copyAdminCert $HOME_DIR/org1.fp.com/admin $HOME_DIR/org1.fp.com/peer1/msp
# }
# function peer2tls() {
# 	export FABRIC_CA_CLIENT_HOME=$HOME_DIR/org1.fp.com/peer2
# 	fabric-ca-client enroll -d --enrollment.profile tls -u http://peer2.org1.fp.com:peer2.org1.fp.compw@$ENROLLURL -M $HOME_DIR/org1.fp.com/peer2/tls --csr.hosts peer2.org1.fp.com --id.affiliation org1

# 	copyTls $HOME_DIR/org1.fp.com/peer2/tls
# 	copyRootCA $HOME_DIR/org1.fp.com/peer0/peer2/ca.crt

# }

# function peer2enroll() {
# 	fabric-ca-client enroll -d -u http://peer2.org1.fp.com:peer2.org1.fp.compw@$ENROLLURL -M $HOME_DIR/org1.fp.com/peer2/msp --id.affiliation org1

# 	# cp $HOME_DIR/org1.fp.com/peer2/msp/cacerts/* $HOME_DIR/org1.fp.com/peer2/msp/tlscacerts
# 	# cp $HOME_DIR/org1.fp.com/peer2/msp/intermediatecerts/* $HOME_DIR/org1.fp.com/peer2/msp/tlsintermediatecerts
# 	finishMSPSetup $HOME_DIR/org1.fp.com/peer2/msp
# 	copyAdminCert $HOME_DIR/org1.fp.com/admin $HOME_DIR/org1.fp.com/peer2/msp
# }
