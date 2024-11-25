#!/bin/bash

# Define input and output files
input_file="input.txt"
mcc_mnc_file="parsed_mcc_mnc.txt"
inbound_file="parsed_inbound.txt"
target_inventory="target_inventory.ini"

# Clear previous output files if they exist
> "$mcc_mnc_file"
> "$inbound_file"
> "$target_inventory"

# Parse MCC-MNC pairs
echo "Parsing MCC-MNC pairs..."
awk '/MCC-MNC:/ {flag=1; next} /Inbound:/ {flag=0} flag {gsub(/\t/, ""); print}' "$input_file" | \
while read -r line; do
  if [[ "$line" =~ ([0-9]{3})-([0-9]{2}) ]]; then
    mcc="${BASH_REMATCH[1]}"
    mnc="${BASH_REMATCH[2]}"
    echo "mcc=$mcc,mnc=$mnc" >> "$mcc_mnc_file"
  fi
done

# Output parsed MCC-MNC pairs
echo "Parsed MCC-MNC pairs:"
cat "$mcc_mnc_file"

# Parse Inbound key-value pairs
echo "Parsing Inbound pairs..."
awk '/Inbound:/ {flag=1; next} /SERVERS:/ {flag=0} flag {gsub(/\t/, ""); print}' "$input_file" > "$inbound_file"

# Output parsed Inbound pairs
echo "Parsed Inbound pairs:"
cat "$inbound_file"

# Parse target servers and filter inventory
echo "Filtering target servers..."
echo "[all]" > "$target_inventory"
awk '/SERVERS:/ {flag=1; next} {if (flag) {gsub(/\t/, ""); print}}' "$input_file" | \
while read -r server; do
  grep "^$server " inventory.ini >> "$target_inventory"
done

# Output filtered inventory file
echo "Filtered inventory file:"
cat "$target_inventory"

# Validate inventory file
if [ ! -s "$target_inventory" ]; then
  echo "Error: No servers found in inventory.ini for the given input." >&2
  exit 1
fi

echo "Parsing complete."

