#!/bin/sh
set -e

# in the lines below, everywhere where `--dry-run` appears, it means we attempt
# to validate the k8s config manifest(s) without actually applying, which allows
# us to apply in an atomic manner: either everything succeeds or none at all

# extract, validate, and apply the Namespace manifest first
# so that --dry-run=server call may deterministically succeed later
# (most helpful for 1st-time installation)
NAMESPACE_MANIFEST=$(yq 'select(.kind=="Namespace")' deploy.yml) && \
echo "validate, then apply Namespace..." && \
echo "$NAMESPACE_MANIFEST" | kubectl apply --dry-run=client -f - && \
echo "$NAMESPACE_MANIFEST" | kubectl apply --dry-run=server -f - && \
echo "$NAMESPACE_MANIFEST" | kubectl apply -f - && \

# validate all manifests both on kubectl (client) & k8s (server) sides
# and only carry on if everything is well validated
echo "validate, then apply all manifests..." && \
kubectl apply --dry-run=client -f deploy.yml && \
kubectl apply --dry-run=server -f deploy.yml && \
kubectl apply -f deploy.yml && \

# success output (e.g. Slack notification)
echo "all good"
