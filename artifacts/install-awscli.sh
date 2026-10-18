#!/bin/bash

set -e

if command -v aws >/dev/null 2>&1; then
    echo "AWS CLI already installed"
    exit 0
fi

gcloud storage cp gs://multicloud-lab-test/awscliv2.zip /tmp/awscliv2.zip && \
  python3 -m zipfile -e /tmp/awscliv2.zip /tmp/ && \
  chmod +x /tmp/aws/install /tmp/aws/dist/aws && \
  sudo /tmp/aws/install --update && aws --version && \
  rm -rf /tmp/awscliv2.zip /tmp/aws
