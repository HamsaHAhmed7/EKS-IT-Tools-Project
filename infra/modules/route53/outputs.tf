
output "zone_id" {
  value = aws_route53_zone.eks.zone_id
}

output "zone_name" {
  value = aws_route53_zone.eks.name
}
