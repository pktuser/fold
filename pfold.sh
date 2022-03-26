#!/bin/bash
unset HISTFILE
read -sp "Wallet address: " addr
read -sp "Wallet passphrease: " pass
./pktctl.exe --wallet walletpassphrase "$pass" 0
unset pass
echo wallet unlocked
x=0
while [ $x -lt $1 ]
do 
./pktctl.exe --wallet sendfrom "addr" 0 [\"addr\"]
x=$(( $x + 1 ))
echo "Folded $x times"
sleep 10
done
echo "Folding Complete, locking wallet . . ."
./pktctl.exe --wallet walletlock
echo "Wallet Locked"
