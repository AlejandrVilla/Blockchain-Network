# Basic Network

## Estructure

The network structure is as follow

- Org 1
    - Peer 0
    - Peer 1
- Org 2
    - Peer 0
    - Peer 1
- Ordering service
    - Orderer node 1
    - Orderer node 2
- Consensus algorithm 
    - Raft

## Smart contract and application gateway
The chaincode is inside the asset-transfer-basic folder. It contains both the chaincode and the application gateway made in GO programming language

The asset transfer basic sample demonstrates:

- Connecting a client application to a Fabric blockchain network.
- Submitting smart contract transactions to update ledger state.
- Evaluating smart contract transactions to query ledger state.
- Handling errors in transaction invocation.

### About the sample

This sample shows create, read, update, transfer and delete of an asset.
Also you can test transactions per second (TSP) using Goroutines.

### Smart Contract

The smart contract implements the following functions to support the application:

- Test
- CreateAsset
- ReadAsset
- UpdateAsset
- DeleteAsset
- TransferAsset

## Running the sample

Follow these steps in order:

1. Create the test network and a channel with CA (from the `Rnetwork` folder).
   ```
   ./runNetwork.sh
   ```
    This will show a simple menu
2. Deploy the smart contract implementation.
    - Inside the menu you will see an option to deploy the Chaincode
    - Or you can use the following instruction
   ```
   ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go/ -ccl go
   ```
3. Run the application (from the `asset-transfer-basic` folder).
   ```
   # To run the Go sample application
   cd application-gateway-go
   go run .
   ```

## Clean up

When you are finished, you can bring down the test network (from the `Rnetwork` folder). The command will remove all the nodes, and delete any ledger data that you created.

```
./network.sh down
```