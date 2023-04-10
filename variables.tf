variable "vpc_name" {
  default     = "aws-eks-ec2"
  type        = string
  description = "aws-eks-ec2"
}

variable "project" {
  default     = "aws-eks-ec2"
  type        = string
  description = "aws-eks-ec2"
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "Extra tags to attach to the VPC resources"
}

variable "environment" {
  default     = "test"
  type        = string
  description = "test environment"
}

variable "cidr_block" {
  default     = "10.15.0.0/16"
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnet_cidr_blocks" {
  default     = ["10.15.0.0/18", "10.15.64.0/18"]
  type        = list(any)
  description = "List of public subnet CIDR blocks"
}

variable "private_subnet_cidr_blocks" {
  default     = ["10.15.128.0/18", "10.15.192.0/18"]
  type        = list(any)
  description = "List of private subnet CIDR blocks"
}

variable "availability_zones" {
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
  type        = list(any)
  description = "List of availability zones"
}

variable "availability_zones_ref" {
  default     = ["a", "b"]
  type        = list(any)
  description = "List of availability zones reference"
}

variable "region" {
  default     = "ap-southeast-1"
  type        = string
  description = "Region of the VPC"
}

variable "eks_name" {
  default     = "eksec2-cluster"
  type        = string
  description = "eksec2-cluster"
}

variable "eks_version" {
  default     = "1.22"
  type        = string
  description = "1.22"
}

variable "enabled_cluster_log_types" {
  type        = list(string)
  description = "A list of the desired control plane logging [`api`, `audit`, `authenticator`, `controllerManager`, `scheduler`]"
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "k8s_cluster_type" {
  description = "Can be set to `vanilla` or `eks`. If set to `eks`"
  type        = string
  default     = "eks"
}

variable "chart_env_overrides" {
  description = "env values passed to the load balancer controller helm chart."
  type        = map(any)
  default     = {}
}

variable "settings" {
  type        = any
  default     = {}
  description = "Additional settings which will be passed to the Helm chart values, see https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller#configuration."
}