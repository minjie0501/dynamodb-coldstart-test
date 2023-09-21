#!/bin/bash
usage() {
    echo "Usage: $0 <role-arn> <session-name> <cmd ...>"
    exit 1
}

[ $# -gt 2 ] || usage
ROLE_ARN=$1
SESSION_NAME=$2
shift 2

CREDS=$(
    aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name "$SESSION_NAME" \
    --output text --query 'Credentials.[AccessKeyId, SecretAccessKey, SessionToken]'
)

export AWS_ACCESS_KEY_ID=$(echo $CREDS | cut -d ' ' -f 1)
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | cut -d ' ' -f 2)
export AWS_SESSION_TOKEN=$(echo $CREDS | cut -d ' ' -f 3)

"$@"
