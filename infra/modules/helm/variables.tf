variable "lbc_pod_identity" {
  description = "The ARN of the IAM role associated with the AWS Load Balancer Controller pod identity."
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
}
variable "vpc_id" {
  description = "The ID of the VPC where the EKS cluster is deployed."
  type        = string
}
variable "external_dns_pod_identity" {
  type        = string
  description = "External DNS pod identity association"
}
