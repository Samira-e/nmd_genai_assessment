"""Document classification task logic using Bedrock LLM."""

import json
import logging
import os

from common.aws import get_bedrock_client

logger = logging.getLogger(__name__)

CLASSIFY_MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "us.anthropic.claude-haiku-5-5")

DOCUMENT_TYPES = {
    "cybersecurity_advisory": "A security advisory about vulnerabilities, exploits or patches.",
    "drug_approval": "A regulatory notice approving or reviewing a drug or medical product.",
    "airworthiness_directive": "An aviation authority directive requiring inspection or repair of aircraft.",
    "financial_filing": "A company financial report or regulatory filing (e.g. 10-K, 10-Q, earnings).",
    "unknown": "None of the above, or not enough information to decide.",
}
SYSTEM_PROMPT = (
    "You are a document classifier. Classify the document into exactly one of the allowed types. "
    "Reply with a single JSON object only, no other text."
)


def build_prompt(title: str, content: str) -> str:
    """Build user prompt: allowed types, expected JSON shape, and the document."""
    types_list = "\n".join(f"- {name}: {desc}" for name, desc in DOCUMENT_TYPES.items())
    return (
        f"Allowed document types:\n{types_list}\n\n"
        "Return JSON in exactly this shape:\n"
        '{"document_type": "<one of the allowed types>", "confidence": <number between 0 and 1>}\n\n'
        f"<document>\nTitle: {title}\n\n{content}\n</document>"
    )


def parse_json_reply(text: str) -> dict:
    """Extract the JSON object from the model reply"""
    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end <= start:
        raise ValueError(f"No JSON object found in model reply: {text[:200]!r}")
    return json.loads(text[start : end + 1])


def classify_document(event: dict) -> dict:
    """Classify a document using Bedrock LLM.

    The candidate must implement the Bedrock API call to classify the document
    into one of these types: cybersecurity_advisory, drug_approval,
    airworthiness_directive, financial_filing, or unknown.

    Args:
        event: Input with document content from preprocessing.

    Returns:
        Classification result with document_type and confidence.
    """
    document_id = event["document_id"]
    content = event.get("content", "")
    logger.info("Classifying document: %s", document_id)

    # TODO: Implement Bedrock classification
    # 1. Build a prompt that asks the LLM to classify the document
    # 2. Call Bedrock InvokeModel with the prompt
    # 3. Parse the response to extract document_type and confidence
    #
    # Expected document types: cybersecurity_advisory, drug_approval,
    #   airworthiness_directive, financial_filing, unknown
    #
    # Hint: Use the Messages API format for Claude models:
    #   bedrock.invoke_model(
    #       modelId=CLASSIFY_MODEL_ID,
    #       body=json.dumps({
    #           "anthropic_version": "bedrock-2023-05-31",
    #           "max_tokens": 256,
    #           "messages": [{"role": "user", "content": prompt}]
    #       })
    #   )

    raise NotImplementedError(
        "classify_document() is not implemented. "
        "Call Bedrock to classify the document and return document_type + confidence."
    )
