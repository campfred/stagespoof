#!/bin/bash

HOSTS_SPOOF_HEADER="##\n# Spoofed for Akamai staging tests\n##"

show_title() {
	cat <<EOF

░▄▀▀░▀█▀▒▄▀▄░▄▀▒▒██▀░▄▀▀▒█▀▄░▄▀▄░▄▀▄▒█▀
▒▄██░▒█▒░█▀█░▀▄█░█▄▄▒▄██░█▀▒░▀▄▀░▀▄▀░█▀
Version 2023.6

EOF
}

show_help() {
	cat <<EOF
usage: stagespoof <domain 1> <domain n> | --reset/--clear/--clean | --help | --version

Spoofs a domain with the staging one, automagically.
Or reverts to normal when resetting.

Subdomains (ex.: ctv) can be specified if desired to spoof only this subdomain's hosts.

Report bugs to: @campfred on GitHub
stagespoof home page: https://github.com/campfred/stagespoof
Reference used: https://community.akamai.com/customers/s/article/How-to-test-using-Akamai-s-Staging-Network-1386937927433
EOF
}

setup_proxy() {
	echo "🔍 Checking proxy setup..."
	system_proxy_macos_server=$(networksetup -getsecurewebproxy "Wi-Fi" | grep "Server" | awk '{print $2}')
	echo $system_proxy_macos_server
	echo ${#system_proxy_macos_server}
	if ((${#system_proxyserver_macos} > 0)); then
		system_proxy_macos_port=$(networksetup -getsecurewebproxy "Wi-Fi" | grep "Port" | awk '{print $2}')
		echo $system_proxy_macos_port
		system_proxy_macos=$system_proxy_macos_server:$system_proxy_macos_port
		echo $system_proxy_macos
		export HTTPS_PROXY=$system_proxy_macos
		echo "ℹ️ Using $HTTS_PROXY from macOS Network Setup"
	fi
	# read
}

restart_resolver() {
	echo "🚀 Restarting resolver..."
	killall -HUP mDNSResponder
	echo "✅ Resolver restarted."
	echo
}

clear_cache() {
	echo "🗑️ Clearing DNS cache..."
	sudo dscacheutil -flushcache
	echo "✅ DNS cache cleared."
	echo
}

read_hosts_file() {
	echo -e "\nCurrent content for hosts file:"
	cat /etc/hosts
	echo
}

reset_hosts() {
	echo "🔄 Resetting hosts poutine..."
	if test -f /etc/hosts.bak; then
		echo "📄 Moving backup file in place..."
		yes | sudo mv -f /etc/hosts.bak /etc/hosts
		cat /etc/hosts
	elif test -f /etc/hosts.example; then
		echo "📄 Copying template in place..."
		yes | sudo cp -f /etc/hosts.orig /etc/hosts
		cat /etc/hosts
	else
		echo "📝 Rewriting to basic file..."
		sudo tee /etc/hosts <<EOF
##
# Host Database
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##

127.0.0.1               localhost
255.255.255.255         broadcasthost
::1                     localhost
EOF
	fi
	echo -e "\n✨ Hosts file reset."
}

backup_hosts() {
	echo "⛑️ Backing up hosts file to hosts.bak..."
	sudo cp /etc/hosts /etc/hosts.bak
	is_backup_done=true
	echo -e "✅ Hosts file backed up to hosts.bak.\n"
}

write_hosts() {
	echo -e "✏️ Writing poutine in hosts file..."
	echo -e "\n$HOSTS_SPOOF_HEADER\n$1" | sudo tee -a /etc/hosts
}

spoof_host() {
	echo "🎭 Generating spoof entry for $1..."
	# curl "https://networkcalc.com/api/dns/lookup/$1" --silent | jq
	akamai_fqdn_prd=$(curl "https://networkcalc.com/api/dns/lookup/$1" --silent | jq ".records.CNAME[0].address" -r)
	# echo $akamai_fqdn_prd
	# curl "https://networkcalc.com/api/dns/lookup/$akamai_fqdn_prd" --silent | jq
	akamai_ip_prd=$(curl "https://networkcalc.com/api/dns/lookup/$akamai_fqdn_prd" --silent | jq ".records.A[0].address" -r)
	# echo $akamai_ip_prd

	akamai_fqdn_stg="${akamai_fqdn_prd/edgekey.net/edgekey-staging.net}"
	# echo $akamai_fqdn_stg
	echo -e "💭 $1's canonical name on Akamai is $akamai_fqdn_prd for Production and $akamai_fqdn_stg for Staging."
	# curl "https://networkcalc.com/api/dns/lookup/$akamai_fqdn_stg" --silent | jq
	akamai_ip_stg=$(curl "https://networkcalc.com/api/dns/lookup/$akamai_fqdn_stg" --silent | jq ".records.A[0].address" -r)
	# echo $akamai_ip_stg
	echo -e "🔀 $1 will now now resolve to $akamai_ip_stg instead of $akamai_ip_prd.\n"

	# sleep 30
	# read
	spoof_entry="$akamai_ip_stg		$1"
	# echo -e $spoof_entry
	spoof_entries="${spoof_entries}${spoof_entry}\n"
}

has_work_been_done=false
is_backup_done=false
spoof_entries=""
show_title
while [[ $# -gt 0 ]]; do
	case $1 in
	-r | --reset | -c | --clear | --clean)
		reset_hosts
		read_hosts_file
		exit 0
		;;
	-h | --help)
		show_help
		exit 0
		;;
	-* | --*)
		echo "❗️ Unknown option $1.\n🌬️ *flees out of confusion in French*"
		exit 1
		;;
	*)
		if [[ $spoof_entries == "" ]]; then
			echo "✨ Beginning spoofing domains..."
			# echo -e "ℹ️ Multiple entries may be spoofed in one go as the Hosts file does not support wild card entries.\n"
		fi
		if [[ $is_backup_done == false ]]; then
			backup_hosts
			setup_proxy
		fi
		DOMAIN=$1
		spoof_host $1
		has_work_been_done=true
		shift
		;;
	esac
done

if [ -n "$spoof_entries" ]; then
	write_hosts "$spoof_entries"
fi
if $has_work_been_done; then
	clear_cache
	restart_resolver
	echo "🎉 Finished!"
	read_hosts_file
fi
