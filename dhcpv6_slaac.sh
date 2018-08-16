#!/bin/sh
#install isc-dhcp-server v4 v6
#creat by feng

INTERFACES=eth0


#CONFIG DHCPV4 ,TEST FOR IP PRIVATE ADDRESS
dhcpv4() {
	cat <<-EOF > /etc/dhcp/dhcpd.conf
		ddns-update-style none;
		option domain-name "example.net";
		option domain-name-servers 172.16.1.100,172.16.1.101;
		option ntp-servers 172.16.1.123;
		option subnet-mask 255.255.255.0;  
		option broadcast-address 172.16.1.255;
		default-lease-time 86400;

		subnet 172.16.1.0 netmask 255.255.255.0 {
		range 172.16.1.40 172.16.1.80;
		option broadcast-address 172.16.1.255;
		option routers 172.16.1.1;
		}

		EOF
	echo "DHCPV4 CONFIG SUCESS"
}


#CONFIG DHCPV6 STATEFUL CONF
dhcpv6_stateful() {
	cat <<-EOF > /etc/dhcp/dhcpd6.conf.stateful
		dhcpv6-lease-file-name "/var/lib/dhcp/dhcpd6.leases";

		subnet6 2001:172:16:1000::/64 {
		interface $INTERFACES;
		range6 2001:172:16:1000::100 2001:172:16:1000::500;
		range6 2001:172:16:1000::/64 temporary;
		option dhcp6.name-servers 2001:172:16:1000::100,2001:172:16:1000::101;
		option dhcp6.domain-search "example.net";
		option dhcp6.sntp-servers 2001:172:16:1000::102;
		#DHCP-PD
		prefix6 2001:172:16:2000:: 2001:172:16:3000:: /64;
		allow leasequery;
		preferred-lifetime 300;
		default-lease-time 600;
		option dhcp-renewal-time 300;
		option dhcp-rebinding-time 600;
		option dhcp6.info-refresh-time 300;
		
		
		}
		EOF
	echo "DHCPV6 STATEFUL SUCESS"
}


#CONFIG DHCPV6 STATELESS CONF
dhcpv6_stateless() {
	cat <<-EOF > /etc/dhcp/dhcpd6.conf.stateless
		subnet6 2001:172:16:1000::/64 {
		interface $INTERFACES;
		option dhcp6.name-servers 2001:172:16:1000::100,2001:172:16:1000::101;
		option dhcp6.domain-search "example.net";
		option dhcp6.sntp-servers 2001:172:16:1000::102;
		#DHCP-PD
		prefix6 2001:172:16:2000:: 2001:172:16:3000:: /64;
		allow leasequery;
		preferred-lifetime 300;
		default-lease-time 600;
		option dhcp-renewal-time 300;
		option dhcp-rebinding-time 600;
		option dhcp6.info-refresh-time 600;
		}
		EOF
	echo "DHCPV6 STATELESS CONFIG SUCESS"
}


#CONFIG radvd.stateful
radvd_stateful() {
	cat <<-EOF > /etc/radvd.conf.stateful
		#stateful
		#M bit=1 ,O bit=1, A bit=0
		interface $INTERFACES {
		   AdvSendAdvert on;
		   MinRtrAdvInterval 30;
		   MaxRtrAdvInterval 600;
		   AdvManagedFlag on;           #M bit=1        
		   AdvOtherConfigFlag on;       #M bit=1        
		   AdvLinkMTU 1500;
		   AdvSourceLLAddress on;
		   AdvDefaultPreference high;
		   prefix 2001:0172:0016:1000::/64
		   {
		   AdvOnLink on;
		   AdvAutonomous off;           #A bit=0        
		   AdvRouterAddr on;
		   AdvPreferredLifetime 3600;
		   AdvValidLifetime 7200;
		   }; 
		route 2001:172:16:1000::/64 {
			};

		};
		EOF
	echo "RADVD STATEFUL SUCESS"
	
}


radvd_stateless() {
	cat <<-EOF > /etc/radvd.conf.stateless
		#stateless
		#M bit=0 ,O bit=1, A bit=1
		interface $INTERFACES {
		   AdvSendAdvert on;
		   MinRtrAdvInterval 30;
		   MaxRtrAdvInterval 600;
		   AdvManagedFlag off;           #M bit=0        
		   AdvOtherConfigFlag on;        #O bit=1        
		   AdvLinkMTU 1500;
		   AdvSourceLLAddress on;
		   AdvDefaultPreference high;
		   prefix 2001:0172:0016:1000::/64
		   {
		   AdvOnLink on;
		   AdvAutonomous on;             #A bit=1        
		   AdvRouterAddr off;
		   AdvPreferredLifetime 3600;
		   AdvValidLifetime 7200;
		   };

		route 2001:172:16:1000::1/64 {
			};

		};
		EOF
	
	echo "RADVD STATELESS SUCESS"
}

