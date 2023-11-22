#!/bin/bash

. scripts/envVar.sh
. scripts/utils.sh

CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"
BFT="$5"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}
: ${BFT:=0}

: ${CONTAINER_CLI:="docker"}
: ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}
infoln "Using ${CONTAINER_CLI} and ${CONTAINER_CLI_COMPOSE}"

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

createChannelGenesisBlock() {
  	setGlobals 1
	which configtxgen
	if [ "$?" -ne 0 ]; then
		fatalln "configtxgen tool not found."
	fi
	local bft_true=$1

	if [ $bft_true -eq 1 ]; then # BFT
		configtxgen -profile ChannelUsingBFT -outputBlock ./channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
	else		# Raft
		configtxgen -profile ChannelUsingRaft -outputBlock ./channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
	fi
	res=$?
  	verifyResult $res "Failed to generate channel configuration transaction..."
}

createChannel() {
	local rc=1
	local COUNTER=1
	local bft_true=$1
	infoln "Adding orderers"
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		. scripts/orderer.sh ${CHANNEL_NAME}> /dev/null 2>&1
		. scripts/orderer2.sh ${CHANNEL_NAME}> /dev/null 2>&1
		if [ $bft_true -eq 1 ]; then
		. scripts/orderer2.sh ${CHANNEL_NAME}> /dev/null 2>&1
		. scripts/orderer3.sh ${CHANNEL_NAME}> /dev/null 2>&1
		. scripts/orderer4.sh ${CHANNEL_NAME}> /dev/null 2>&1
		fi
		res=$?
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	verifyResult $res "Channel creation failed"
}

# joinChannel ORG
joinChannel() {
	ORG=$1
	FABRIC_CFG_PATH=$PWD/../config/
	setGlobals $ORG
	local rc=1
	local COUNTER=1
	## Unirse a un canal puede tomar tiempo
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
		sleep $DELAY
		peer channel join -b $BLOCKFILE 	# peer0 for org1 y org2
		res=$?
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME' "

	if [ $1 = "1" ]; then
		rc=1
		COUNTER=1
		while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
			sleep $DELAY		
			export CORE_PEER_ADDRESS=localhost:8051	# peer1 para org1
			peer channel join -b $BLOCKFILE
			res=$?
			let rc=$res
			COUNTER=$(expr $COUNTER + 1)
		done
		verifyResult $res "After $MAX_RETRY attempts, peer1.org${ORG} has failed to join channel '$CHANNEL_NAME' "
	fi

	if [ $1 = "2" ]; then
		rc=1
		COUNTER=1
		while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
			sleep $DELAY
			export CORE_PEER_ADDRESS=localhost:10051		# peer1 para org2
			peer channel join -b $BLOCKFILE
			res=$?
			let rc=$res
			COUNTER=$(expr $COUNTER + 1)
		done
		verifyResult $res "After $MAX_RETRY attempts, peer1.org${ORG} has failed to join channel '$CHANNEL_NAME' "
	fi
}

setAnchorPeer() {
  ORG=$1
  ${CONTAINER_CLI} exec cli ./scripts/setAnchorPeer.sh $ORG $CHANNEL_NAME 
}


## User attempts to use BFT orderer in Fabric network with CA
if [ $BFT -eq 1 ] && [ -d "organizations/fabric-ca/ordererOrg/msp" ]; then
  fatalln "Fabric network seems to be using CA. This sample does not yet support the use of consensus type BFT and CA together."
fi

## Create channel genesis block
FABRIC_CFG_PATH=$PWD/../config/
BLOCKFILE="./channel-artifacts/${CHANNEL_NAME}.block"

infoln "Generating channel genesis block '${CHANNEL_NAME}.block'"
FABRIC_CFG_PATH=${PWD}/configtx
if [ $BFT -eq 1 ]; then
  FABRIC_CFG_PATH=${PWD}/bft-config
fi

# Generate genesis block for a channel
createChannelGenesisBlock $BFT

## Create channel
infoln "Creating channel ${CHANNEL_NAME}"
createChannel $BFT
successln "Channel '$CHANNEL_NAME' created"

## Join all the peers to the channel
infoln "Joining org1 peer to the channel..."
joinChannel 1
infoln "Joining org2 peer to the channel..."
joinChannel 2

## Set the anchor peers for each org in the channel
infoln "Setting anchor peer for org1..."
setAnchorPeer 1
infoln "Setting anchor peer for org2..."
setAnchorPeer 2

successln "Channel '$CHANNEL_NAME' joined"
