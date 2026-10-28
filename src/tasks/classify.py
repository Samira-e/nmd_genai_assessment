"""Document classification task logic using Bedrock LLM."""

import json
import logging
import os

from common.aws import get_bedrock_client

logger = logging.getLogger(__name__)

CLASSIFY_MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "us.anthropic.claude-haiku-5-5")


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
