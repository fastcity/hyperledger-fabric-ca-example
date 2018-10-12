#### hyperledger-fabirc-ca-server的生产示例

用法:
1. ./updownca.sh up 启动docker-ca.yaml，生成 ./ca 文件夹

1. ./caget.sh 生成ca msp证书信息。 默认生成在 ./fabric-ca-files文件夹下，生成成功之后会执行scripts/cacopy.sh 将生成的证书复制到crtpto-config对应目录下
1. ./updown.sh up 启动fabric网络，启动前会先执行scripts/genesis.sh 生成创世块
1. ./ccofficial.sh  安装chaincode

注：

- 此例子ca默认启动一个rootca 一个middleca，中间ca默认url:localhost:7055,生成ca证书的流程主要在caget.sh中

- 此例子有一个orderer 三个peer,根据hyperledger项目的fabric-samples/first-network修改而来

- 节点名称：orderer.fp.com peer0.fp.com peer1.fp.com peer2.fp.com，channel名称：mychannel，组织名称Org1Msp

- ca 生成需要在同一电脑上，因为需要复制ca/middleCA/ca-chain.pem，若不在一个电脑上需要手动将ca/middleCA/ca-chain.pem复制到orderer peer的对应路径下，更名为ca.crt，如orderer的路径:crypto-config/ordererOrganizations/fp.com/orderers/orderer.fp.com/tls/ca.crt

- orderer的cafile路径为：crypto-config/ordererOrganizations/fp.com/orderers/orderer.fp.com/tls/ca.crt

- 证书路径，可参考docker-compose-cli.yaml，base下的dockerfile. 以下列出peer0的，做参考:

----------
> PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto  
CORE_PEER_TLS_ENABLED=true  
CORE_PEER_TLS_CERT_FILE=$PATH/peerOrganizations/org1.fp.com/peers/peer0.org1.fp.com/tls/server.crt  
CORE_PEER_TLS_KEY_FILE=$PATH/peerOrganizations/org1.fp.com/peers/peer0.org1.fp.com/tls/server.key   
CORE_PEER_TLS_ROOTCERT_FILE=$PATH/peerOrganizations/org1.fp.com/peers/peer0.org1.fp.com/tls/ca.crt   
CORE_PEER_MSPCONFIGPATH=$PATH/peerOrganizations/org1.fp.com/users/Admin@org1.fp.com/msp   

-------------
- 数据持久化：peer0节点跟orderer节点，映射路径 /var/hyperledger，暂时去掉，没用研究好，重新生成ca会报错.应该是ca变化，数据还是以前的，待研究........
