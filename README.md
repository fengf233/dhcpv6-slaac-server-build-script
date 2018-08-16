# dhcpv6-slaac-server-build-script
A script to build a dhcpv6+slaac test environment（for Ubuntu）  
- use **dhcpv6_slaac.sh** can build a dhcpv6+slaac test environment on your ubuntu server  
- **./dhcp.sh** to run restart stop server  
- **/etc/dhcp/dhcpd.conf** is dhcpv4 config  
- **/etc/dhcp/dhcpd6.conf.stateful** is dhcpv6 config that RA's flag  M bit=1 ,O bit=1,use dhcp address
- **/etc/dhcp/dhcpd6.conf.stateless** is dhcpv6 config that RA's flag M bit=0 ,O bit=1,use slaac address  
- **/etc/radvd.conf.stateful** M bit=1 ,O bit=1, A bit=0  
- **/etc/radvd.conf.stateless** M bit=0 ,O bit=1, A bit=1  
- **/etc/radvd.conf.basic** M bit=1 ,O bit=1, A bit=1
