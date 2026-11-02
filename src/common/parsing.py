"""Shared helper for parsing model replies"""

import json


def parse_json_reply(text: str) -> dict:
    """Extract the JSON object from the model reply"""
    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end <= start:
        raise ValueError(f"No JSON object found in model reply: {text[:200]!r}")
    return json.loads(text[start : end + 1])
