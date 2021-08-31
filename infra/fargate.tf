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
    name = "nofile"
    hardLimit = "262144"
    softLimit = "262144"
  }]
  health_check_path = "/"
  image_tag         = var.image_tag
  variable_file     = "auth.localenv"
}
