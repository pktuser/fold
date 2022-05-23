#!/bin/bash
#https://docs.pkt.cash/en/latest/pktd/pktwallet/
#unset HISTFILE

###################################### W A L L E T  B O S S  B R A N C H ###############################

# a e s t h e t i c s 
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CF='\033[0m' # Clear Formatting
UNDERLINE='\033[4m'
GREY='\033[90m'

pullURL="https://explorer.pkt.cash/api/v1/PKT/pkt/address/"
locktime=9001 #in seconds
pktctl="/bin/pktctl"

testLog() {

    log=fold.log
    if [ -f "$log" ]
        then loadLog
        else promptUser
    fi

}

loadLog() { # load log to variable
    
    mapfile -t log < fold.log
    pktctl="${log[0]}"
    addr="${log[1]}"
    pass="${log[2]}"

    clear
    printf "\n${GREEN}Settings successfully loaded${CF}"
    sleep 1

    menuSelect
        
}

displayLog() {

    clear
    printf "\n\nLog file loaded as follows:\n\n"
    echo "path:${log[0]}"
    echo "address: ${log[1]}"
    echo "password: ${log[2]}"
    printf "\n"
    read -p "press enter to continue" entr

    menuSelect

}

deleteLog() {

    clear
    rm -rf fold.log
    unset $pass
    printf "\n${GREEN}Saved settings deleted${CF}"
    sleep 1
    promptUser

}

promptUser() {
   
    clear
#   read -p "/path/to/pktctl (eg /bin/pktctl): " pktctl #probably not needed - default install path ok
    read -p "Wallet address: " addr
    read -p "Wallet passphrase: " pass
    
    while [ ! -f "$pktctl" ] #test if pktctl file exists in default location
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
            yes ) printf "$pktctl\n$addr\n$pass" > fold.log; printf "\n${GREEN}log saved${CF}"; sleep 1; break;;
            no ) printf "\n${GREEN}inputs not saved${CF}\n"; sleep 1; break;;
        esac
    done

    menuSelect

}

menuSelect() {
    
    clear
    PS3="Select: "
    COLUMNS=0
    echo "What would you like to do?"
    select opt in "Load Saved Settings" "Enter New Settings" "Display Saved Settings" "Delete Saved Settings" "Show Wallet Status" "Fold Coins" "Show Transactions Log" "Exit"
    do
        case $opt in
            "Load Saved Settings" ) loadLog; break;;
            "Enter New Settings" ) promptUser; break;;
            "Display Saved Settings" ) displayLog; break;;
            "Delete Saved Settings" ) deleteLog; break;;
            "Show Wallet Status" ) walletStatus; break;;
            "Fold Coins" ) fold; break;;
            "Show Transactions Log" ) showTX; break;;
            "Exit" ) exit;;
            * ) echo "try again";;
        esac
    done

}

showTX() {
    
    cat transactions.log | more
    read -p "press enter to continue" entr
    menuSelect

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
            fold
        else
            printf "\n${RED}your wallet is not synced. Please sync by running /pktwallet\n"
            menuSelect
    fi

}

sendPKT() {
    #function call to send PKT
    echo "sendPKT()"
}

addressBook() {
    #save sendto addresses to an array or something
    echo "addressBook()"
}

