#!/bin/bash

# Perform the curl request and store the response
response=$(curl -s -X POST "http://multibags.1dt.com.br/api/v1/customer/login" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{ "password": "aA#123456789", "username": "otoniel.isidoro@gmail.com" }')

# Extract the token using jq
token=$(echo "$response" | jq -r '.token')

# Check if the token was extracted successfully
if [ -z "$token" ] || [ "$token" == "null" ]; then
  echo "Error: Token not found in response"
  exit 1
fi

# Print the JSON output with the token
json_output=$(jq -n --arg token "Bearer $token" '{"name": "Authorization", "value": $token, "in": "header", "duration": 600}')

echo "$json_output"
