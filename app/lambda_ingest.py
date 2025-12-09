import json
import logging
import boto3

from .embedding import generate_embedding
from .config import TABLE_NAME, DOC_BUCKET

logger = logging.getLogger()
logger.setLevel(logging.INFO)

_s3 = boto3.client("s3")
_dynamo = boto3.resource("dynamodb").Table(TABLE_NAME)


def chunk_text(text: str, max_chars: int = 1000):
    for i in range(0, len(text), max_chars):
        yield text[i : i + max_chars]


def lambda_handler(event, context):
    """
    Triggered by S3 ObjectCreated. Reads file, chunks, embeds, stores in DynamoDB.
    """
    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]

        if bucket != DOC_BUCKET:
            logger.warning("Ignoring object from bucket %s", bucket)
            continue

        obj = _s3.get_object(Bucket=bucket, Key=key)
        body = obj["Body"].read().decode("utf-8")

        for idx, chunk in enumerate(chunk_text(body)):
            embedding = generate_embedding(chunk)
            item = {
                "doc_id": key,
                "chunk_id": str(idx),
                "chunk_text": chunk,
                "embedding": json.dumps(embedding),
            }
            _dynamo.put_item(Item=item)
            logger.info("Indexed %s chunk %s", key, idx)

    return {"statusCode": 200, "body": "Ingest complete"}
