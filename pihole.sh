#!/bin/ash
# OpenWrt configuration for Pi-hole
# Originally developed with OpenWrt 24.10.4.
# J.Christensen Dec-2025

setup()
{
    PIHOLE_IPv4="192.168.1.42"
    PIHOLE_IPv6="fd38:3f9d:48bc:1::42"
}

# dhcp configuration
config_dhcp()
{
    echo "Configuring dhcp..."
	uci -q delete dhcp.lan.dhcp_option
	uci -q delete dhcp.lan.dns
	uci set dhcp.lan.dhcp_option="6,${PIHOLE_IPv4}"
	uci set dhcp.lan.dns="${PIHOLE_IPv6}"
	uci set dhcp.lan.dns_service="0"
	uci -q delete dhcp.@dnsmasq[0].server
	uci set dhcp.@dnsmasq[0].server="${PIHOLE_IPv4} ${PIHOLE_IPv6}"
    uci commit dhcp
    service dnsmasq restart
}

# wan configuration
config_wan()
{
    echo "Configuring WAN..."
    uci -q delete network.wan.dns
    uci -q delete network.wan6.dns
    uci set network.wan.peerdns="0"
    uci set network.wan6.peerdns="0"
    uci commit network
    service network restart
}

#---- MAIN SCRIPT STARTS HERE ----#
# redirect output to a log file
PROGNAME=$(basename -s .sh $0)
exec 1>>$PROGNAME.log
exec 2>&1

echo "Script starting at $(date "+%F %T")"
setup
#config_system
#config_lan
config_wan
config_dhcp
#config_firewall
#config_wireless
echo "Script complete at $(date "+%F %T")"
