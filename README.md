#### 中国社会扶贫网区块链项目部署

1. 先启动ca，文件docker-ca.yaml，启动脚本：updownca.sh，默认的ca的文件在 ./ca 下

1. 生成ca文件，脚本：caget.sh。 默认生成在 ./fabric-ca-files 下，可以修改shell文件的路径
1. 将生成的ca拷贝至crypto-config对应文件夹下，脚本：cacopy.sh
1. 利用生成的msp生成创世快，脚本：genesis.sh 
1. 启动fabric网络并安装chaincode，脚本：updown.sh
1. 安装chaincode，脚本ccpoor.sh 

注：
- 第一次启动时，请将ca文件夹fabric-ca-files文件夹里的东西删除

- 此fabric根据fabric-samples/first-network修改而来，一个orderer 三个peer

- 节点名称：orderer.fp.com peer0.fp.com peer1.fp.com peer2.fp.com，channel名称：mychannel，组织名称Org1Msp
- ca 生成需要在同一电脑上，因为需要复制ca-server的中间ca下的ca-chain.pem，若不再一个电脑上可以将caget.sh里面的ENROLLURL变量修改为正确的url，随后手动将ca-chain.pem复制到rootca路径下，更名为ca.crt，如orderre的路径:ordererOrganizations/fp.com/orderers/orderer.fp.com/tls/ca.crt
- orderer的cafile路径为：crypto-config/ordererOrganizations/fp.com/orderers/orderer.fp.com/tls/ca.crt
- 数据持久化：peer0节点跟orderer节点，映射路径 /var/hyperledger
- 证书路径，可参考docker-compose-cli.yaml，base下的dockerfile. 以下列出peer0的，做参考:

----------

> - CORE_PEER_TLS_ENABLED=true
> - CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.fp.com/peers/peer0.org1.fp.com/tls/server.crt
> - CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.fp.com/peers/peer0.org1.fp.com/tls/server.key
> - CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.fp.com/peers/peer0.org1.fp.com/tls/ca.crt
> - CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.fp.com/users/Admin@org1.fp.com/msp

-------------