#!/bin/sh

while read -r line; do
    echo "type $line"
done | dotool
