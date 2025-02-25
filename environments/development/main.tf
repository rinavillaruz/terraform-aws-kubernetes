module "development" {
  source = "../../modules/aws"
}

locals {
  modules = {
    development = module.development
  }
}

output "private_key_path_from_module" {
  value = lookup(local.modules, terraform.workspace, null).private_key_path
}

output "public_key_path_from_module" {
  value = lookup(local.modules, terraform.workspace, null).public_key
}