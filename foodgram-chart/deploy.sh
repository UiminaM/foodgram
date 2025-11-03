#!/bin/bash
set -e
set -a
source .env
set +a

helm upgrade --install foodgram-helm ./foodgram-helm \
  -n foodgram \
  -f values.yaml 
