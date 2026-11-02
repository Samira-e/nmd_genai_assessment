"""LLM-based field extraction task logic."""

import json
import logging
import os

from common.aws import get_bedrock_client

logger = logging.getLogger(__name__)
# 1. Build a prompt that asks the LLM to extract fields based on document_type
EXTRACT_MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "us.anthropic.claude-haiku-5-5")
# Expected fields by document type:
#   cybersecurity_advisory: severity, cve_ids, affected_products, mitigation_steps
#   drug_approval: drug_name, indication, approval_date, applicant, dosage
#   airworthiness_directive: ad_number, affected_aircraft, compliance_deadline, required_action
#   financial_filing: company_name, filing_date, event_type, revenue, net_income
#
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
    document_type = event.get("document_type", "unknown")
    logger.info("Extracting fields from: %s (type: %s)", document_id, document_type)

    # TODO: Implement Bedrock field extraction

    # 2. Call Bedrock InvokeModel with the prompt
    # 3. Parse the JSON response to extract structured fields

    # Return format: {"extracted_fields": {...}, "extraction_confidence": 0.0-1.0}

    raise NotImplementedError(
        "extract_fields() is not implemented. Call Bedrock to extract structured fields based on the document type."
    )
