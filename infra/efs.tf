module "efs" {
  source = "../terraform-modules/efs"

  efs_name          = var.docker_app
  efs_subnets       = data.terraform_remote_state.gohunt_devops.outputs.private_subnets
  kms_key_id        = "arn:aws:kms:us-west-2:961267742133:key/c27ac6a3-c9e1-44d4-8145-fb7beda9398a"
  security_group_id = module.sg.security_group_id
}

module "sg" {
  source = "../terraform-modules/security-group"

  stack_name = var.stack_name

  create_sg   = true
  description = "${var.docker_app}-efs-sg"
  sg_name     = "${var.docker_app}-efs"
  vpc_id      = data.terraform_remote_state.gohunt_devops.outputs.vpc_id

  create_ingress_with_cidr_blocks = true
  ingress_with_cidr_blocks = [
    {
      rule        = "efs from vpc cidr"
      cidr_blocks = data.terraform_remote_state.gohunt_devops.outputs.vpc_id
      from_port   = 2049
      to_port     = 2049
      protocol    = "udp"
      description = "efs from vpc cidr"
    },
    {
      rule        = "efs from vpc cidr"
      cidr_blocks = data.terraform_remote_state.gohunt_devops.outputs.vpc_id
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      description = "efs from vpc cidr"
    }
  ]

  create_egress_with_cidr_blocks = true
  egress_with_cidr_blocks = [
    {
      rule        = "All IPv4 traffic"
      cidr_blocks = "0.0.0.0/0"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "All IPv4 traffic"
    }
  ]
}
