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

# Define product ID and customer ID
PRODUCT_ID=$1
CUSTOMER_ID=$2

if [ -z "$PRODUCT_ID" ] || [ "$PRODUCT_ID" == "null" ]; then
  echo "Please inform the product id as 1st arg. e.g.: ./reset.sh <product_id> <customer_id>"
  exit 1
fi

if [ -z "$CUSTOMER_ID" ] || [ "$CUSTOMER_ID" == "null" ]; then
  echo "Please inform the customer id as 2nd arg. e.g.: ./reset.sh <product_id> <customer_id>"
  exit 1
fi

# Get reviews for the product
response=$(curl -s -X GET "http://multibags.1dt.com.br/api/v1/products/$PRODUCT_ID/reviews" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $token")

# Find the review ID for the given customer
review_id=$(echo "$response" | jq -r --arg CUSTOMER_ID "$CUSTOMER_ID" '.[] | select(.customer.id == ($CUSTOMER_ID | tonumber)) | .id')

if [ -n "$review_id" ] && [ "$review_id" != "null" ]; then
  echo "Deleting review ID: $review_id for product ID: $PRODUCT_ID and customer ID: $CUSTOMER_ID."

  delete_url="http://multibags.1dt.com.br/api/v1/auth/products/$PRODUCT_ID/reviews/$review_id"

  curl -s -X DELETE "$delete_url" \
    -H "accept: application/json" \
    -H "Authorization: Bearer $token"

  echo "Deleted review ID: $review_id."
else
  echo "No review found for product ID: $PRODUCT_ID and customer ID: $CUSTOMER_ID. No action taken."
fi
