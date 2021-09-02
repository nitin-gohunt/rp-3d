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
    },
    {
      port     = 81
      protocol = "HTTP"
    },
    {
      port     = 8080
      protocol = "HTTP"
    }
  ]

  create_https_listener = true
  https_listeners = [
    {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = data.terraform_remote_state.gohunt_devops.outputs.ssl_arn
    },
    {
      port            = 6443
      protocol        = "HTTPS"
      certificate_arn = data.terraform_remote_state.gohunt_devops.outputs.ssl_arn
    },
    {
      port            = 7443
      protocol        = "HTTPS"
      certificate_arn = data.terraform_remote_state.gohunt_devops.outputs.ssl_arn
    },
    {
      port            = 8443
      protocol        = "HTTPS"
      certificate_arn = data.terraform_remote_state.gohunt_devops.outputs.ssl_arn
    },
    {
      port            = 10443
      protocol        = "HTTPS"
      certificate_arn = data.terraform_remote_state.gohunt_devops.outputs.ssl_arn
    },
  ]
  target_group_arn = module.fargate.target_group_arns[0]

  # SG parameters
  create_sg                       = true
  sg_description                  = "Reverse Proxy security group"
  vpc_id                          = data.terraform_remote_state.gohunt_devops.outputs.vpc_id
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
    {
      rule        = "off-brand http from public"
      cidr_blocks = "0.0.0.0/0"
      from_port   = 81
      to_port     = 81
      protocol    = "tcp"
      description = "http from public"
    },
    {
      rule        = "off-off-brand http from public"
      cidr_blocks = "0.0.0.0/0"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "http from public"
    },
    {
      rule        = "https from public"
      cidr_blocks = "0.0.0.0/0"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "https from public"
    },
    {
      rule        = "arcgis portal https from public"
      cidr_blocks = "0.0.0.0/0"
      from_port   = 6443
      to_port     = 6443
      protocol    = "tcp"
      description = "https from public"
    },
    {
      rule        = "arcgis server https from public"
      cidr_blocks = "0.0.0.0/0"
      from_port   = 7443
      to_port     = 7443
      protocol    = "tcp"
      description = "https from public"
    },
    {
      rule        = "arcgis server 2 https from public"
      cidr_blocks = "0.0.0.0/0"
      from_port   = 8443
      to_port     = 8443
      protocol    = "tcp"
      description = "https from public"
    },
    {
      rule        = "arcgis server 3 https from public"
      cidr_blocks = "0.0.0.0/0"
      from_port   = 10443
      to_port     = 10443
      protocol    = "tcp"
      description = "https from public"
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
