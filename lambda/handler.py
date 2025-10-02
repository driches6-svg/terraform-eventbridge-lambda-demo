import json
import os


def lambda_handler(event, context):
    print("EVENT:", json.dumps(event))
    detail = event.get("detail") or {}
    msg = {
        "received": True,
        "powered_by": os.environ.get("POWERED_BY", "unknown"),
        "detail": detail,
    }
    return {"statusCode": 200, "body": json.dumps(msg)}
