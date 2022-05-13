#!/bin/bash
#https://docs.pkt.cash/en/latest/pktd/pktwallet/
#unset HISTFILE
pullURL="https://explorer.pkt.cash/api/v1/PKT/pkt/address/"
locktime=7200 #in seconds

clear
printf "\n\n\nYOUR WALLET MUST BE UP TO DATE PRIOR TO RUNNING THIS COMMAND\n\n\n"
printf "run pktwallet\n\n\n"
read -p "press enter to continue, ctrl-c to quit" entr
clear

loadlog() {
    PS3="Select 1 - yes, 2 - no, 3 - delete log: "
    echo "Load saved setting from file?"
        select yn in "Yes" "No" "Delete"; do
        case $yn in
            Yes ) break;;
            No ) promptuser; return; break;;
            Delete ) rm -rf fold.log; promptuser; return; break;;
        esac
    done

    mapfile -t log < fold.log
    clear
    printf "\n\nLog file loaded, as follows:\n\n"
    echo "path:${log[0]}"
    pktctl="${log[0]}"
    echo "address: ${log[1]}"
    addr="${log[1]}"
    echo "password: ${log[2]}"
    pass="${log[2]}"
    read -p "press enter to continue" entr
}

promptuser() {
    clear
    read -p "/path/to/pktctl (eg /bin/pktctl): " pktctl
    read -p "Wallet address: " addr
    read -p "Wallet passphrase: " pass
    printf "\n\n"
    echo "Would you like to save these settings and your password in a local unencrypted file?"
    echo "Please note this is very insecure and puts you at risk of theft if anyone accesses this file"
    printf "\n"
    read -p "Type \"yes\" to save (insecure), type \"no\" to continue without saving: " yn
#        select yn in "yes" "no"; do
        case $yn in
            yes ) printf "$pktctl\n$addr\n$pass" > fold.log; break;;
            no ) break;;
            * ) echo "type yes or no";;
        esac
#    done
}

log=fold.log
if [ -f "$log" ]; then loadlog; else promptuser; fi
#if [ -z "$v"   ]; then verbmode="verbose"; else verbmode="silent"; fi

clear
printf "\n\n"
read -p "press enter to fold or press ctrl-c to exit" entr
clear
$pktctl  --wallet walletpassphrase "$pass" $locktime
unset pass
printf "\n\n\n"
echo "Wallet unlocked"
sleep 1
x=0
while true
do
     #eval curl https://explorer.pkt.cash/api/v1/PKT/pkt/address/pkt1q9dczv9ne8mfg98aya90kepflk2j2whhfqqn0mk | grep balanceCount | awk '{print $2;}' | tr -d ',' > utx
     utx=`curl -s $pullURL$addr | grep balanceCount | awk '{print $2;}' | tr -d ','`
     #utx=`curl -s https://explorer.pkt.cash/api/v1/PKT/pkt/address/pkt1q9dczv9ne8mfg98aya90kepflk2j2whhfqqn0mk | grep balanceCount | awk '{print $2;}' | tr -d ','`
     #echo $pullURL
     #echo $addr
     #echo "utx value: $utx"
     #read -p "press enter to continue" entr

    if [ $utx -gt 1200 ]
        then
            $pktctl --wallet sendfrom $addr 0 [\"$addr\"]
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
