import os

EMBED_MODEL_ID = os.getenv("EMBED_MODEL_ID", "amazon.titan-embed-text-v1")
LLM_MODEL_ID   = os.getenv("LLM_MODEL_ID", "anthropic.claude-3-sonnet-20240229-v1:0")
TABLE_NAME     = os.getenv("TABLE_NAME")
DOC_BUCKET     = os.getenv("DOC_BUCKET")
MAX_CHUNKS     = int(os.getenv("MAX_CHUNKS", "20"))
