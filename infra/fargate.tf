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
  health_check_path = "/"
  image_tag         = var.image_tag
  target_group_arn = module.fargate.target_group_arns[0]
  variable_file     = "auth.localenv"

  create_listener_rule = true
  listener_arn         = data.terraform_remote_state.gohunt_devops.outputs.ecs_alb_listener_arn
  listener_rules = [
    {
      priority = 98
      actions = [
        {
          type = "forward"
        }
      ],
      conditions = [{
        host_headers = ["test_nginx.staging.gohunt.com"]
      }]
    }
  ]
}
