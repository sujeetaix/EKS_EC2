resource "aws_iam_policy" "load-balancer-policy" {  
  name        = "AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "AWS LoadBalancer Controller IAM Policy"
  policy = file("alb_iam_policy.json")
}