#!/bin/bash

#Requires jq to be installed

JWT=$(./make-jwt.sh)

ACCESS_TOKEN= curl -s \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: Bearer $JWT" \
  "https://api.github.com/app/installations/$APP_INSTALLATION/access_tokens" | jq -r '.token'

echo -n $ACCESS_TOKEN
