#!/bin/bash
#https://docs.pkt.cash/en/latest/pktd/pktwallet/
#unset HISTFILE

# a e s t h e t i c s 
RED='\033[31m'
GREEN='\033[32m'
NF='\033[0m' # No Format
UNDERLINE='\033[4m'
GREY='\033[90m'

pullURL="https://explorer.pkt.cash/api/v1/PKT/pkt/address/"
locktime=7200 #in seconds


clear
printf "\n\n\n${RED}YOUR WALLET MUST BE UP TO DATE PRIOR TO RUNNING THIS COMMAND${NF}\n\npktwallet must be running in background for pktctl to work\n\n\n"
read -p "Press enter to continue, ctrl-c to quit" entr
clear

loadLog() { # load log to variable
    
    mapfile -t log < fold.log
    pktctl="${log[0]}"
    addr="${log[1]}"
    pass="${log[2]}"
    # show variables to user
    displayLog

}

displayLog() {

    clear
    printf "\n\nLog file loaded as follows:\n\n"
    echo "path:${log[0]}"
    echo "address: ${log[1]}"
    echo "password: ${log[2]}"
    printf "\n"
    #read -p "press enter to fold" entr
    sleep 1

}

deleteLog() {

    clear
    rm -rf fold.log
    echo "Log deleted"
    sleep 1
    promptuser

}

promptuser() {
    clear
    read -p "/path/to/pktctl (eg /bin/pktctl): " pktctl
    read -p "Wallet address: " addr
    read -p "Wallet passphrase: " pass
        while true; do
            clear
            printf "\n\n"
            printf "Would you like to save these settings and your password in a local ${RED}unencrypted${NF} file?\n"
            printf "Please note this is ${RED}very insecure${NF} and puts you at ${RED}risk of theft${NF} if anyone accesses this file\n"
            printf "\n"
            read -p "Type \"yes\" to save (insecure), type \"no\" to continue without saving: " yn
        case $yn in
            yes ) printf "$pktctl\n$addr\n$pass" > fold.log; echo "log saved"; sleep 1; break;;
            no ) echo "inputs not saved"; sleep 1; break;;
        esac
        done
}


# testWallet() {
    #in progress for future release
    #test if pktwallet is running
    #test if wallet is updated to latest block on chain
# }

log=fold.log
if [ -f "$log" ]
    then 
        PS3="Select: "
        echo "Load saved setting from file?"
        select opt in "Yes" "No" "Show Log" "Delete Log"
        do
            case $opt in
                Yes ) loadLog;;
                No ) promptuser;;
                "Show Log" ) loadLog;;
                "Delete Log" ) deleteLog;;
                * ) echo "try again";;
            esac
        done
    else promptuser
fi
clear
printf "\n\n"
echo "Command set to: $pktctl  --wallet walletpassphrase "$pass" $locktime"
read -p "If this looks correct, press enter to fold or press ctrl-c to exit" entr
# clear

$pktctl  --wallet walletpassphrase "$pass" $locktime
unset pass
printf "\n\n\n"
echo "Wallet unlocked"
sleep 1

x=0
while true
do
     utx=`curl -s $pullURL$addr | grep balanceCount | awk '{print $2;}' | tr -d ','`
     echo "Unconsolidated transactions: $utx"
    if [ $utx -gt 1200 ]
        then
            $pktctl --wallet sendfrom $addr 0 [\"$addr\"] >> transactions.log
            x=$(( $x + 1 ))
            echo "Folded $x times"
            sleep 10
        else
            echo "Folded $x times"
            break
        fi
done

echo "Folding complete, locking wallet . . ."
$pktctl --wallet walletlock
echo "Wallet Locked"
echo "Transaction id's saved to transactions.log"