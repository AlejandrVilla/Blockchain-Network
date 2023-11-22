#!/bin/bash

OP=0
while [ "0" = "$OP" ]; do
    echo "S) Crear red y canal"
    echo "C) para instalar chaincode"
    echo "J) para saltar"
    echo "E) para terminar"
    read READ

    if [ "S" = "$READ" ]; then
        . network.sh up createChannel -c mychannel -ca
        # docker ps -a
        if [ "0" -eq "$?" ]; then
            echo "canal creado"
        else
            echo  "error"
            exit -1
        fi
    elif [ "C" = "$READ" ]; then
        # . network.sh deployCC -cnc basic -ccp ../asset-transfer-basic/chaincode-go -ccl go
        . CCGO.sh
    elif [ "J" = "$READ" ]; then
        OP=1
    elif [ "E" = "$READ" ]; then
        exit -1
    else
        echo "Opcion incorrecta"
    fi
done

OP=0
while [ "0" = "$OP" ]; do
    echo "Q) Ver todas las transacciones"
    echo "I) Insertar transaccion"
    echo "C) Transferir"
    echo "S) Buscar transaccion por ID"
    echo "TSP) Probar transacciones por segundo"  # serializado, nada optimo
    echo "E) para salir"
    read READ
    export PATH=${PWD}/../bin:$PATH
    export FABRIC_CFG_PATH=$PWD/../config/
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:10051
    if [ "Q" = "$READ" ]; then
        peer chaincode query -C mychannel -n basic -c '{"Args":["GetAllAssets"]}'
    elif [ "I" = "$READ" ]; then
        echo "ID transaccion"
        read ID
        peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:8051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c "{\"function\":\"CreateAsset\",\"Args\":[\"${ID}\",\"yellow\", \"5\", \"Alejandro\", \"1300\"]}"
    elif [ "C" = "$READ" ]; then
        echo "Nombre de la transaccion"
        read TRAN
        echo "Nuevo dueno"
        read OWNER
        peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n basic --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c "{\"function\":\"TransferAsset\",\"Args\":[\"$TRAN\",\"$OWNER\"]}"
    elif [ "S" = "$READ" ]; then
        echo "ID de la transaccion"
        read ID
        peer chaincode query -C mychannel -n basic -c "{\"Args\":[\"ReadAsset\",\"$ID\"]}"
    elif [ "TSP" = "$READ" ]; then
        echo "Total de transacciones"
        read NTSP
        echo "tiempos"
        TIEMPO=$( { time . TSP.sh $NTSP; } 2>&1 )
        echo "$TIEMPO"

        # extrae tiempo del sistema
        TIEMPO_SYS=$(echo "$TIEMPO" | awk '/sys/{print $2}')
        echo "Tiempo del sistema $TIEMPO_SYS"

        # Extraer números antes de 'm' y después de 'm' pero antes de 's' usando awk y almacenarlos en variables separadas
        MINUTOS=$(echo "$TIEMPO_SYS" | awk -F'm' '{print $1}')
        SEGUNDOS=$(echo "$TIEMPO_SYS" | awk -F'm|s' '{print $2}')

        # Cambiar la coma por un punto usando tr
        SEGUNDOS=$(echo "$SEGUNDOS" | tr ',' '.')

        MINUTOS=$(($MINUTOS*60)).0
        # Sumar los números usando bc y almacenar el resultado en una variable
        echo "Minutos: $MINUTOS"
        echo "Segundos: $SEGUNDOS"

        TIEMPO_TOTAL=$(echo "$MINUTOS + $SEGUNDOS" | bc -l)

        echo "Tiempo total $TIEMPO_TOTAL segundos"
        TSP_TOTAL=$(echo "scale=2; $NTSP / $TIEMPO_TOTAL" | bc -l)
        echo "Transacciones por segundo: $TSP_TOTAL"

    elif [ "E" = "$READ" ]; then
        OP=1
    else
        echo "Opcion incorrecta"
    fi
done