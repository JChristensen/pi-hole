#!/bin/ash
# OpenWrt configuration for Pi-hole.
# Originally developed with OpenWrt 24.10.4.
# J.Christensen Dec-2025

setup()
{
    # Set the Pi-hole addresses here
    PIHOLE_IPv4="192.168.1.42"
    PIHOLE_IPv6="fd38:3f9d:48bc:1::42"
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

# dhcp configuration
config_dhcp()
{
    echo "Configuring dhcp..."
    uci -q delete dhcp.lan.dhcp_option
    uci -q delete dhcp.lan.dns
    uci add_list dhcp.lan.dhcp_option="6,${PIHOLE_IPv4}"
    uci add_list dhcp.lan.dhcp_option="6,${PIHOLE_IPv6}"
    uci set dhcp.lan.dns="${PIHOLE_IPv6}"
    uci set dhcp.lan.dns_service="0"
    uci -q delete dhcp.@dnsmasq[0].server
    uci set dhcp.@dnsmasq[0].server="${PIHOLE_IPv4} ${PIHOLE_IPv6}"
    uci commit dhcp
    service dnsmasq restart
}

# firewall configuration
config_firewall()
{
    echo "Configuring firewall rules..."
    uci -q delete firewall.fwd_pihole_v4
    uci set firewall.fwd_pihole_v4="redirect"
    uci set firewall.fwd_pihole_v4.name="fwd_pihole_v4"
    uci set firewall.fwd_pihole_v4.dest="lan"
    uci set firewall.fwd_pihole_v4.target="DNAT"
    uci set firewall.fwd_pihole_v4.src="lan"
    uci set firewall.fwd_pihole_v4.src_ip="!${PIHOLE_IPv4}"
    uci set firewall.fwd_pihole_v4.src_dport="53"
    uci set firewall.fwd_pihole_v4.dest_ip="${PIHOLE_IPv4}"
    uci set firewall.fwd_pihole_v4.dest_port="53"

    uci -q delete firewall.fwd_pihole_v6
    uci set firewall.fwd_pihole_v6="redirect"
    uci set firewall.fwd_pihole_v6.name="fwd_pihole_v6"
    uci set firewall.fwd_pihole_v6.dest="lan"
    uci set firewall.fwd_pihole_v6.target="DNAT"
    uci set firewall.fwd_pihole_v6.src="lan"
    uci set firewall.fwd_pihole_v6.src_ip="!${PIHOLE_IPv6}"
    uci set firewall.fwd_pihole_v6.src_dport="53"
    uci set firewall.fwd_pihole_v6.dest_ip="${PIHOLE_IPv6}"
    uci set firewall.fwd_pihole_v6.dest_port="53"

    uci -q delete firewall.nat_pihole_v4
    uci set firewall.nat_pihole_v4="nat"
    uci set firewall.nat_pihole_v4.name="nat_pihole_v4"
    uci set firewall.nat_pihole_v4.proto="tcp udp"
    uci set firewall.nat_pihole_v4.src="lan"
    uci set firewall.nat_pihole_v4.dest_ip="${PIHOLE_IPv4}"
    uci set firewall.nat_pihole_v4.dest_port="53"
    uci set firewall.nat_pihole_v4.target="MASQUERADE"

    uci -q delete firewall.nat_pihole_v6
    uci set firewall.nat_pihole_v6="nat"
    uci set firewall.nat_pihole_v6.name="nat_pihole_v6"
    uci set firewall.nat_pihole_v6.proto="tcp udp"
    uci set firewall.nat_pihole_v6.src="lan"
    uci set firewall.nat_pihole_v6.dest_ip="${PIHOLE_IPv6}"
    uci set firewall.nat_pihole_v6.dest_port="53"
    uci set firewall.nat_pihole_v6.target="MASQUERADE"

    uci -q delete firewall.drop_dot
    uci set firewall.drop_dot="rule"
    uci set firewall.drop_dot.name="drop_dot"
    uci set firewall.drop_dot.src="lan"
    uci set firewall.drop_dot.dest="wan"
    uci set firewall.drop_dot.dest_port="853"
    uci set firewall.drop_dot.target="DROP"

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
config_wan
config_dhcp
config_firewall
echo "Script complete at $(date "+%F %T")"
