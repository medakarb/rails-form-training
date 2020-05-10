#!/usr/bin/env bash

set -e

PARAMETER_STORE_PREFIX=${PARAMETER_STORE_PREFIX:-}

if [ -n "$PARAMETER_STORE_PREFIX" ]; then
    export DATABASE_USERNAME=$(aws ssm get-parameters --name /rails-form-training/prd/db_user --with-decryption --query "Parameters[0].Value" --region ap-northeast-1 --output text)
    export DATABASE_PASSWORD=$(aws ssm get-parameters --name /rails-form-training/prd/db_password --with-decryption --query "Parameters[0].Value" --region ap-northeast-1 --output text)
    export DATABASE_HOSTNAME=$(aws ssm get-parameters --name /rails-form-training/prd/db_host --with-decryption --query "Parameters[0].Value" --region ap-northeast-1 --output text)
    export SECRET_KEY_BASE=$(aws ssm get-parameters --name /rails-form-training/prd/SECRET_KEY_BASE --with-decryption --query "Parameters[0].Value" --region ap-northeast-1 --output text)
fi

export DATABASE_USERNAME=$(aws ssm get-parameters --name /rails-form-training/prd/db_user --with-decryption --query "Parameters[0].Value" --region ap-northeast-1 --output text)
export DATABASE_PASSWORD=$(aws ssm get-parameters --name /rails-form-training/prd/db_password --with-decryption --query "Parameters[0].Value" --region ap-northeast-1 --output text)
export DATABASE_HOSTNAME=$(aws ssm get-parameters --name /rails-form-training/prd/db_host --with-decryption --query "Parameters[0].Value" --region ap-northeast-1 --output text)
export SECRET_KEY_BASE=$(aws ssm get-parameters --name /rails-form-training/prd/SECRET_KEY_BASE --with-decryption --query "Parameters[0].Value" --region ap-northeast-1 --output text)

exec "$@"