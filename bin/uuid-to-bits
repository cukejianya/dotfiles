#!/usr/bin/env bash

hex=$(echo "$1" | tr -d '-' | tr  '[:lower:]' '[:upper:]')

most_split_uuid="${hex:0:16}"
least_split_uuid="${hex:16:16}"

most_sig_bits=$(echo "ibase=16; $most_split_uuid" | bc)
least_sig_bits=$(echo "ibase=16; $least_split_uuid" | bc)

echo "{\"mostSigBits\": \"$most_sig_bits\",\"leastSigBits\": \"$least_sig_bits\"}" | jq
