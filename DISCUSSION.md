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
s3://nmd-genai-samira-esfandyari-documents/results/cybersecurity-advisory.json

* Classified as "cybersecurity_advisory" (0.98 confidence).
* Extracted severity, CVE IDs, affected products and mitigation steps (0.95 confidence).
### 3. Prompt Engineering

How would you improve the classification prompt to handle ambiguous documents that could match multiple types? What techniques would you use to ensure consistent JSON output from the LLM?

**Your answer:**
**Ambiguous documents:**
* Give a one-line definition and a short example for each type in the prompt.
* Ask the model for a second-choice type and the evidence it used.
* Send low-confidence results (for example below 0.8) to human review instead of guessing.

**Consistent JSON:**
* In the prompt: the exact JSON shape and "reply with JSON only".
* In the code: take the JSON between the first "{" and last "}", accept only the allowed types (otherwise "unknown"), and keep confidence between 0 and 1. This is what my "parse_json_reply" and validation do.
* Stronger option: Bedrock tool use with a JSON schema, which forces structured output.
### 4. Error Handling

How would you handle Bedrock throttling (429 errors) in a production pipeline? What retry strategy would you implement, and how would it interact with Step Functions' built-in error handling?

**Your answer:**
The code today:

* Layer 1 (inside the Lambda): the Bedrock client in “aws.py” tries up to 3 times in “adaptive” mode 
* Layer 2 (Step Functions): the state machine has no Retry or Catch →one throttle fails the whole document.

What to change:

* Retry on Classify and Extract: wait longer each time (2s, 4s, 8s…, up to 5 retries) 

                  with a random extra wait so all documents don’t retry at the same moment (exponential backoff and jitter).

* Catch: anything that still fails goes to a failure path (dead letter queue with an alert).

    "Classify":{  

      ...  

      "Retry": [ ... ],

      "Catch": [ ... ],

      "Next": "Extract" 

    }

The problem is 2 layers multiplied:

* 3 tries per run × 6 runs (first run + 5 retries) = can be 18 Bedrock calls for one document.
* Fix at high volume: keep the client’s retries small

              Limit how many documents run at once, below the Bedrock quota.



### 5. Enterprise Readiness

Assume a CTO prototyped this pipeline over a weekend using AI code assistants. It works for demos but needs to go to production for a Fortune 500 client.

Write a prioritized list of changes organized by:
1. **Must-fix before production** — what would block a launch?
2. **Should-fix in the first sprint** — what's important but not blocking?
3. **Nice-to-have for long-term maintainability** — what would you plan for later?

Consider security, error handling, observability, testing, CI/CD, and infrastructure hardening.

**Your answer:**
1. Must-fix before production: what would block a launch?

**Security issue:**

* Bedrock permission: Lambda can call any model in any region (should limit to one model). “modules/lambda/main.tf” 
* S3 bucket Encryption: uses only AWS default encryption, not the client own key(KMS) → “modules/s3/main.tf”
* Container image scanning:  Images are never scanned for vulnerabilities → “modules/ecr/main.tf”

**Error handling issue:**

* No retries or failure handling: one throttle or a bad reply fails the whole document, and nobody is alerted → “terraform/modules/step-functions/state_machine.asl.json”

**Data quality issue:**

* The model’s output is saved without a check: clients receive wrong or random values as if they were correct → “src/tasks/aggregate.py”

**Deployment issue:**

* Every image is tagged “latest", and tags can be overwritten: you can’t tell which code is running, or roll back a bad release. “terraform/live/candidate/main.tf”
* "make update-lambdas” does nothing: it looks for Terraform outputs that don’t exist, prints “Lambda functions updated,” but no Lambda gets the new code. “Makefile”, “terraform/live/candidate/outputs.tf”

**Infrastructure issue:**

*  One command can delete every image: destroying the repository deletes all images, no way back. ”modules/ecr/main.tf”

2. Should-fix in the first sprint: important but not blocking

