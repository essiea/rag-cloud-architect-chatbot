---

# ✅ **README 2 — RAG Cloud Architect Chatbot**
**File:** `rag-cloud-architect-chatbot/README.md`

```markdown
# 🧠 AWS Architecture RAG Chatbot (Amazon Bedrock + DynamoDB)

![CI](https://github.com/<YOUR_GITHUB_USERNAME>/rag-cloud-architect-chatbot/actions/workflows/ci.yml/badge.svg)
![Python](https://img.shields.io/badge/Python-3.11-blue.svg)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC)
![AWS](https://img.shields.io/badge/AWS-Serverless-orange)
![License](https://img.shields.io/badge/License-MIT-green)

A **Retrieval-Augmented Generation (RAG)** chatbot designed for DevOps and Cloud teams.  
Upload your AWS architecture documentation to S3, and the bot answers questions about your infrastructure using:

- Amazon Titan Text Embeddings  
- DynamoDB (vector store)  
- Lambda ingestion + query functions  
- Bedrock Claude 3 Sonnet for reasoning  
- API Gateway for public access  

---

## 🚀 Features

- Full RAG pipeline  
- Upload architecture docs to S3 → automatically indexed  
- Chunking + embeddings with Titan  
- DynamoDB vector similarity search  
- Natural language answers using Claude 3 Sonnet  
- Fully serverless (cheap, scalable)  

---

## 🧠 Architecture

![Architecture](docs/png/architecture.png)

### Mermaid Diagram
```mermaid
flowchart TD
    S3[S3 Docs Bucket] --> ING[Ingest Lambda]
    ING --> DDB[(DynamoDB Vector Store)]
    QL[Query Lambda] --> DDB
    QL --> B[Bedrock Claude 3 Sonnet]
    API[API Gateway] --> QL
    USER[User/Web Interface] --> API
ASCII Diagram
graphql
Copy code
S3 → Ingest Lambda → DynamoDB (vectors)
             ↑
             |
Query Lambda ← API Gateway
             ↓
          Bedrock LLM
📁 Repository Structure
arduino
Copy code
rag-cloud-architect-chatbot/
├── app/
│   ├── config.py
│   ├── embedding.py
│   ├── rag.py
│   ├── lambda_ingest.py
│   └── lambda_query.py
└── terraform/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
🛠 Deployment (Terraform)
bash
Copy code
cd terraform
terraform init
terraform apply -auto-approve \
  -var="doc_bucket_name=my-architecture-docs"
Outputs:

API endpoint for querying chatbot

DynamoDB table name

📤 Upload Documents
bash
Copy code
aws s3 cp docs/vpc-design.md s3://my-architecture-docs/
aws s3 cp docs/stepfunctions.md s3://my-architecture-docs/
The ingest Lambda will automatically:

Read files

Chunk them

Create embeddings

Store vectors in DynamoDB

🔎 Query API
bash
Copy code
curl -X POST \
  https://<api-id>.execute-api.us-east-1.amazonaws.com/chat \
  -d '{ "question": "Explain our VPC architecture" }'
📘 Example Answer
json
Copy code
{
  "answer": "Your VPC spans 2 AZs, with public and private subnets..."
}
💰 Cost Overview
Component	Cost
DynamoDB	~$0.10–$1/mo (pay-per-request)
S3	free tier available
API Gateway	~$1/mo
Bedrock	pay-per-request

🐛 Troubleshooting
Issue	Solution
Query results irrelevant	Increase chunk size or TOP_K
Ingest Lambda not firing	Check S3 bucket notification events
Bedrock AccessDenied	Add Bedrock invoke permissions

🤝 Contributing
Feel free to open issues or submit PRs!

📄 License
MIT License.
