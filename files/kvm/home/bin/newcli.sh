usage() {
  printf "\nUsage: $0 <hostname> <username> <vnc-port> <network>
<hostname>: The hostname of the new VM
<username>: The non-root username to create
<vnc-port>: The port to listen on for VNC connections
<network>: The libvirt network to attach the VM to\n\n"
  exit 1
}

hostname="$1"
username="$2"
vnc_port="$3"
network="$4"

if [ -z "$hostname" -o -z "$username" -o -z "$vnc_port" -o -z "$network" ]; then
  usage
fi

tmp_ks=$(mktemp)
tmp_ks_basename=$(basename "$tmp_ks")

printf "#version=RHEL7
bootloader --append=\"console=ttyS0\" --location=mbr
clearpart --all --drives=vda
cmdline
eula --agreed
firewall --enabled --ssh --service=mdns
firstboot --disable
ignoredisk --only-use=vda
install
cdrom
keyboard --vckeymap=us --xlayouts=us
lang en_US
network --activate --bootproto=dhcp --device=eth0 --ipv6=auto --hostname=$hostname.local --onboot=yes
part /boot --fstype=xfs --ondisk=vda --size=1000
part pv.01 --ondisk=vda --grow
volgroup vg01 pv.01
logvol / --vgname=vg01 --name=lv_root --size=50000
logvol swap --vgname=vg01 --name=lv_swap --size=2000
logvol /home --vgname=vg01 --name=lv_home --percent=100
reboot
rootpw --plaintext lab
selinux --enforcing
timezone --utc America/New_York
user --name=$username --groups wheel --password lab --plaintext
xconfig --startxonboot
zerombr

%%packages 
@^Minimal Install
%%end

%%post
# Workaround to skip firstboot/initial setup
# See https://bugs.centos.org/view.php?id=12584
systemctl disable initial-setup-graphical.service
%%end" > "$tmp_ks"

virt-install \
--name "$hostname" \
--memory "1000" \
--vcpus=4 \
--cpuset=auto \
--cpu host \
--location "/kvm_pool/isos/CentOS-7-x86_64-Everything-1611.iso" \
--extra-args "console=ttyS0 ks=file:/$tmp_ks_basename" \
--initrd-inject="$tmp_ks" \
--os-variant="rhel7" \
--disk pool="kvm_pool",size="100" \
--network network="$network" \
--graphics vnc,password="lab",listen="127.0.0.1",port="$vnc_port"

rm "$tmp_ks"
