// Module is pulled down in Jenkinsfile to terraform-modules path, if running locally pull the terraform-modules repo and update the source path
module "alb" {
  source = "../terraform-modules/load-balancer"

  # Default parameters
  stack_name = var.stack_name

  # LB parameters
  create_lb       = true
  internal        = false
  name            = "rp"
  scheme          = "pub"
  security_groups = [module.alb.security_group_id]
  subnets         = data.terraform_remote_state.gohunt_devops.outputs.public_subnets
  type            = "ALB"

  # LB Listener parameters
  create_http_listener = true
  http_tcp_listeners = [
    {
      port     = 80
      protocol = "HTTP"
    }
  ]

  create_https_listener = true
  https_listeners = [
    {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = data.terraform_remote_state.gohunt_devops.outputs.ssl_arn
    }
  ]
  target_group_arn = module.fargate.target_group_arns[0]

  # SG parameters
  create_sg                       = true
  create_ingress_with_cidr_blocks = true
  ingress_with_cidr_blocks = [
    {
      rule        = "http from public"
      cidr_blocks = "0.0.0.0/0"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "http from public"
    },
  ]
  create_egress_with_cidr_blocks = true
  egress_with_cidr_blocks = [
    {
      rule        = "All IPv4 traffic"
      cidr_blocks = "0.0.0.0/0"
      from_port   = 0
      to_port     = 0
      protocol    = -1
      description = "All IPv4 traffic"
    }
  ]

}
