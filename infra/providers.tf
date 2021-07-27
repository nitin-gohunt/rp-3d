provider "aws" {
  region = var.region
}

provider "aws" {
  region      = var.region
  max_retries = "100"

  assume_role {
    role_arn = "arn:aws:iam::079128414198:role/jenkins_role"
  }
  alias = "production"
}
