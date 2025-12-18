# Pi-hole installation with OpenWrt
https://github.com/JChristensen/pi-hole  
README file  
Jack Christensen  
Dec 2025
## Background
These are notes from my recent installation of [Pi-Hole](https://pi-hole.net/). A few months back, I had tried Pi-hole, but had a couple minor issues. So I shelved the project until I saw [Dad the engineer's](https://www.dad-the-engineer.com/) videos ([here](https://www.youtube.com/watch?v=RoKi4-MCLRw) and [here](https://www.youtube.com/watch?v=SWJ5i7WZmYw)) and [worksheet](https://www.dad-the-engineer.com/blog/rpi-pi-hole-unbound-optional-worksheet), which rekindled my interest. I would encourage you to check out Dad's material; he has done a fine job (his other videos on a range of topics are worthwhile as well.)

Bottom line, Pi-hole is running great; I wish I had tried it sooner! Of course I made a few mistakes along the way; hence these notes. Installation really is straightforward (only easy to say after you have done it) but as ever, details are important.

These notes are specific to my setup, mainly the part about configuring a router running [OpenWrt](https://openwrt.org/). My OpenWrt config is pretty simple but still, YMMV. So while these notes cannot be all things to all people, I hope that some will find them useful, even if in a small way.

## Known issues
My router has a guest network configured as a subnet. It looks like guest DNS requests are routed to Pi-hole, but I think things can be optimized a little. I will update the procedure when I have a better handle on that.

## Unknown issues
Feel free to raise an issue for any errors that you may find here, or for improvements and other suggestions.

## Prerequisites
- A [Raspberry Pi](https://www.raspberrypi.com/products/) running [RPi OS Lite (trixie)](https://www.raspberrypi.com/software/operating-systems/) and connected via Ethernet. This is a headless installation; OpenSSH Server should be installed and enabled.
- A router running OpenWrt 24.10.4 or later.

I used a Raspberry Pi 3 Model B. This (or a 3B+) may be the perfect Pi-hole machine for typical home use. A Pi 4 might be a bit of overkill; a Pi 5 definitely would be. On the Pi 3B, memory utilization is about 20% of 1GB. I do not think I have seen CPU load average with anything to the left of the decimal point, so the machine is really loafing. Power consumption is less than two watts.

Installation of Raspberry Pi OS or OpenWrt, using ssh or creating keys, etc. are outside the scope of these notes. A comfort level with the Linux command line is assumed, including editing configuration files with an editor of your choice, e.g. nano, vim, etc.

## DNS privacy considerations
Dad's video and worksheet included the optional installation of Unbound, for a recursive DNS solution running on the Pi. Hence no need for third-party DNS providers like Cloudflare or Quad9. Unbound communicates directly to DNS root and TLD servers.

I skipped Unbound, and instead installed [dnscrypt-proxy](https://docs.pi-hole.net/guides/dns/dnscrypt-proxy/) to implement DNS-over-HTTPS (DoH). There were two reasons for this: (1) I had previously implemented DoH on the router, and (B) My understanding is that DNS root/TLD servers do not implement encryption such as DoH or DoT.

Therefore the choices were to run Unbound but send unencrypted DNS queries to the root/TLD servers, or to encrypt queries, but then place trust in third party DNS providers.

There is no right answer here. Know your threat model, know who you trust, and proceed accordingly.

I may still try Unbound at some point, because it does sound cool.

## Let's get on with it
Enough with the preliminaries already.  
Go to the [Pi-hole installation procedure](https://github.com/JChristensen/pi-hole/blob/master/pihole_procedure.md).  
Go to the [OpenWrt procedure](https://github.com/JChristensen/pi-hole/blob/master/openwrt_procedure.md).

