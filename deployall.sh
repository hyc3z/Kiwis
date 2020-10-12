#!/bin/bash

# Execute on master
kubectl apply -f  deployment/namespace.yaml
kubectl apply -f  deployment/clusterrole.yaml
kubectl apply -f  deployment/clusterrolebinding.yaml
kubectl apply -f  deployment/serviceaccount.yaml
kubectl apply -f  deployment/mysql.yaml
kubectl apply -f  deployment/nvidia.yaml
kubectl apply -f  deployment/redis.yaml
kubectl apply -f  deployment/scheduler.yaml
kubectl apply -f  deployment/tagcontrol.yaml
kubectl apply -f  deployment/backend.yaml
kubectl apply -f  deployment/frontend.yaml