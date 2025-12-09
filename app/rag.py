import math
from typing import List
import boto3
import json

from .embedding import generate_embedding
from .config import TABLE_NAME, LLM_MODEL_ID, MAX_CHUNKS

_dynamo = boto3.resource("dynamodb").Table(TABLE_NAME)
_bedrock = boto3.client("bedrock-runtime")


def cosine_similarity(a: List[float], b: List[float]) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    norm_a = math.sqrt(sum(x * x for x in a))
    norm_b = math.sqrt(sum(x * x for x in b))
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return dot / (norm_a * norm_b)


def retrieve_context(question: str) -> str:
    q_embed = generate_embedding(question)

    resp = _dynamo.scan()
    items = resp.get("Items", [])
    if not items:
        return ""

    scored = []
    for item in items:
        emb = item.get("embedding")
        if isinstance(emb, str):
            emb = json.loads(emb)
        sim = cosine_similarity(q_embed, emb)
        scored.append((sim, item))

    scored.sort(key=lambda x: x[0], reverse=True)
    top_items = [i for _, i in scored[:MAX_CHUNKS]]

    context_blocks = [i["chunk_text"] for i in top_items]
    return "\n\n---\n\n".join(context_blocks)


def answer_question(question: str) -> str:
    context = retrieve_context(question)

    system_prompt = (
        "You are an AWS cloud architect assistant. You will answer questions "
        "ONLY using the provided context. If you don't know, say you don't know."
    )

    user_prompt = f"Context:\n{context}\n\nQuestion: {question}"

    body = {
        "messages": [
            {"role": "system", "content": [{"type": "text", "text": system_prompt}]},
            {"role": "user", "content": [{"type": "text", "text": user_prompt}]},
        ],
        "max_tokens": 400,
        "temperature": 0.2,
    }

    resp = _bedrock.invoke_model(
        modelId=LLM_MODEL_ID,
        body=json.dumps(body),
        contentType="application/json",
        accept="application/json",
    )

    payload = json.loads(resp["body"].read())
    content = payload["output"]["message"]["content"]
    text_parts = [c["text"] for c in content if c["type"] == "text"]
    return "\n".join(text_parts)
