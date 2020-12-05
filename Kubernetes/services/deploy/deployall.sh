#!/bin/bash

# Execute on master
file_names=$(ls ./*.yaml)
for file in $file_names
do
  kubectl apply -f $file
done