* Testing and CI/CD: real tests with a fake Bedrock client instead of placeholders

                                         GitHub Actions runs tests and terraform plan on every pull request, with prod approval and OIDC (no stored keys).

* Observability: * CloudWatch alarms and a dashboard

                                * document_id in every log

                                * model and prompt version in each result.

* Capacity and cost: confirm Bedrock quotas

             limit concurrent documents and skip duplicates (DE-4).

3. Nice-to-have for long-term maintainability: plan for later

* Quality: a labelled test set to check accuracy before prompt or model changes
* Environments: separate dev, test, prod.
* Housekeeping:  S3 lifecycle rule (versioning keeps old copies forever). 

            Faster Docker builds: install packages before copying code, and remove --no-cache.



### 4. Terraform — Adding a Pipeline Step

 In their repo, each Lambda is written out by hand (not in a loop), so a new step touches about 10 files.

File → Add

src/tasks/validate.py (new) → validate_fields(event): checks each field's type and format with a Pydantic model per document type; returns is_valid and a list of errors

src/lambdas/validate/handler.py (new) →Same 3-line pattern as the other handlers: log, then call validate_fields(event)

tests/test_tasks.py →Tests for valid data, a missing field, and a wrong format

terraform/modules/lambda/main.tf →A new log group and a new aws_lambda_function "validate" with handler lambdas.validate.handler.handler; no Bedrock or S3 access needed

terraform/modules/lambda/outputs.tf →validate_arn

terraform/live/candidate/main.tf →Pass validate_lambda_arn = module.lambda.validate_arn to the Step Functions module

terraform/modules/step-functions/variables.tf → A validate_lambda_arn variable

terraform/modules/step-functions/main.tf → Add the ARN to the invoke permission list and to the templatefile values

terraform/modules/step-functions/state_machine.asl.json → Extract's Next becomes Validate; a new Validate state with input from $.extract_result, ResultPath $.validate_result, Next Aggregate

Makefile → Add validate to the update-lambdas loop



**Your answer:**
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
(These checks can run in the Validate step in question 6-shared)

The code today: no schema. The model’s JSON is saved with no checks.

What to change:

  Schema Check: Define one Pydantic(already installed) schema per document type, then validate every extraction against it.

  Business rules: checks for values that are valid alone but impossible together (e.g. a compliance deadline before the document date).

The code today: no failure handling. Any step fails, the whole document fails.

What to change: 

* Bedrock throttled/timed out: retry with backoff (see question 4).
* Reply is not valid JSON: retry once with a stricter prompt.
* Valid JSON that fails the schema or a rule: save it with a mark “needs review,” send it to a review queue, and count it with a metric with an alarm.
* Low confidence: send it to human review.

Result: nothing is silently dropped, every result says whether it passed validation.


### DE-2. Pipeline at Scale

This processes one document per Step Functions execution. Design a batch pipeline that handles 100,000 documents per day. What changes to the Step Functions architecture? Where would you parallelize, and where are the bottlenecks?

**Your answer:**
The code today: one Step Functions run per upload, using Standard workflows.

* Each document makes two Bedrock calls (Classify and Extract)

What to change:

* Buffer in SQS: put S3 events into an SQS queue, so a spike waits in the queue instead of failing.
* Batch process: a Step Functions Distributed Map reads a batch of documents and runs them in parallel, with a MaxConcurrency limit set below the Bedrock quota.
* Cheaper workflows: use Express workflows for each document (Standard workflows, used today, charge for every step).
* Fewer model calls: combine Classify and Extract into one Bedrock call, or use Bedrock batch inference (sends many requests in bulk) for documents that aren’t urgent.

Bottleneck → Solution:

* Bedrock requests and tokens per minute → concurrency limit, backoff retries, quota increase request.
* Lambda concurrent executions → reserved concurrency for the pipeline.
* Step Functions cost /limits → Express workflows, Distributed Map.


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