walletStatus() {
    
    clear

    #utx=`curl -s $pullURL$addr | grep balanceCount | awk '{print $2;}' | tr -d ','`
    addrValues=`curl -s $pullURL$addr`
    utx="`echo "$addrValues" | grep balanceCount | awk '{print $2;}' | tr -d ','`"
    echo "Unconsolidated transactions...: $utx"
    
    wallMinedRaw="`echo "$addrValues" | grep mined24 | awk '{print $2;}' | tr -d ',"'`"
    wallMined24="`echo "scale=2 ; $wallMinedRaw / 1073741824" | bc`"
    echo "PKT mined previous 24 hours...: $wallMined24"

    #current hashrate
    whotopay=`curl -s http://pool.pkt.world/pay/whotopay`
    hashrate="`echo "$whotopay" | grep -A 5 "$addr" | grep "currentEncryptionsPerSecond" | awk '{print $2}' | tr -d ','`"
    hashrate="`echo "$hashrate / 1000" | bc`"
    hashrate="`printf "%'d" $hashrate`"
    echo "Current mining hashrate to wallet: $hashrate Ke/s"
    #current bandwidth
    bandwidthRaw="`echo "$whotopay" | grep -A 5 "$addr" | grep "kbps" | awk '{print $2}' | tr -d ','`"
    bandwidth="`echo "scale=2 ; $bandwidthRaw / 1000" | bc`"
    bandwidth="`printf "%'.2f" $bandwidth`"
    echo "Current mining bandwidth to wallet: $bandwidth mbps"

    wallcurH=`$pktctl --wallet getinfo | grep CurrentHeight | awk '{print $2;}' | tr -d ','`
    wallbackH=`$pktctl --wallet getinfo | grep BackendHeight | awk '{print $2;}' | tr -d ','`
    compare=$(($wallbackH-$wallcurH))
    wallBal=(`$pktctl --wallet getaddressbalances 1 1 | grep -w total | awk '{print $2;}' | tr -d ','`)
    wallBal=(`printf "%'.2f\n" ${wallBal[@]}`)
    wallAddr=(`$pktctl --wallet getaddressbalances 1 1 | grep -w address | awk '{print $2;}' | tr -d ',"'`)



    if [[ $compare -eq 0 ]]; then            
            lag="${GREEN}Wallet is fully synced!${CF}"
        elif [[ $compare -gt 0 ]] && [[ $compare -le 30 ]]; then
            lag="${GREEN}Wallet is $compare blocks behind blockchain. It is safe to fold.${CF}\n"
        else
            lag="${RED}Wallet is $compare blocks behind blockchain. Advisable to wait before folding.${CF}\n"
    fi

    if [[ $utx -gt 1439 ]] && [[ $compare -le 30 ]]; then
            txlag="${YELLOW}Folding is recommended.${CF}\n"
        elif [[ $utx -gt 1439 ]] && [[ $compare -gt 29 ]]; then
            txlag="${RED}Folding recommended but allow wallet height to sync before folding."
        elif [[ $utx -lt 1440 ]]; then
            txlag="${GREEN}Unconsolidated tx's are low - no need to fold!${CF}"

    fi

    echo "Current block height..........: "$wallbackH # block height    
    echo "Current wallet height.........: "$wallcurH  # wallet height
    printf "\nWallet Balance(s):\n"
    for (( i=0; i<${#wallAddr[@]}; ++i ))
    do
        printf "Address [$i]: "${wallAddr[i]}
        printf "${GREEN} PKT: "${wallBal[i]}"\n${CF}"
    done

    numFolds=`echo "scale=0 ; $utx / 1440" | bc`
    timetoFold=$( bc <<<"10*$numFolds" )

    if [[ $numFolds -gt 0 ]]; then

        printf "\n${GREEN}Program estimates $numFolds folds required to consolidate mining income.\n"
        printf "Estimated time to complete is $timetoFold seconds.${CF}"

    fi

    printf "\n\n"
    printf "$lag\n"
    printf "$txlag\n"
    printf "\n"

    read -p "press enter to continue" entr

    menuSelect
    
}


fold() {

    $pktctl  --wallet walletpassphrase "$pass" $locktime
    unset pass
    
    echo "Wallet unlocked"
    echo "Beginning fold task"

    x=0
    while true
    do

        utx=`curl -s $pullURL$addr | grep balanceCount | awk '{print $2;}' | tr -d ','`
        echo "Unconsolidated transactions: $utx"

        if [ $utx -gt 1440 ]
        then
            $pktctl --wallet sendfrom $addr 0 [\"$addr\"] >> transactions.log
            x=$(( $x + 1 ))
            echo "Folded $x times"
            sleep 8
        else
            break
        fi

    done

    echo "Folding complete, locking wallet . . ."
    $pktctl --wallet walletlock
    echo "Wallet Locked"
    printf "${GREEN}Transaction hashes saved to transactions.log${CF}\n\n"
    read -p "Press enter to continue" entr

    menuSelect

}


# function calls
clear
printf "\n\n\n${RED}pktwallet must be running in background for pktctl to work${CF}\n\n"
read -p "press enter to confirm, ctrl-c to exit" entr
clear
testLog


