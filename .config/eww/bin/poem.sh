#!/bin/sh

author="$(eww get poem-author)"
title="$(eww get poem-title)"

curl -s \
    --variable title="$title" \
    --variable author="$author" \
--expand-url "https://poetrydb.org/author,title,random/{{author:url}};{{title:url}};1" |
    jq '.[0]' -c
