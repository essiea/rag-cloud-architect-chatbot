import json
import logging
from .rag import answer_question

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.debug("Event: %s", json.dumps(event))

    body = {}
    if "body" in event and event["body"]:
        try:
            body = json.loads(event["body"])
        except json.JSONDecodeError:
            pass

    question = body.get("question") or (event.get("queryStringParameters") or {}).get("q")
    if not question:
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": "Missing 'question' or 'q' parameter"}),
        }

    try:
        answer = answer_question(question)
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"answer": answer}),
        }
    except Exception as exc:
        logger.exception("Error answering question: %s", exc)
        return {
            "statusCode": 500",
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": str(exc)}),
        }
