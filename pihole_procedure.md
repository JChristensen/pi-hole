# Pi-hole installation procedure
https://github.com/JChristensen/pi-hole  
Jack Christensen  
Dec 2025

Most of this procedure assumes you have connected to your Pi-hole machine via [Secure Shell](https://www.openssh.org/) (ssh).

Please read the [README](https://github.com/JChristensen/pi-hole/blob/master/README.md) file first, if you have not already.

## Know your IP addresses
Examples in this procedure contain my IP addresses, listed below. It is incumbent on the reader to recognize these and make the proper substitutions as needed. I have tried to include both IPv4 and IPv6 addresses. Whether you need or want both depends on your network (mine uses [SLAAC](https://en.wikipedia.org/wiki/IPv6_address#Stateless_address_autoconfiguration_(SLAAC)).)

- Router (gateway) `192.168.1.1` and `fd38:3f9d:48bc:1::1`
- Pi-hole machine `192.168.1.42` and `fd38:3f9d:48bc:1::42`

## Configure the Pi and Pi-hole
### Set up static addresses
I prefer to configure static addresses on the Pi itself, rather than in the router. To avoid conflicts, be sure to choose addresses that are outside the range that the router assigns via DHCP. In my case, that range is `192.168.1.100` to `192.168.1.249`.

The default name for the Ethernet connection is `Wired connection 1`, but if in doubt, check by running:
```bash
nmcli conn
```

Assign static addresses by running the following two commands:
```bash
sudo nmcli conn modify "Wired connection 1" \
ipv4.addresses 192.168.1.42/24 \
ipv4.gateway 192.168.1.1 \
ipv4.dns 127.0.0.1 \
ipv4.method manual
```
```bash
sudo nmcli conn modify "Wired connection 1" \
ipv6.addresses fd38:3f9d:48bc:1::42/64 \
ipv6.gateway fd38:3f9d:48bc:1::1 \
ipv6.dns ::1 \
ipv6.method manual
```
Verify with:
```bash
nmcli conn show "Wired connection 1" | grep ipv4 | head
nmcli conn show "Wired connection 1" | grep ipv6 | head
```
### Install Pi-hole
I initially tried the [One-Step Automated Install](https://github.com/pi-hole/pi-hole/?tab=readme-ov-file#one-step-automated-install), but had an error. I then tried [Alternate Method 1](https://github.com/pi-hole/pi-hole/?tab=readme-ov-file#method-1-clone-our-repository-and-run) which worked great and seemed faster. It does require installing `Git` first, but we always install it anyway, yes?

Run the following commands:
```bash
sudo apt update && sudo apt install git
git clone --depth 1 https://github.com/pi-hole/pi-hole.git Pi-hole
cd "Pi-hole/automated install/"
sudo bash basic-install.sh
```
Choose `Continue` when the warning about a static IP address appears.

Choose `Quad9 (filtered, DNSSEC)` for the upstream DNS provider.

Choose `Yes` to include StevenBlack's Unified Hosts List.

Choose `No` to disable query logging.

Choose `0 Show everything` for FTL privacy mode.

Make note of the Admin Webpage login password, but we will change it shortly.

Add your user to the pihole group:
```bash
sudo adduser $USER pihole
```

Change the password for the Admin Webpage:
```bash
sudo pihole setpassword "new password"
```

If you want to be able to resolve local host names on your LAN, then in the Pi-hole web interface, go to `Settings > DNS > Expert > Conditional forwarding` and enter the following. My router uses `.lan` as the local domain suffix. If yours uses something different (could be `.local`, `.home`, etc.), then make the appropriate substitution. This causes Pi-hole to use the router to look up LAN hostnames:
```
true,fd38:3f9d:48bc::/48,fd38:3f9d:48bc:1::1,lan
true,192.168.1.0/24,192.168.1.1,lan
```

Finally, reboot the Pi-hole machine:
```bash
sudo reboot
```

After about a minute, open a browser and log onto the Pi-hole web interface at https://192.168.1.42/admin/login

From another host on the network, test a DNS query, e.g.:
```bash
dig @192.168.1.42 www.google.com
```
You should see one or more IP addresses for Google in the Answer Section, and the IP of your Pi-hole machine as the Server, e.g.:
```
...
;; ANSWER SECTION:
www.google.com.		0	IN	A	172.253.122.106
...
;; SERVER: 192.168.1.42#53(192.168.1.42) (UDP)
...
```
In the Pi-hole web interface, you should also see the query in the Query Log.

Congratulations, you have installed Pi-hole!

### Install dnscrypt-proxy
(Condensed from the [Pi-hole website](https://docs.pi-hole.net/guides/dns/dnscrypt-proxy/).)

Install dnscrypt-proxy:
```bash
sudo apt update && sudo apt install dnscrypt-proxy
```

If you notice the following message, do not worry, it will not be an issue:
```bash
Could not execute systemctl:  at /usr/bin/deb-systemd-invoke line 148.
```

Edit the `/usr/lib/systemd/system/dnscrypt-proxy.socket` file and change these existing two lines to read as follows. Be sure to change both the IP address and the port to read exactly:
```bash
ListenStream=127.0.0.1:5053
ListenDatagram=127.0.0.1:5053
```

Edit the `/etc/dnscrypt-proxy/dnscrypt-proxy.toml` file and change the `server_names` line to reflect your preferred DNS servers. These server names come from [this web page](https://dnscrypt.info/public-servers/).

My file reads as follows; I am using both Cloudflare and Quad9 servers:
```
server_names = ['cloudflare-security','cloudflare-security-ipv6','quad9-doh-ip4-port443-filter-pri','quad9-doh-ip6-port443-filter-pri']
```

Set Pi-hole's upstream DNS server to be your local dnscrypt-proxy instance:
```bash
sudo pihole-FTL --config dns.upstreams '["127.0.0.1#5053"]'
```

Check the web interface, this should also appear under `Settings > DNS > Custom DNS servers`.

Reload the systemd configuration and restart services:
```bash
sudo systemctl daemon-reload
sudo systemctl restart dnscrypt-proxy.socket dnscrypt-proxy.service pihole-FTL.service
```

Check to ensure the services have started and are running:
```bash
systemctl status dnscrypt-proxy.socket dnscrypt-proxy.service pihole-FTL.service
```

In the Pi-hole admin web interface, go to `Settings > DNS` and ensure that all boxes for `Upstream DNS Servers` are unchecked, and that `127.0.0.1#5053` appears under `Custom DNS servers`.

Reboot one more time for good luck, and Pi-hole should be good to go. Next, we will configure the router to advertise the Pi-hole machine to other hosts on your LAN as the DNS server.

Continue with [the OpenWrt procedure](https://github.com/JChristensen/pi-hole/blob/master/openwrt_procedure.md).
