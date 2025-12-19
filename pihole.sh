#!/bin/ash
# OpenWrt configuration for Pi-hole
# Originally developed with OpenWrt 24.10.4.
# J.Christensen Dec-2025

setup()
{
    # Set the Pi-hole addresses here
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

# firewall configuration
config_firewall()
{
    echo "Configuring firewall rules..."
    # uci -q delete ???
    uci set firewall.@redirect[-1].name="dns_to_pihole_v4"
    uci set firewall.@redirect[-1]="redirect"
    uci set firewall.@redirect[-1].dest="lan"
    uci set firewall.@redirect[-1].target="DNAT"
    uci set firewall.@redirect[-1].src="lan"
    uci set firewall.@redirect[-1].src_ip="!${PIHOLE_IPv4}"
    uci set firewall.@redirect[-1].src_dport="53"
    uci set firewall.@redirect[-1].dest_ip="${PIHOLE_IPv4}"
    uci set firewall.@redirect[-1].dest_port="53"

    # uci -q delete ???
    uci set firewall.@redirect[-1].name="dns_to_pihole_v6"
    uci set firewall.@redirect[-1]="redirect"
    uci set firewall.@redirect[-1].dest="lan"
    uci set firewall.@redirect[-1].target="DNAT"
    uci set firewall.@redirect[-1].src="lan"
    uci set firewall.@redirect[-1].src_ip="!${PIHOLE_IPv6}"
    uci set firewall.@redirect[-1].src_dport="53"
    uci set firewall.@redirect[-1].dest_ip="${PIHOLE_IPv4}"
    uci set firewall.@redirect[-1].dest_port="53"
    uci set firewall.@redirect[-1].reflection="0"

    # uci -q delete ???
    uci set firewall.@nat[-1].name="masq_pihole_v4"
    uci set firewall.@nat[-1]="nat"
    uci set firewall.@nat[-1].proto="tcp udp"
    uci set firewall.@nat[-1].src="lan"
    uci set firewall.@nat[-1].dest_ip="${PIHOLE_IPv4}"
    uci set firewall.@nat[-1].dest_port="53"
    uci set firewall.@nat[-1].target="MASQUERADE"

    # uci -q delete ???
    uci set firewall.@nat[-1].name="masq_pihole_v6"
    uci set firewall.@nat[-1]="nat"
    uci set firewall.@nat[-1].proto="tcp udp"
    uci set firewall.@nat[-1].src="lan"
    uci set firewall.@nat[-1].dest_ip="${PIHOLE_IPv6}"
    uci set firewall.@nat[-1].dest_port="53"
    uci set firewall.@nat[-1].target="MASQUERADE"

    # uci -q delete ???
    uci set firewall.@rule[-1].name="drop_dot"
    uci set firewall.@rule[-1]="rule"
    uci set firewall.@rule[-1].src="lan"
    uci set firewall.@rule[-1].dest="wan"
    uci set firewall.@rule[-1].dest_port="853"
    uci set firewall.@rule[-1].target="DROP"

    uci commit firewall
    service firewall restart
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
config_firewall
#config_wireless
echo "Script complete at $(date "+%F %T")"
