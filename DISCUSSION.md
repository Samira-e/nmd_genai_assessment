# Discussion Questions

Answer the **Shared Questions** section plus the **one track section** specified in your email (Solutions Architect OR Data Engineer). 

Aim for 2-4 sentences per answer unless otherwise noted. We value clarity and depth over length.

---

## Shared Questions (everyone answers)

### 1. Troubleshooting

If you could not complete the assessment or got stuck at any point, what went wrong and what did you try to troubleshoot?

**Your answer:**
* **First "terraform apply" failed:** the Lambdas could not be created because the Docker image was not in ECR yet. I built and pushed the image, then ran "apply" again.
* **"make format" removed imports I needed:** it runs "ruff check --fix", which deleted imports that looked unused because the functions were not written yet. I restored the files and formatted only the file I changed.
* **Extract did not get the document type:** the state machine sent only the Preprocess output to Extract, so every document became "unknown". I added "document_type" from the Classify result to the Extract input.
* **"make update-lambdas" did nothing:** it looks for Terraform outputs that do not exist and hides the error. I updated the Lambdas with "aws lambda update-function-code" instead.
* **First pipeline run failed at Classify:** Bedrock returned "temperature is deprecated for this model". I found it in the Step Functions execution history and removed "temperature".
* **My IAM user could not list Bedrock models:** not a blocker, because the Lambda role calls Bedrock, not my user.
### 2. Proof of Completion

Paste the S3 URI to one of your result files (e.g., "s3://nmd-genai-<your-name>-documents/results/<document-id>.json`).

**Your answer:**

### 3. Prompt Engineering

How would you improve the classification prompt to handle ambiguous documents that could match multiple types? What techniques would you use to ensure consistent JSON output from the LLM?

**Your answer:**

### 4. Error Handling

How would you handle Bedrock throttling (429 errors) in a production pipeline? What retry strategy would you implement, and how would it interact with Step Functions' built-in error handling?

**Your answer:**

### 5. Enterprise Readiness

Assume a CTO prototyped this pipeline over a weekend using AI code assistants. It works for demos but needs to go to production for a Fortune 500 client.

Write a prioritized list of changes organized by:
1. **Must-fix before production** — what would block a launch?
2. **Should-fix in the first sprint** — what's important but not blocking?
3. **Nice-to-have for long-term maintainability** — what would you plan for later?

Consider security, error handling, observability, testing, CI/CD, and infrastructure hardening.

**Your answer:**

### 4. Terraform — Adding a Pipeline Step

A new "validate" Lambda needs to be added to the pipeline between Extract and Aggregate. It will validate the extracted fields against a schema before writing results. List every file you'd need to change and what you'd add to each.

**Your answer:**
`
---

## Solutions Architect Track

*Answer this section only if your email specified Solutions Architect.*

### SA-1. Model Selection & Cost Architecture

This assessment restricts you to Claude Haiku. In a production system processing thousands of documents daily, how would you decide which model to use for classification vs. extraction? What factors (cost, latency, accuracy, token limits) would drive that decision? How would you implement cost attribution per client?

**Your answer:**

### SA-2. Security Review

A client wants to process PHI (protected health information) through this pipeline. What changes are needed to meet HIPAA requirements? Think about data at rest, data in transit, Bedrock's data handling policies, IAM scoping, and logging.

**Your answer:**

### SA-3. Multi-Tenancy

A client wants to offer this pipeline as a SaaS feature where each of their customers uploads documents. How would you isolate tenants? Consider S3 partitioning, IAM scoping, cost attribution, and noisy-neighbor protection.

**Your answer:**

### SA-4. Production Readiness Briefing

List the key points you'd convey to a client's VP of Engineering who approved this project but hasn't seen the implementation. What changes are needed before going to production, and how would you prioritize them?

**Your answer:**

---

## Data Engineer Track

*Answer this section only if your email specified Data Engineer.*

### DE-1. Data Quality & Validation

The pipeline trusts the LLM's JSON output without validation. How would you validate extracted fields against a schema? How would you handle extraction failures — retry, dead-letter queue, or flag for human review? What's your strategy?

**Your answer:**

### DE-2. Pipeline at Scale

This processes one document per Step Functions execution. Design a batch pipeline that handles 100,000 documents per day. What changes to the Step Functions architecture? Where would you parallelize, and where are the bottlenecks?

**Your answer:**

### DE-3. Observability & Data Lineage

How would you monitor this pipeline in production? What metrics, alerts, and dashboards would you build? A downstream team also needs to know which model version and prompt version produced each extraction. How would you track that lineage?

**Your answer:**
**Monitoring**
The code today: no alarms or dashboard. Step Functions logs only errors.

What to change:

Everything is on one CloudWatch dashboard, and every log line carries the document_id, so you can trace one document through all four steps.

* Pipeline: runs started, status (succeeded, failed), time per document → Alert when the failure rate goes above a set level.
* Lambda: errors, throttles, duration → Alert when errors or throttles keep happening.
* Bedrock: calls, throttles, response time, tokens used (cost per document) → Alert when throttling continues or cost per document jumps.
* Data quality: average confidence, how often fields come back empty, “needs review” count → Alert when confidence drops suddenly (often a sign the prompt or input changed).

**Lineage for the downstream team**

The code today: the result file has no record of which model or prompt made it.

**What to change: add to every result:**

* model_Id, prompt_version, code_version(image tag),stepfuction_execution_id, source_file_s3_version_id, processing_time 

Result: results can be queried in Athena.


### DE-4. Caching & Deduplication

If the same document is uploaded twice, the pipeline currently processes it again at full cost. How would you implement caching or deduplication? Consider where in the pipeline to check, what to use as a cache key, and the tradeoffs of different storage options (DynamoDB, S3 metadata, Elasticache).

**Your answer:**
**Where:** in Preprocess, right after reading the file and before any Bedrock call, so a duplicate has no cost.

**key**: Document content hash + model ID + prompt version (makes the pipeline idempotent: the same document is processed only once).

**store:** DynamoDB, with conditional write (save if this key doesn't exist). It's atomic, so two identical uploads at the same moment can't both pass. 

  **DynamoDB:**

Pros: Atomic check, serverless, can expire old keys automatically (TTL)
Cons: One more table to manage

  **S3 metadata:**

Pros: Nothing new to run
Cons: No atomic check, so two uploads at once can both slip (needs a lookup per file)

  **ElastiCache:**

Pros: Very fast
Cons: Not durable, needs a VPC and a running cluster, overkill for this volume

