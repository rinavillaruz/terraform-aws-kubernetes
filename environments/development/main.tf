module iam {
  source = "../../modules/iam"
}

module ssm {
  source = "../../modules/ssm"
}

module keypair {
  source = "../../modules/keypair"
}

module networking {
  source = "../../modules/networking"
}

module security_groups {
  source = "../../modules/security_groups"

  vpc_id          = module.networking.vpc_id
  vpc_cidr_block  = module.networking.vpc_cidr_block
  
  depends_on = [module.networking]
}

module "compute" {
  source = "../../modules/compute"
  
  # Pass AWS resources from development module
  private_subnets                     = module.networking.private_subnets
  public_subnets                      = module.networking.public_subnets
  bastion_security_group_id           = module.security_groups.bastion_security_group_id
  control_plane_security_group_id     = module.security_groups.control_plane_security_group_id
  worker_node_security_group_id       = module.security_groups.worker_node_security_group_id  
  kubernetes_master_instance_profile  = module.iam.kubernetes_master_instance_profile
  kubernetes_worker_instance_profile  = module.iam.kubernetes_worker_instance_profile
  key_pair_name                       = module.keypair.key_pair_name
  tls_private_key_pem                 = module.keypair.tls_private_key_pem
  vpc_id                              = module.networking.vpc_id
  
  depends_on = [module.iam, module.keypair, module.networking, module.security_groups]
}