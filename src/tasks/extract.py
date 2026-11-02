"""LLM-based field extraction task logic."""

import json
import logging
import os

from common.parsing import parse_json_reply
from common.aws import get_bedrock_client

logger = logging.getLogger(__name__)

EXTRACT_MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "us.anthropic.claude-haiku-5-5")

FIELDS_BY_TYPE = {
    "cybersecurity_advisory": ["severity", "cve_ids", "affected_products", "mitigation_steps"],
    "drug_approval": ["drug_name", "indication", "approval_date", "applicant", "dosage"],
    "airworthiness_directive": ["ad_number", "affected_aircraft", "compliance_deadline", "required_action"],
    "financial_filing": ["company_name", "filing_date", "event_type", "revenue", "net_income"],
}

SYSTEM_PROMPT = (
    "You extract structured fields from documents. "
    "Reply with a single JSON object only, no other text. Use null for any field not found."
)


def build_prompt(document_type: str, fields: list[str], title: str, content: str) -> str:
    """Build user prompt: fields to extract, expected JSON shape, and the document"""
    fields_json = ", ".join(f'"{name}": ...' for name in fields)
    return (
        f"Document type: {document_type}\n"
        f"Extract these fields: {', '.join(fields)}\n\n"
        "Return JSON in exactly this shape:\n"
        f'{{"extracted_fields": {{{fields_json}}}, "confidence": <number between 0 and 1>}}\n\n'
        f"<document>\nTitle: {title}\n\n{content}\n</document>"
    )


def extract_fields(event: dict) -> dict:
    """Extract structured fields from document content using Bedrock.

    The candidate must implement the Bedrock API call to extract key fields
    based on the document type. Different document types have different fields.

    Args:
        event: Input with document content and classification.

    Returns:
        Extracted fields as structured data.
    """
    document_id = event["document_id"]
    content = event.get("content", "")
    title = event.get("title", "")
    document_type = event.get("document_type", "unknown")
    logger.info("Extracting fields from: %s (type: %s)", document_id, document_type)
    fields = FIELDS_BY_TYPE.get(document_type)
    if not fields:
        # Unknown type: nothing to extract, so skip the Bedrock call
        return {"document_id": document_id, "extracted_fields": {}, "extraction_confidence": 0.0}

    bedrock = get_bedrock_client()
    response = bedrock.invoke_model(
        modelId=EXTRACT_MODEL_ID,
        body=json.dumps(
            {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 1024,
                "temperature": 0,
                "system": SYSTEM_PROMPT,
                "messages": [{"role": "user", "content": build_prompt(document_type, fields, title, content)}],
            }
        ),
    )
    reply = json.loads(response["body"].read())["content"][0]["text"]

    try:
        data = parse_json_reply(reply)
    except (ValueError, json.JSONDecodeError):
        logger.error("Can't parse extraction reply for %s", document_id)
        data = {}

    return {
        "document_id": document_id,
        "extracted_fields": data.get("extracted_fields", {}),
        "extraction_confidence": data.get("confidence", 0.0),
    }
