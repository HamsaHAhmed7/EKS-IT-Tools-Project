output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster."
  value       = aws_eks_cluster.cluster.endpoint
}

output "cluster_ca_cert" {
  description = "The base64 encoded certificate data required to communicate with the cluster."
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
}

output "cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.cluster.name
}

output "aws_lbc_pod_identity" {
  description = "The ARN of the IAM role associated with the AWS Load Balancer Controller pod identity."
  value       = aws_iam_role.aws_lbc_role.arn

}

output "external_dns_pod_identity" {
  value = aws_eks_pod_identity_association.external_dns.id
}
