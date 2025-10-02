# Terraform EventBridge → Lambda Demo

This repository is a working demonstration of building an **event-driven microservices foundation on AWS** using **Terraform-first principles**.

The project provisions:

- **Custom EventBridge Bus** – decouples event producers and consumers
- **EventBridge Rule + Target** – filters `orderPlaced` events and routes them
- **Lambda Function (Python)** – simple handler that logs and echoes the event
- **Dead Letter Queue (SQS)** – captures failed event deliveries for resilience
- **EventBridge Scheduler** – cron/rate-based trigger to the Lambda (heartbeat example)
- **Reusable Terraform Module** – `modules/event_consumer` to standardise rule/target creation with retries, DLQ, and max event age policies

This setup demonstrates **resilience, traceability, and modularity**, and provides a reusable pattern for scaling out additional event-driven microservices.

---

## 🛠 Tech Stack

- **Terraform** (AWS provider v5)
- **AWS EventBridge** (bus, rules, scheduler)
- **AWS Lambda (Python 3.12)**
- **AWS SQS** (DLQ)
- **Terraform pre-commit hooks** (fmt, validate, tflint, docs)
- **Python linting** (black, isort, ruff)

---

## 🚀 Getting Started

### Prerequisites
- Terraform >= 1.6
- AWS CLI configured with a profile/region
- Python 3.12+

### Clone and Scaffold
```bash
git clone git@github.com:<your-org>/terraform-eventbridge-lambda-demo.git
cd terraform-eventbridge-lambda-demo
```

### Deploy
```bash
terraform init
terraform apply
```

### Test the Event Flow
```bash
aws events put-events --region eu-west-2 --entries '[
  {
    "Source": "app.orders",
    "DetailType": "orderPlaced",
    "EventBusName": "orders-bus",
    "Detail": "{\"orderId\":\"A123\",\"amount\":49.99}"
  }
]'
```

Check the Lambda logs in CloudWatch to see the event.

---

## ✅ CI/CD & Quality Gates

This repo has **quality enforcement built in**, both locally and remotely.

### Local (pre-commit)
A `.pre-commit-config.yaml` is included. It enforces:
- **Terraform**: fmt, validate, tflint, docs
- **Python**: black, isort, ruff
- **General hygiene**: trailing whitespace, EOF newline, merge conflict markers

Install once:
```bash
pip install pre-commit
pre-commit install
```

Run on all files:
```bash
pre-commit run --all-files
```

### Remote (GitHub Actions)

- **Terraform Lint** (`.github/workflows/terraform_lint.yml`)
  Runs `terraform fmt`, `validate`, and `tflint` on PRs and pushes.

- **Python Lint** (`.github/workflows/python_lint.yml`)
  Runs `black`, `isort`, and `ruff` across all Python files.

Both jobs cache dependencies for speed and run automatically on every PR and push to `main`.

---

## 📂 Project Structure
```
terraform-eventbridge-lambda-demo/
├── main.tf                 # Root Terraform stack
├── variables.tf            # Input variables
├── outputs.tf              # Stack outputs
├── lambda/
│   └── handler.py          # Python Lambda handler
└── modules/
    └── event_consumer/     # Reusable module for EventBridge rule + target
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## 📖 Talking Points (for interview/demo)
- **Resilience:** Retry policy + DLQ (SQS) prevents event loss.
- **Traceability:** Events carry correlation IDs, logs are JSON structured.
- **Modularity:** Consumers defined via reusable Terraform module.
- **Automation-first:** All infra codified in Terraform, validated locally and in CI/CD.

---

## 🔮 Next Steps (if you extend this demo)
- Add a second consumer (e.g., SQS) to show **fan-out**.
- Add tracing with **AWS X-Ray**.
- Add `tflint.hcl` and `ruff.toml` for stricter linting.
- Integrate with **GitHub Actions → Terraform Cloud** for deployment pipelines.

---
