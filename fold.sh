#!/bin/bash
#https://docs.pkt.cash/en/latest/pktd/pktwallet/
#unset HISTFILE
pullURL="https://explorer.pkt.cash/api/v1/PKT/pkt/address/"
locktime=7200 #in seconds

clear
printf "\n\n\nYOUR WALLET MUST BE UP TO DATE PRIOR TO RUNNING THIS COMMAND\n\n\n"
read -p "press enter to continue, ctrl-c to quit" entr
clear

loadlog() {
    mapfile -t log < fold.log
    clear
    printf "\n\n loading log file . . ."
    echo "address:${log[0]}"
    echo "address: ${log[1]}"
    echo "password: ${log[2]}"
    read -p "press enter to continue" entr
}

promptuser() {
    read -p "/path/to/pktctl (eg /bin/pktctl): " pktctl
    read -p "Wallet address: " addr
    read -p "Wallet passphrase: " pass
    printf "\n\n"
    echo "Would you like to save these settings and your password in a local unencrypted file?"
    echo "Please note this is very insecure and puts you at risk of theft if anyone accesses this file"

    echo "Yes to save (insecure), No to continue without saving"
        select yn in "Yes" "No"; do
        case $yn in
            Yes ) printf "$pktctl\n$addr\n$pass" > fold.log; break;;
            No ) break;;
        esac
    done
}

log=/fold.log
if [ -f $log ]; then loadlog(); else promptuser(); fi

clear
printf "\n\n"
read -p "press ctrl-c to exit" entr

$pktctl  --wallet walletpassphrase "$pass" $locktime
unset pass

echo "Wallet unlocked"

x=0
while true
do
    # curl https://explorer.pkt.cash/api/v1/PKT/pkt/address/pkt1q9dczv9ne8mfg98aya90kepflk2j2whhfqqn0mk | grep balanceCount | awk '{print $2;}' | tr -d ',' 
    utx=`curl $pullurl$addr | grep balanceCount | awk '{print $2;}' | tr -d ','`



x=0
while [ $x -lt $1 ]
do 
#/bin/pktctl --wallet sendfrom $addr 0 [\"$addr\"]
x=$(( $x + 1 ))
echo "Folded $x times"
sleep 10
done
echo "Folding Complete, locking wallet . . ."
/bin/pktctl --wallet walletlock
echo "Wallet Locked"
