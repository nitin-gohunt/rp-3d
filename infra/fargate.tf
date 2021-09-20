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
  cpu               = 1024
  memory            = 2048
  health_check_path = "/healthcheck"
  image_tag         = var.image_tag
  use_datadog       = "true"
  variable_file     = "auth.localenv"
  volumes = [
    {
      name = "${var.docker_app}-efs"
      efs_volume_configuration = [{
        file_system_id = module.efs.efs_file_system_id
        root_directory = "/"
      }]
    }
  ]
  mount_points = [
    {
      containerPath = "/data/nginx/cache"
      sourceVolume  = "${var.docker_app}-efs"
    }
  ]
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

  # Listener parameters
  create_listener_rule = true
  listener_arn         = data.terraform_remote_state.rp_layers.outputs.https_listener_arn
  listener_rules = [
    {
      priority = 40
      actions = [
        {
          type = "forward"
        }
      ],
      conditions = [{
        path_patterns = ["/arcgis/sharing/rest/portals/self*", "/arcgis/sharing/rest/content/items*"]
      }]
    }
  ]
  target_group_arn = module.fargate.target_group_arns[0]
}
