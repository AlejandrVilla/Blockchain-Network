#!/bin/bash

cd $PWD/../asset-transfer-basic/chaincode-go

GO111MODULE=on go mod vendor
CC_NAME=basic

cd ../../Rnetwork

export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config/

echo "empaquetando Chaincode"
peer lifecycle chaincode package basic.tar.gz --path ../asset-transfer-basic/chaincode-go/ --lang golang --label basic_1.0

export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp

echo "instalando chaincode en peer0 org1"
export CORE_PEER_ADDRESS=localhost:7051
peer lifecycle chaincode install basic.tar.gz

echo "instalando chaincode en peer1 org1"
export CORE_PEER_ADDRESS=localhost:8051
peer lifecycle chaincode install basic.tar.gz

export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp

echo "instalando chaincode en peer0 org2"
export CORE_PEER_ADDRESS=localhost:9051
peer lifecycle chaincode install basic.tar.gz

echo "instalando chaincode en peer1 org2"
export CORE_PEER_ADDRESS=localhost:10051
peer lifecycle chaincode install basic.tar.gz

echo "Comprobando chaincode instalado"
peer lifecycle chaincode queryinstalled
# peer lifecycle chaincode queryinstalled --output json | jq -r 'try (.installed_chaincodes[].package_id)' | grep ^${PACKAGE_ID}$ >&log.txt

CC_PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CC_NAME}.tar.gz)

echo "Aprobando chaincode para org1"
peer lifecycle chaincode approveformyorg -o localhost:7052 --ordererTLSHostnameOverride orderer2.example.com --channelID mychannel --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer2.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_ADDRESS=localhost:7051

echo "Aprobando chaincode para org2"
peer lifecycle chaincode approveformyorg -o localhost:7052 --ordererTLSHostnameOverride orderer2.example.com --channelID mychannel --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer2.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

echo "Revisando chaincode en org1"
peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name basic --version 1.0 --sequence 1 --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer2.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" --output json

echo "Subiendo chaincode al canal"
peer lifecycle chaincode commit -o localhost:7052 --ordererTLSHostnameOverride orderer2.example.com --channelID mychannel --name basic --version 1.0 --sequence 1 --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer2.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"

echo "Comprobando el chaincode instalado"
peer lifecycle chaincode querycommitted --channelID mychannel --name basic
