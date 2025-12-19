# OpenWrt procedure
https://github.com/JChristensen/pi-hole  
Jack Christensen  
Dec 2025

Here we modify the router to advertise the Pi-hole machine to hosts on the LAN as the DNS server. The router remains as the DHCP server. We assume a (fairly) default installation of OpenWrt.

Below are steps to take using **either** the OpenWrt web interface ([LuCI](https://github.com/JChristensen/pi-hole/blob/master/openwrt_procedure.md#luci-configuration)), **or** the command-line interface ([UCI](https://github.com/JChristensen/pi-hole/blob/master/openwrt_procedure.md#uci-configuration).)

## LuCI configuration

### Advertise Pi-hole as the DNS server for the LAN
Go to `Network > Interfaces > LAN > Edit > DHCP Server > Advanced Settings`.  
Clear any existing entries in the DHCP-Options box(es), then enter `6,` followed by the Pi-hole IPv4 address:
```
6,192.168.1.42
```

Now click on the `IPv6 Settings` tab. In the `Announced IPv6 DHCP servers` box, clear any existing entries, then enter the Pi-hole IPv6 address:
```
fd38:3f9d:48bc:1::42
````

Also, clear the `Local IPv6 DNS server` checkbox.

Click `Save`, then `Save & Apply`.

### Set DNS forwards
Go to 'Network > DHCP and DNS > Forwards'

Delete any existing entries.

Enter the Pi-hole IPv4 and IPv6 addresses (one per box):
```
192.168.1.42
fd38:3f9d:48bc:1::42
```
Click `Save & Apply`.


### Remove any custom DNS servers 

Go to `Network > Interfaces > wan > Advanced Settings` and clear the checkbox `Use DNS servers advertised by peer`.

Also clear any entries in `Use custom DNS servers`.

Click `Save`, then Save & Apply`.

Repeat for the `wan6` interface.

### Dealing with the rogues
At this point, the router is advertising Pi-hole as the DNS server, but this is only a suggestion. Hosts on the LAN can "go rogue," i.e. disregard the suggestion and send DNS requests to a server of their choosing. We can mitigate this with a few firewall rules.

Hat tip to [Jeff Keller](https://jeff.vtkellers.com/posts/technology/force-all-dns-queries-through-pihole-with-openwrt/) for these rules.

#### Port forward rules
These rules (one for IPv4, one for IPv6) redirect any DNS traffic originating on the LAN to the Pi-hole machine. The Pi-hole machine itself is excluded from this rule.

Go to `Network > Firewall > Port Forwards`.  
Click `Add` to create a new rule, and make the following settings on the `General Settings` tab:

Name: `dns_to_pihole_v4`

Source zone: `lan`

External port: `53`

Destination zone: `lan`

Internal IP address: `192.168.1.42` (choose from the drop-down)

Internal port: `53`

Now, on the `Advanced Settings` tab:

Source IP address: `!192.168.1.42`

This last setting ensures that the rule does not apply to the Pi-hole machine. Do not forget the bang (!)

Click `Save`, then `Save & Apply`.

Now add another rule for IPv6. We can do this by clicking the `Clone` button, then the `Edit` button on the new rule. Change the following settings:

Name: `dns_to_pihole_v6`

Internal IP address: `fd38:3f9d:48bc:1::42` (choose your Pi-hole's address from the drop-down)

Advanced Settings > Source IP address: `!fd38:3f9d:48bc:1::42`

Click `Save`, then `Save & Apply`.

#### NAT rules
With just the above rules, the rogue host will notice that the reply did not come from the intended DNS server. These NAT rules will rewrite the source IP on the response to match the original query. (Sneaky.) Again, we have two rules, IPv4 and IPv6.

Go to `Network > Firewall > NAT Rules`.  
Click `Add` to create a new rule, and make the following settings on the `General Settings` tab:

Name: `masq_pihole_v4`

Protocol: `TCP, UDP`

Outbound zone: `lan`

Destination address: `192.168.1.42` (choose from the drop-down)

Destination port: `53`

Action: `MASQUERADE`

Click `Save`, then `Save & Apply`.

Now add another rule for IPv6 by cloning the rule just added. Edit the cloned rule, and change the following settings:

Name: `masq_pihole_v6`

Destination address: `fd38:3f9d:48bc:1::42` (choose your Pi-hole's address from the drop-down)

Click `Save`, then `Save & Apply`.

#### Stop outbound DoT
I added one more rule to stop any rogue host that tries to use DNS-over-TLS (DoT), which is bound for port 853.

Go to `Network > Firewall > Traffic Rules`.  
Click `Add` to create a new rule, and make the following settings on the `General Settings` tab:

Name: `drop_dot`

Protocol: `TCP, UDP`

Source zone: `lan`

Destination zone: `wan, wan6`

Destination port: `853`

Action: `drop`

Click `Save`, then `Save & Apply`.

### Test the firewall rules
We can test the rules by creating a fictitious local DNS entry.  
In the Pi-hole web interface, go to `Settings > Local DNS Records` and enter:

Domain: `piholetest.example.com`

IP: `10.1.2.3`

Then click the green box with the plus sign.

Now, from another host on the network, run the following command, which tries to use Google's DNS server:
```bash
dig piholetest.example.com @8.8.8.8
```

The reply should be as follows, apparently from Google's 8.8.8.8 DNS server, but really from Pi-hole, since Google does not have an address for that name:

```
...
;; ANSWER SECTION:
piholetest.example.com.	0	IN	A	10.1.2.3
...
;; SERVER: 8.8.8.8#53(8.8.8.8) (UDP)
...
```

The local DNS record in Pi-hole can be deleted, or it can be left for future testing.

### The end (LuCI)
At this point I like to reboot the router and the Pi, then check to see if everything is working as planned.

Congratulations! Your OpenWrt router is now working with Pi-hole to minimize unwanted content and keep your DNS queries private.

## UCI configuration
(Stay tuned.)
