output "github_actions_role_arn" {
  value       = module.github_oidc.role_arn
  description = "Role ARN for GitHub Actions"
}

output "app_url" {
  value       = "https://tools.eks.${var.domain}"
  description = "IT-Tools application URL"
}

output "argocd_url" {
  value       = "https://argocd.eks.${var.domain}"
  description = "ArgoCD dashboard URL"
}

output "grafana_url" {
  value       = "https://grafana.eks.${var.domain}"
  description = "Grafana dashboard URL"
}

output "argocd_admin_password_command" {
  value       = "kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath=\"{.data.password}\" | base64 -d"
  description = "Command to retrieve ArgoCD admin password"
}

output "configure_kubectl_command" {
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
  description = "Command to configure kubectl"
}
