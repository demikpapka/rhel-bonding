#!/bin/bash
# by Evgeny Sorokine demikgame@gmail.com
# Settin up virtual bonding interface bond0 using nmcli from two connected physical interfaces
# The executing of this script assumes that logged to the system as root user, otherwise - sudo addons on each line is needed.
# This script is for LACP (CISCO) or LAG (Other Link Aggregation protocols) assumed that Switches are already configured in these modes.
# 
# Please, change the parameters below for your own environment (NICs, bonding types, system IPs etc)
# 
# !!!Be careful, this script de-activates network connections via NICs!!! If you are connected via SSH using these NICs, please consider console (iDRAC, CIMC, ILO etc) access via KVM or direct control on the machine!!!
##

ETH1="enp2s0f0"       # Network Interface 1 - Please check and change the name!
ETH2="enp2s0f1"       # Network Interface 2 - Please check and change the name!
BOND="bond0"          # Virtual Bonding Interface - You can leave it default or change.
TYPE="4"           # Bonding Modes for the Virtual Interface. 0 = Balance Round-Robin, 1 = Active - Backup, 2 = Balance - XOR, 3 = Broadcast, 4 = 802.3ad LACP or LAG, 5 = Balance - TLB, 6 = Balance - ALB
SYSIP="x.x.x.x"  # Desired IP address for the virtual bonding interface
MASK="24"        # Network Mask CIDR (For Example = 24 for 255.255.255.0)
GW="x.x.x.x"     # Default Gateway IP Address
DNSIP="x.x.x.x"  # DNS server IP Address
SDNS="x.xyz.x"   # Domain Name

# Turning off the NICs which are desired for the bonding

ip link set dev ${ETH1} down
ip link set dev ${ETH2} down

# Creating new Bonding Interface with parameters mentioned above
nmcli connection add type bond con-name ${BOND} ifname ${BOND} bond.options mode=${TYPE},xmit_hash_policy=2

# Add two Slave type Ethernet connections on the physical NICs to the virtual bonding interface
nmcli connection add type ethernet slave-type bond con-name ${BOND}-port1 ifname ${ETH1} master ${BOND}
nmcli connection add type ethernet slave-type bond con-name ${BOND}-port2 ifname ${ETH2} master ${BOND}

# Setting Up the IP configurations for the new bonding interface mentioned above
nmcli connection modify ${BOND} ipv4.addresses ${SYSIP}/${MASK} # ip/netmask
nmcli connection modify ${BOND} ipv4.gateway ${GW}  # your gateway IP
nmcli connection modify ${BOND} ipv4.dns ${DNSIP}  # your DNS server
nmcli connection modify ${BOND} ipv4.dns-search ${SDNS}  # your dns domain
nmcli connection modify ${BOND} ipv4.method manual  # this is a static IP

# Activate the Virtual Bonding Interface connection
nmcli connection up ${BOND}

# Show and Verify new connection
nmcli device && nmcli connection show

# Setting up Auto connection for the slaves
nmcli connection modify ${BOND} connection.autoconnect-slaves 1

# Reload the virtual connection
nmcli connection up ${BOND}

# To show the status of the bonding interface
cat /proc/net/bonding/${BOND}
