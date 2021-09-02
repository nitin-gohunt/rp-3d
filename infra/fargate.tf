// Module is pulled down in Jenkinsfile to terraform-modules path, if running locally pull the terraform-modules repo and update the source path
module "fargate" {
  source = "../terraform-modules/fargate"

  # Default parameters
  aws_region       = var.region
  docker_repo      = var.docker_repo
  ecs_cluster_arn  = data.terraform_remote_state.gohunt_devops.outputs.ecs_cluster_arn
  ecs_cluster_name = data.terraform_remote_state.gohunt_devops.outputs.ecs_cluster_name
  environment      = var.environment
  network_configuration = [{
    subnets = data.terraform_remote_state.gohunt_devops.outputs.private_subnets
  }]
  private_route53_zone_id   = data.terraform_remote_state.gohunt_devops.outputs.private_route53_zone_id
  private_route53_zone_name = data.terraform_remote_state.gohunt_devops.outputs.private_route53_zone_name
  route53_zone_id           = data.terraform_remote_state.gohunt_devops.outputs.route53_zone_id
  route53_zone_name         = data.terraform_remote_state.gohunt_devops.outputs.route53_zone_name
  service_name              = var.docker_app
  stack_name                = var.stack_name
  vpc_cidr                  = [data.terraform_remote_state.gohunt_devops.outputs.vpc_cidr]
  vpc_id                    = data.terraform_remote_state.gohunt_devops.outputs.vpc_id

  # Service parameters
  ulimits = [{
    name      = "nofile"
    hardLimit = "262144"
    softLimit = "262144"
  }]
  health_check_path = "/healthcheck"
  image_tag         = var.image_tag
  variable_file     = "auth.localenv"
  datadog_secrets = [
    {
      valueFrom = data.terraform_remote_state.gohunt_devops.outputs.datadog_secret_arn
      name      = "DD_API_KEY"
    }
  ]
  log_subscription_filter = {
    destination_arn = data.terraform_remote_state.gohunt_devops.outputs.datadog_forwarder_arn
    filter_pattern  = ""
  }

  # Target Group Parameers
  create_target_group = true
  target_groups = [
    {
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "ip"
      deregistration_delay = 30
      health_check = {
        enabled             = true
        interval            = 30
        healthy_threshold   = 5
        unhealthy_threshold = 2
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200,301"
      }
    },
    {
      backend_protocol     = "HTTP"
      backend_port         = 8080
      target_type          = "ip"
      deregistration_delay = 30
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = 8080
        healthy_threshold   = 5
        unhealthy_threshold = 2
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200,301"
      }
    },
  ]

  # Listener parameters
  create_listener_rule = true
  listener_arn         = module.alb.http_tcp_listener_arns[0]
  listener_rules = [
    {
      priority = 10
      actions = [
        {
          type = "forward"
        }
      ],
      conditions = [{
        path_patterns = ["/*"]
      }]
    },
  ]
  target_group_arn = module.fargate.target_group_arns[0]
}
