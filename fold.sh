#!/bin/bash
#https://docs.pkt.cash/en/latest/pktd/pktwallet/
#unset HISTFILE

# a e s t h e t i c s 
RED='\033[31m'
GREEN='\033[32m'
CF='\033[0m' # Clear Formatting
UNDERLINE='\033[4m'
GREY='\033[90m'

pullURL="https://explorer.pkt.cash/api/v1/PKT/pkt/address/"
locktime=3650 #in seconds

loadLog() { # load log to variable
    
    mapfile -t log < fold.log
    pktctl="${log[0]}"
    addr="${log[1]}"
    pass="${log[2]}"
        
}

displayLog() {

    clear
    printf "\n\nLog file loaded as follows:\n\n"
    echo "path:${log[0]}"
    echo "address: ${log[1]}"
    echo "password: ${log[2]}"
    printf "\n"
    read -p "press enter to continue" entr

}

showLog() {
    loadLog
    displayLog
    menuSelect
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
    
    while [ ! -f "$pktctl" ]
    do
        clear
        printf "${RED}/path/to/pktctl as entered is not valid\n"
        printf "Path stored as: $path\n"
        printf "try: $HOME/bin/pktctl${CF}\n"
        read -p "Please re-enter path: " pktctl
    done
    
    while true; do
        clear
        printf "\n\n"
        printf "Would you like to save these settings and your password in a local ${RED}unencrypted${CF} file?\n"
        printf "Please note this is ${RED}very insecure${CF} and puts you at ${RED}risk of theft${CF} if anyone accesses this file\n"
        printf "\n"
        read -p "Type \"yes\" to save (insecure), type \"no\" to continue without saving: " yn
        case $yn in
            yes ) printf "$pktctl\n$addr\n$pass" > fold.log; echo "log saved"; sleep 1; break;;
            no ) echo "inputs not saved"; sleep 1; break;;
        esac
    done

}

menuSelect() {
    
    clear
    PS3="Select: "
    echo "Load saved setting from file?"
    select opt in "Yes" "No" "Show Log" "Delete Log" "Show Status"
    do
        case $opt in
            Yes ) loadLog; break;;
            No ) promptuser; break;;
            "Show Log" ) showLog; break;;
            "Delete Log" ) deleteLog; break;;
            "Show Status" ) walletStatus; break;;
            * ) echo "try again";;
        esac
    done

}

testWallet() {

    printf "\n\nConfirming Wallet is up to date...\n\n"
    wallcurH=1
    wallbackH=2
    wallcurH=`$pktctl --wallet getinfo | grep CurrentHeight | awk '{print $2;}' | tr -d ','`
    wallbackH=`$pktctl --wallet getinfo | grep BackendHeight | awk '{print $2;}' | tr -d ','`
    
    echo "Current block height:  "$wallbackH # block height    
    echo "Current wallet height: "$wallcurH  # wallet height

    range=30 # height must be within $range blocks
    compare=$(($wallbackH-$wallcurH))

    if [ $compare -le $range ]
        then
            printf "\n${GREEN}Wallet sync is within range!\nproceeding to fold${CF}\n"
            sleep 3
        else
            printf "\n${RED}your wallet is not synced. Please sync by running /pktwallet\n"
            printf "\nexiting program . . .${CF}\n\n"
            sleep 3
            exit
    fi

}

walletStatus() {
    
    clear
    utx=`curl -s $pullURL$addr | grep balanceCount | awk '{print $2;}' | tr -d ','`
    echo "Unconsolidated transactions: $utx"

    wallcurH=`$pktctl --wallet getinfo | grep CurrentHeight | awk '{print $2;}' | tr -d ','`
    wallbackH=`$pktctl --wallet getinfo | grep BackendHeight | awk '{print $2;}' | tr -d ','`
    wallTotal=`$pktctl --wallet getaddressbalances 1 1 | grep -w total | awk '{print $2;}' | tr -d ','`

    echo "Current block height:       "$wallbackH # block height    
    echo "Current wallet height:      "$wallcurH  # wallet height
    echo "Wallet total(s): \$PKT      "$wallTotal
    printf "\n\n"

    read -p "press enter to continue" entr

    menuSelect
    
}

clear
printf "\n\n\n${RED}pktwallet must be running in background for pktctl to work${CF}\n\n"
read -p "press enter to confirm, ctrl-c to exit" entr

log=fold.log
if [ -f "$log" ]
    then loadLog; menuSelect

    else promptuser
fi
 
clear
testWallet

$pktctl  --wallet walletpassphrase "$pass" $locktime
unset pass
echo "Wallet unlocked"

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
printf "${GREEN}Transaction hashes saved to transactions.log${CF}\n\n"