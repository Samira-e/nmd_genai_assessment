# Sample Documents

These JSON files represent documents for testing the processing pipeline. Upload them to your S3 bucket's `uploads/` prefix to trigger the pipeline.

Each document has:
- `title` — document title
- `content` — full text content for LLM processing
- `source` — originating organization
- `date` — publication date

## Upload command

```bash
for f in data/*.json; do
  aws s3 cp "$f" "s3://nmd-genai-${CANDIDATE_NAME}-documents/uploads/$(basename $f)" \
    --profile nmd-codescreen
done
```