radvd_basic() {
	cat <<-EOF > /etc/radvd.conf.basic
		#M bit=1,O bit=1, A bit=1
		interface $INTERFACES {
		   AdvSendAdvert on;
		   MinRtrAdvInterval 30;
		   MaxRtrAdvInterval 600;
		   AdvManagedFlag on;           #M bit=1        
		   AdvOtherConfigFlag on;       #O bit=1         
		   AdvLinkMTU 1500;
		   AdvSourceLLAddress on;
		   AdvDefaultPreference high;
		   prefix 2001:0172:0016:1000::/64
		   {
		   AdvOnLink on;
		   AdvAutonomous on;            #A bit=1        
		   AdvRouterAddr off;
		   AdvPreferredLifetime 3600;
		   AdvValidLifetime 7200;
		   };

		route 2001:172:16:1000::1/64 {
			};

		};
		EOF
	
	echo "RADVD BASIC SUCESS"
}

defconfig() {
	cat <<-EOF > ./mode.conf
		#mode = 1.radvd+dhcp 2.stateless 3.stateful
		#change this option number and run ./dhcp.sh to change mode 
		MODE=2
		#if you want to connect DHCP-PD subnet,you should add default route 
		#that route direct to your ipv6 address that you get from dhcpv6 server(or static address)
		#this option set to your ipv6 address that you should directed
		ROUTE6=2001:172:16:1000::500
		EOF
	
	echo "MODECONF SUCESS"
}

#build script
dhcp_script() {
	cat <<EOF > ./dhcp.sh
		#!/bin/sh
		#ifconfig eth0 inet6 add 2001:172:16::1/64
		#radvd -d -C /etc/radvd.conf
		P_CONF=`pwd`
		. \$P_CONF/mode.conf
		start_s() {
				killall radvd 
				killall dhcpd
				sleep 1
				dhcpd -cf /etc/dhcp/dhcpd.conf
				sleep 2
				dhcpd -6 -cf /etc/dhcp/dhcpd6.conf $INTERFACES -lf /var/log/dhpd6.leases
				sleep 2
				radvd -d -C /etc/radvd.conf
				#start DHCP server
				#set ipv6 address at interface
				ip -6 addr add 2001:172:16:1000::1/64 dev $INTERFACES
				#add defualt route
				ip -6 route add 2001:172:16:1000::/64 dev $INTERFACES
				#route to lan side
				ip -6 route add 2001:172:16:3000::/64 via \$ROUTE6
				#ip -6 route add 2001:172:16::/48 dev eth0 
				# must add ipv6 forwarding 
				echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
				#if dhcpd6.leases does not exist
				#ln -s /var/lib/dhcp/dhcpd6.leases /var/log/dhcpv6/dhcpd6.leases
				echo "DHCPv6 server is up"
		
		}
		stop_s() {
				killall radvd
				killall dhcpd
				ip -6 route del 2001:172:16:1000::/64 dev $INTERFACES
				ip -6 route del 2001:172:16:3000::/64 via \$ROUTE6
				
		}
		setup() {
			if [ \$MODE -eq 1 ]; then
				echo "setup radvd+dhcp"
				cp /etc/radvd.conf.basic /etc/radvd.conf
				cp /etc/dhcp/dhcpd6.conf.stateful /etc/dhcp/dhcpd6.conf
		   
			elif [ \$MODE -eq 2 ]; then
				echo "setup stateless server"
				cp /etc/radvd.conf.stateless /etc/radvd.conf
				cp /etc/dhcp/dhcpd6.conf.stateless /etc/dhcp/dhcpd6.conf
		   
			elif [ \$MODE -eq 3 ]; then
				echo "setup statefull server"
				cp /etc/radvd.conf.stateful /etc/radvd.conf
				cp /etc/dhcp/dhcpd6.conf.stateful /etc/dhcp/dhcpd6.conf
			else 
				echo "MODE is not config"
				echo "slaac+dhcp=0 , stateless=1, stateful=2,stop server= 3"  
			fi
			start_s
		}
		
		case "\$1" in
			restart )
				echo "restart dhcp server"
				start_s
				exit
				;;
			stop )
				echo "stop dhcp server"
				stop_s
				exit
				;;
			* )
				echo "run server now"
				setup
				;;
		esac	
EOF
	
	echo "DHCP SCRIPT CREAT"
}


#config interfaces if you need
interface() {
	cat <<-EOF > /etc/network/interfaces.dhcp
		# This file describes the network interfaces available on your system
		# and how to activate them. For more information, see interfaces(5).

		source /etc/network/interfaces.d/*

		# The loopback network interface
		auto lo
		iface lo inet loopback

		# The primary network interface
		auto $INTERFACES
		#iface $INTERFACES inet dhcp
		iface $INTERFACES inet static 
		address 172.16.1.2
		netmask 255.255.255.0
		network 172.16.1.0
		gateway 172.16.1.1
		dns-nameservers 8.8.8.8

		iface $INTERFACES inet6 static
		address 2001:172:16:1000::1 
		netmask 64
		gateway fe80::1
		EOF
	echo "INTERFACES SUCESS"
}

echo "interface is $INTERFACES now,chick it !"
echo "press enter key to continue:"
read tmp
sudo apt-get update
sudo apt-get install isc-dhcp-server -y
sudo apt-get install radvd -y
#sudo apt-get install bind9 -y
sleep 1
#backup conf
cp /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.old
cp /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server.old
#set dhcp listen interface
echo 'INTERFACES="'$INTERFACES'"' > /etc/default/isc-dhcp-server
dhcpv4
dhcpv6_stateful
dhcpv6_stateless
radvd_stateful
radvd_stateless
radvd_basic
defconfig
dhcp_script
#interface