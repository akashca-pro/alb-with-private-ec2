terraform {
  backend "s3" {
    bucket         = "task-3-41-tf-state-ak"
    key            = "terraform/task-3-46-alb/terraform.tfstate"
    region         = "ap-south-1"
    use_lockfile   = true
    #dynamodb_table = "task-3-41-tf-lock"
  }
}