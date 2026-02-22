variable "project" {
  type = string
}
variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}
variable "common_tags" {
  type = map(string)
}

variable "eks_version" {
  type = string
}
