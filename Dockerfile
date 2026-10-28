# Use the official AWS Lambda Python base image
FROM public.ecr.aws/lambda/python:3.13

# Copy application source
COPY src/ ${LAMBDA_TASK_ROOT}/

# Install Python dependencies
COPY requirements.lambda.txt ${LAMBDA_TASK_ROOT}/
RUN pip3 install --no-cache-dir -r ${LAMBDA_TASK_ROOT}/requirements.lambda.txt

# Default handler — overridden per function via Terraform image_config
CMD ["lambdas.preprocess.handler.handler"]
