# 🧠 AWS Architecture RAG Chatbot (Amazon Bedrock + DynamoDB)

![CI](https://github.com/essiea/rag-cloud-architect-chatbot/actions/workflows/ci.yml/badge.svg)
![Python](https://img.shields.io/badge/Python-3.11-blue.svg)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC)
![AWS](https://img.shields.io/badge/AWS-Serverless-orange)
![License](https://img.shields.io/badge/License-MIT-green)

The **RAG Cloud Architect Chatbot** is a serverless Retrieval-Augmented Generation (RAG) system that allows teams to query AWS architecture documentation using natural language.

Upload architecture docs to S3, and the system will:

- Chunk text  
- Generate Titan embeddings  
- Store vectors in DynamoDB  
- Retrieve relevant context  
- Use Claude 3 Sonnet to answer questions  

---

## 🚀 Features

- S3 document ingestion  
- Text chunking + Titan embeddings  
- DynamoDB vector storage  
- Claude 3 RAG reasoning  
- API-based query endpoint  
- Fully serverless, low cost  

---

## 🧠 Architecture

### Mermaid Diagram

\`\`\`mermaid
flowchart TD
    S3[S3 Docs Bucket] --> ING[Ingest Lambda]
    ING --> DDB[(DynamoDB Vector Store)]
    QL[Query Lambda] --> DDB
    QL --> B[Bedrock Claude 3 Sonnet]
    API[API Gateway] --> QL
    USER[User / Web UI] --> API
\`\`\`

---

## 📁 Repository Structure

\`\`\`
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
\`\`\`

---

## 🔧 Requirements

- AWS Bedrock enabled  
- DynamoDB table  
- S3 bucket for docs  
- IAM:
  - \`bedrock:InvokeModel\`
  - DynamoDB read/write  
  - S3 read  
- Python 3.11  
- Terraform 1.6+  

---

## 🛠 Deployment

\`\`\`bash
cd terraform
terraform init
terraform apply -auto-approve
\`\`\`

---

## 🤝 Contributing  
PRs welcome.

---

## 📄 License  
MIT License.
