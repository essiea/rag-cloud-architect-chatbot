variable "region" {
  type    = string
  default = "us-east-1"
}

variable "doc_bucket_name" {
  type        = string
  description = "S3 bucket name for architecture docs"
}

variable "table_name" {
  type        = string
  default     = "rag-architecture-vectors"
}

variable "embed_model_id" {
  type        = string
  default     = "amazon.titan-embed-text-v1"
}

variable "llm_model_id" {
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}
