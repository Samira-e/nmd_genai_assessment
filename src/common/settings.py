"""Application settings via pydantic-settings."""

from __future__ import annotations

import logging
from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    """Configuration loaded from environment variables."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    aws_profile: str | None = Field(default=None)
    aws_region: str = Field(default="us-west-2")
    s3_bucket_name: str | None = Field(default=None)
    bedrock_model_id: str = Field(default="us.anthropic.claude-haiku-5-5")
    log_level: str = Field(default="INFO")


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Get cached application settings."""
    return Settings()
