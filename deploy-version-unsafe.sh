#!/bin/sh
set -e

# WARNING!!! ############################
# this is an example of UNSAFE deployment
# because we don't do "--dry-run" first
# but apply all manifests directly;
# so the overall operation is non-atomic
# i.e. some manifests may fail to apply
# while the others succeed, resulting in
# unpredictable behaviors

kubectl apply -f deploy-version.yml && \
echo "all good but something might fail!"
