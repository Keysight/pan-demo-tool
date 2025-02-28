#!/bin/bash
. /pan-demo/py3/bin/activate
cp -r /temp/.terraform /pan-demo/terraform/
cp /temp/.terraform.lock.hcl /pan-demo/terraform/
python3 pan_demo_setup.py "$@"
