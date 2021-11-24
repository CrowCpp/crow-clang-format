#!/bin/bash

TIME_NOW=$(date +%s)
TIME_TM=$(($TIME_NOW + 600)) #TM = Ten Minutes

JWT_HEADER='{"alg":"RS256","typ":"JWT"}'
JWT_PAYLOAD="{\"iat\":$TIME_NOW,\"exp\":$TIME_TM,\"iss\":$APP_ID}"

JWT_ENC_HEADER=$(echo -n $JWT_HEADER | base64 | tr '/+' '_-')
JWT_ENC_PAYLOAD=$(echo -n $JWT_PAYLOAD | base64 | tr '/+' '_-')

JWT_DATA="$JWT_ENC_HEADER.$JWT_ENC_PAYLOAD"
JWT_SIG=$(echo -n $JWT_DATA | openssl sha256 -sign "pk.pem" | base64 | tr '/+' '_-' | tr -d '\n')

echo -n "$JWT_DATA.$JWT_SIG"
