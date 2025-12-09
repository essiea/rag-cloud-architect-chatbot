import json
import boto3
from .config import EMBED_MODEL_ID

_bedrock = boto3.client("bedrock-runtime")

def generate_embedding(text: str) -> list[float]:
    body = {"inputText": text}
    resp = _bedrock.invoke_model(
        modelId=EMBED_MODEL_ID,
        body=json.dumps(body),
        contentType="application/json",
        accept="application/json",
    )
    payload = json.loads(resp["body"].read())
    return payload["embedding"]
