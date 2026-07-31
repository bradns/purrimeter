import json
import os
from datetime import datetime, timezone

import boto3

s3_client = boto3.client("s3")
BUCKET = os.environ["DATA_BUCKET"]


def lambda_handler(event, context):
    now = datetime.now(timezone.utc)
    key = f"test/hello-{now:%Y%m%d-%H%M%S}.txt"
    body = f"Hello run at {now.isoformat()}"

    s3_client.put_object(
        Bucket=BUCKET,
        Key=key,
        Body=body,
        ContentType="text/plain",
    )

    return {"statusCode": 200, "written": key}
