#!/bin/bash
#unset HISTFILE
read -p "Wallet address: " addr
read -p "Wallet passphrease: " pass
/bin/pktctl --wallet walletpassphrase "$pass" 0
unset pass
echo wallet unlocked
x=0
while [ $x -lt $1 ]
do 
/bin/pktctl --wallet sendfrom "$addr" 0 [\"$addr\"]
x=$(( $x + 1 ))
echo "Folded $x times"
sleep 10
done
echo "Folding Complete, locking wallet . . ."
/bin/pktctl --wallet walletlock
echo "Wallet Locked"
