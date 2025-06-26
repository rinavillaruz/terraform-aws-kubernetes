module "development" {
  source = "../../modules/aws"
}

locals {
  modules = {
    development = module.development
  }
}