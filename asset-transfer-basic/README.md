# Asset transfer basic sample

The asset transfer basic sample demonstrates:

- Connecting a client application to a Fabric blockchain network.
- Submitting smart contract transactions to update ledger state.
- Evaluating smart contract transactions to query ledger state.
- Handling errors in transaction invocation.

## About the sample

This sample includes smart contract and application code in go language. This sample shows create, read, update, transfer and delete of an asset.

### Application

Follow the execution flow in the client application code, and corresponding output on running the application. Pay attention to the sequence of:

- Transaction invocations (console output like "**--> Submit Transaction**" and "**--> Evaluate Transaction**").
- Results returned by transactions (console output like "**\*\*\* Result**").

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

1. Create the test network and a channel (from the `test-network` folder).
   ```
   ./runNetwork.sh
   ```

1. Deploy the smart contract implementation.
   ```
   ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go/ -ccl go
   ```

1. Run the application (from the `asset-transfer-basic` folder).
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