{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:Query"
            ],
            "Resource": "arn:aws:dynamodb:*:*:table/1Config"
        },
        {
            "Effect": "Allow",
            "Action": "kms:Decrypt",
            "Resource": "${KW_CONFIG_KEY}"
        }
    ]
}