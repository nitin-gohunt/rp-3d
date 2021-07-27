variable "docker_app" {
  description = "The name of the docker application"
  type        = string
}

variable "docker_repo" {
  description = "The name of the docker repo"
  type        = string
}

variable "environment" {
  description = "The name of the environment"
  type        = string
}

variable "image_tag" {
  description = "The image tag"
  type        = string
}

variable "region" {
  description = "The name of the aws region to deploy into"
  type        = string
}

variable "remote_state_s3_bucket" {
  description = "The terraform states bucket"
  type        = string
}

variable "stack_name" {
  description = "The name of the stack"
  type        = string
}

locals {
  tf_states_bucket = "${var.remote_state_s3_bucket}-${var.region}"
}
