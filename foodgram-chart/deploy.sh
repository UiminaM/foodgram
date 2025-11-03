#!/bin/bash
set -e
set -a

source .env

set +a

POSTGRES_USER=$(vals get 'ref+vault://secret/foodgram/backend#POSTGRES_USER')
POSTGRES_DB=$(vals get 'ref+vault://secret/foodgram/backend#POSTGRES_DB')
POSTGRES_PASSWORD=$(vals get 'ref+vault://secret/foodgram/backend#POSTGRES_PASSWORD')

helm upgrade --install foodgram-helm ./foodgram-helm \
  -n foodgram \
  -f values.yaml \
  --set postgresql.auth.username="$POSTGRES_USER" \
  --set postgresql.auth.database="$POSTGRES_DB" \
  --set postgresql.auth.postgresPassword="$POSTGRES_PASSWORD"
