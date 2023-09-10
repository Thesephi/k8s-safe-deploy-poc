#!/bin/sh
set -e

# NOTE ##################################################
# this is how we deploy k8s in an atomic and safe manner
# because we do "--dry-run" first, and so if anything may
# go wrong during deployment, it will exit during dry-run
# and preventing the issue(s) from being actually applied

kubectl apply --dry-run=client -f deploy-version.yml && \
kubectl apply --dry-run=server -f deploy-version.yml && \
kubectl apply -f deploy-version.yml && \
echo "all good"
