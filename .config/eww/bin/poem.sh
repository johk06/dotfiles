#!/bin/sh

author="shakespeare"
title="sonnet"

curl -s \
    --variable title="$title" \
    --variable author="$author" \
--expand-url "https://poetrydb.org/author,title,random/{{author:url}};{{title:url}};1" |
    jq '.[0]' -c
