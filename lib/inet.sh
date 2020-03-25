#!/bin/sh

#
# Takes an IPv4 network in CIDR notation as input. Sets the following
# variables:
#
# prefix      Number of bits in the network prefix
# netmask     Netmask in decimal format
# net_id      Network ID
# first_ip    First IP address in the network
# last_ip     Last IP address in the network
# broadcast   Broadcast address
#

#
# Helper functions
#

convert_decimal_to_binary_ip() {
  od1=$(echo "$1" | cut -d '.' -f 1 -)
  od2=$(echo "$1" | cut -d '.' -f 2 -)
  od3=$(echo "$1" | cut -d '.' -f 3 -)
  od4=$(echo "$1" | cut -d '.' -f 4 -)
  ob1=$(echo "obase=2;ibase=10;$od1" | bc | awk '{printf "%08d", $0}')
  ob2=$(echo "obase=2;ibase=10;$od2" | bc | awk '{printf "%08d", $0}')
  ob3=$(echo "obase=2;ibase=10;$od3" | bc | awk '{printf "%08d", $0}')
  ob4=$(echo "obase=2;ibase=10;$od4" | bc | awk '{printf "%08d", $0}')
  binary_ip="${ob1}${ob2}${ob3}${ob4}"
}

convert_binary_to_decimal_ip() {
  ob1=$(echo "$1" | cut -c 1-8 -)
  ob2=$(echo "$1" | cut -c 9-16 -)
  ob3=$(echo "$1" | cut -c 17-24 -)
  ob4=$(echo "$1" | cut -c 25-32 -)
  od1=$(echo "obase=10;ibase=2;$ob1" | bc)
  od2=$(echo "obase=10;ibase=2;$ob2" | bc)
  od3=$(echo "obase=10;ibase=2;$ob3" | bc)
  od4=$(echo "obase=10;ibase=2;$ob4" | bc)
  decimal_ip="${od1}.${od2}.${od3}.${od4}"
}

#
# Main functions
#

set_prefix() {
  prefix=$(echo "$1" | cut -d '/' -f 2 -)
  if [ "$prefix" -lt 1 -o "$prefix" -gt 31 ]; then
    printf "Prefix should be greater than 0 and less than 32.\\n"
    exit 1
  fi
}

set_netmask() {
  mask_bits=""
  i="0"
  while true; do
    if [ "$i" -lt "$1" ]; then
      mask_bits="${mask_bits}1"
      i=$(expr "$i" + 1)
      continue
    else
      break
    fi
  done
  binary_netmask=$(printf "%-32s" "$mask_bits" | tr ' ' '0')
  convert_binary_to_decimal_ip "$binary_netmask"
  netmask="$decimal_ip"
}

set_net_id() {
  address=$(echo "$1" | cut -d '/' -f 1 -)
  convert_decimal_to_binary_ip "$address"
  decimal_net_id=$((2#$binary_ip & 2#$2))
  binary_net_id=$(echo "obase=2;ibase=10;$decimal_net_id" | bc | awk '{printf "%032s", $0}')
  convert_binary_to_decimal_ip "$binary_net_id"
  net_id="$decimal_ip"
}

set_first_ip() {
  if [ "$2" -eq 31 ]; then
    increment=0
  else
    increment=1
  fi
  decimal_first_ip=$((2#$1 + $increment))
  binary_first_ip=$(echo "obase=2;ibase=10;$decimal_first_ip" | bc | awk '{printf "%032s", $0}')
  convert_binary_to_decimal_ip "$binary_first_ip"
  first_ip="$decimal_ip"
}

set_broadcast() {
  binary_netmask_inverted=$(echo "$2" | tr 10 01)
  decimal_broadcast=$((2#$1 | 2#$binary_netmask_inverted))
  binary_broadcast=$(echo "obase=2;ibase=10;$decimal_broadcast" | bc | awk '{printf "%032s", $0}')
  convert_binary_to_decimal_ip "$binary_broadcast"
  broadcast="$decimal_ip"
}

set_last_ip() {
  if [ "$2" -eq 31 ]; then
    decrement=0
  else
    decrement=1
  fi
  decimal_last_ip=$((2#$1 - $decrement))
  binary_last_ip=$(echo "obase=2;ibase=10;$decimal_last_ip" | bc | awk '{printf "%032s", $0}')
  convert_binary_to_decimal_ip "$binary_last_ip"
  last_ip="$decimal_ip"
}

set_prefix "$1"
set_netmask "$prefix"
set_net_id "$1" "$binary_netmask"
set_first_ip "$binary_net_id" "$prefix"
set_broadcast "$binary_net_id" "$binary_netmask"
set_last_ip "$binary_broadcast" "$prefix"
