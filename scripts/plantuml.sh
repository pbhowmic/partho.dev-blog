#!/usr/bin/env bash
SCRIPT_DIR=$(dirname $(readlink -f "$0"))
NAMESPACE=plantuml-ns

kubectl apply -f "${SCRIPT_DIR}"/plantuml.yaml -n ${NAMESPACE}
kubectl port-forward service/puml -n ${NAMESPACE} 9000:8080
