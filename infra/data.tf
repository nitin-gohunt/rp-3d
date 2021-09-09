data "aws_caller_identity" "current" {}

data "aws_availability_zones" "azs" {
  state = "available"
}

data "aws_region" "region" {}

data "terraform_remote_state" "gohunt_devops" {
  backend = "s3"

  config = {
    bucket = local.tf_states_bucket
    key    = "${var.stack_name}/tf-infrastructure.state"
    region = var.region
  }
}
