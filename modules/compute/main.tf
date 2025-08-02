# Ec2
resource "aws_instance" "bastion" {
  count                   = length(var.public_subnet_cidrs)
  ami                     = var.bastion.ami
  instance_type           = var.bastion.instance_type
  key_name                = var.key_pair_name 
  vpc_security_group_ids  = [var.bastion_security_group_id]
  subnet_id               = var.public_subnets[count.index].id
  private_ip              = var.bastion.private_ip

  tags = {
    Name                = "${terraform.workspace} - ${var.bastion.name}"
    Environment         = terraform.workspace
    Project             = "Kubernetes"
    Role                = "bastion-host"
    ManagedBy           = "Terraform"
    CostCenter          = "Infrastructure"
    MonitoringEnabled   = "true"
    # AvailabilityZone    = var.public_subnets[count.index].availability_zone
    SubnetType          = "public"
    # InstanceIndex       = count.index + 1
    CreatedDate         = formatdate("YYYY-MM-DD", timestamp())
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"]]
  }
}

# Allocate an Elastic IP for each bastion host
resource "aws_eip" "bastion_eip" {
  count    = length(var.public_subnet_cidrs)
  domain   = "vpc"
}

# Associate each Elastic IP with a corresponding bastion instance
resource "aws_eip_association" "bastion_eip_assoc" {
  count         = length(var.public_subnet_cidrs)
  instance_id   = aws_instance.bastion[count.index].id
  allocation_id = aws_eip.bastion_eip[count.index].id
}

resource "null_resource" "upload_common_functions" {
  depends_on = [null_resource.wait_for_master_ready]
  
  provisioner "file" {
    source                  = "${path.module}/${var.common_functions.source}"
    destination             = var.common_functions.destination
    
    connection {
      type                  = var.common_functions.connection.type
      user                  = var.common_functions.connection.user
      private_key           = var.tls_private_key_pem
      host                  = aws_instance.control_plane["0"].private_ip
      bastion_host          = aws_eip.bastion_eip[0].public_ip
      bastion_user          = var.common_functions.connection.bastion_user
      bastion_private_key   = var.tls_private_key_pem
    }
  }
  
  # Make sure the file is executable
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/common-functions.sh",
      "echo 'Common functions uploaded successfully'"
    ]
    
    connection {
      type                = var.common_functions.connection.type
      user                = var.common_functions.connection.user
      private_key         = var.tls_private_key_pem
      host                = aws_instance.control_plane["0"].private_ip
      bastion_host        = aws_eip.bastion_eip[0].public_ip
      bastion_user        = var.common_functions.connection.bastion_user
      bastion_private_key = var.tls_private_key_pem
    }
  }
}

resource "aws_instance" "control_plane" {
  for_each                = { "0" = true }
  ami                     = var.control_plane.ami
  instance_type           = var.control_plane.instance_type
  key_name                = var.key_pair_name
  vpc_security_group_ids  = [var.control_plane_security_group_id]
  subnet_id               = var.private_subnets[0].id
  private_ip              = var.control_plane_private_ips[0]
  iam_instance_profile    = var.kubernetes_master_instance_profile

  root_block_device {
    volume_size           = var.control_plane.root_block_device.volume_size
    volume_type           = var.control_plane.root_block_device.volume_type
    delete_on_termination = var.control_plane.root_block_device.delete_on_termination
  }

  user_data = templatefile("${path.module}/${var.control_plane.init_file}", {
    common_functions                  = file("${path.module}/${var.common_functions.source}")
    control_plane_endpoint            = aws_lb.k8s_api.dns_name
    control_plane_master_private_ip   = var.control_plane_private_ips[0]
    is_first_control_plane            = "true"
  })

  tags = {
    Name = "${terraform.workspace} - ${var.control_plane.name}"
  }
}

# Wait for master control plane to be fully ready
resource "null_resource" "wait_for_master_ready" {
  depends_on = [aws_instance.control_plane]

  provisioner "remote-exec" {
    inline = [
      templatefile("${path.module}/${var.wait_for_master_ready.source}", {
        common_functions = file("${path.module}/${var.common_functions.source}")
      })
    ]

    connection {
      type                = var.common_functions.connection.type
      user                = var.common_functions.connection.user
      private_key         = var.tls_private_key_pem
      host                = aws_instance.control_plane["0"].private_ip
      bastion_host        = aws_eip.bastion_eip[0].public_ip
      bastion_user        = var.common_functions.connection.bastion_user
      bastion_private_key = var.tls_private_key_pem
      timeout             = var.common_functions.connection.timeout
    }
  }

  triggers = {
    instance_id = aws_instance.control_plane["0"].id
  }
}

# Additional control plane nodes (created after master)
resource "aws_instance" "control_plane_secondary" {
  for_each                = { "1" = 1, "2" = 2 }
  
  ami                     = var.control_plane_secondary.ami
  instance_type           = var.control_plane_secondary.instance_type
  key_name                = var.key_pair_name 
  vpc_security_group_ids  = [var.control_plane_security_group_id]
  subnet_id               = var.private_subnets[each.value].id
  private_ip              = var.control_plane_private_ips[each.value]
  iam_instance_profile    = var.kubernetes_master_instance_profile

  root_block_device {
    volume_size           = var.control_plane_secondary.root_block_device.volume_size
    volume_type           = var.control_plane_secondary.root_block_device.volume_type
    delete_on_termination = var.control_plane_secondary.root_block_device.delete_on_termination
  }

  user_data = templatefile("${path.module}/${var.control_plane_secondary.init_file}", {
    common_functions                  = file("${path.module}/${var.common_functions.source}")
    control_plane_endpoint            = aws_lb.k8s_api.dns_name
    control_plane_master_private_ip   = var.control_plane_private_ips[0]
    is_first_control_plane            = "false"
  })

  depends_on = [null_resource.wait_for_master_ready]

  tags = {
    Name              = "${terraform.workspace} - ${var.control_plane.name}"
    Environment       = terraform.workspace
    Project           = "Kubernetes"
    Role              = "control-plane"
    ManagedBy         = "Terraform"
    CostCenter        = "Infrastructure"
    MonitoringEnabled = "true"
    # AvailabilityZone  = var.private_subnets[0].availability_zone
    SubnetType        = "private"
    # InstanceIndex     = each.key
    CreatedDate       = formatdate("YYYY-MM-DD", timestamp())
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"]]
  }
}

resource "aws_instance" "worker_nodes" {
  count                   = var.worker_nodes.count
  ami                     = var.worker_nodes.ami
  instance_type           = var.worker_nodes.instance_type
  key_name                = var.key_pair_name
  vpc_security_group_ids  = [var.worker_node_security_group_id]
  
  # Use modulo to distribute worker nodes across available subnets
  subnet_id               = var.private_subnets[count.index % length(var.private_subnets)].id

  iam_instance_profile    = var.kubernetes_worker_instance_profile

  root_block_device {
    volume_size           = var.worker_nodes.root_block_device.volume_size
    volume_type           = var.worker_nodes.root_block_device.volume_type
    delete_on_termination = var.worker_nodes.root_block_device.delete_on_termination
  }

  user_data = templatefile("${path.module}/${var.worker_nodes.init_file}", {
    common_functions = file("${path.module}/${var.common_functions.source}")
  })

  # Wait for at least the master control plane to be ready
  depends_on = [null_resource.wait_for_master_ready]

   tags = {
    Name              = "${terraform.workspace} - ${var.worker_nodes.name} ${count.index + 1}"
    Environment       = terraform.workspace
    Project           = "Kubernetes"
    Role              = "worker-node"
    ManagedBy         = "Terraform"
    CostCenter        = "Infrastructure"
    MonitoringEnabled = "true"
    # AvailabilityZone  = var.private_subnets[count.index % length(var.private_subnets)].availability_zone
    SubnetType        = "private"
    # InstanceIndex     = count.index + 1
    NodeType          = "compute"
    WorkloadCapable   = "true"
    CreatedDate       = formatdate("YYYY-MM-DD", timestamp())
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"]]
  }
}

# Wait for worker nodes to join the cluster
resource "null_resource" "wait_for_workers_to_join" {
  depends_on    = [
    aws_instance.worker_nodes,
    aws_instance.control_plane_secondary
  ]

  provisioner "remote-exec" {
    inline      = [
      templatefile("${path.module}/${var.wait_for_workers_to_join.init_file}", {
        common_functions  = file("${path.module}/${var.common_functions.source}")
        expected_workers  = length(aws_instance.worker_nodes)
        timeout_seconds   = 600
        check_interval    = 30
        log_file          = var.wait_for_workers_to_join.log_file
      })
    ]

    connection {
      type                = var.common_functions.connection.type
      user                = var.common_functions.connection.user
      private_key         = var.tls_private_key_pem
      host                = aws_instance.control_plane["0"].private_ip
      bastion_host        = aws_eip.bastion_eip[0].public_ip
      bastion_user        = var.common_functions.connection.bastion_user
      bastion_private_key = var.tls_private_key_pem
    }
  }

  triggers = {
    worker_instances        = join(",", aws_instance.worker_nodes[*].id)
    control_plane_instances = join(",", values(aws_instance.control_plane_secondary)[*].id)
  }
}

# Separate null_resource to label worker nodes after they join the cluster
resource "null_resource" "label_worker_nodes" {
  depends_on = [null_resource.wait_for_workers_to_join]

  provisioner "remote-exec" {
    inline = [
      templatefile("${path.module}/${var.label_worker_nodes.init_file}", {
        common_functions      = file("${path.module}/${var.common_functions.source}")
        expected_worker_count = var.label_worker_nodes.expected_worker_count
      })
    ]

    connection {
      type                = var.common_functions.connection.type
      user                = var.common_functions.connection.user
      private_key         = var.tls_private_key_pem
      host                = aws_instance.control_plane["0"].private_ip
      bastion_host        = aws_eip.bastion_eip[0].public_ip
      bastion_user        = var.common_functions.connection.bastion_user
      bastion_private_key = var.tls_private_key_pem
    }
  }

  triggers = {
    worker_wait_complete = null_resource.wait_for_workers_to_join.id
  }
}

############################ LOAD BALANCERS ################################
resource "aws_lb" "k8s_api" {
  name               =  "k8s-api-lb"
  internal           =  true
  load_balancer_type =  "network"
  subnets            =  [for subnet in var.private_subnets : subnet.id]

  tags = {
    Name              = "${terraform.workspace} - Kubernetes API Load Balancer"
    Environment       = terraform.workspace
    Project           = "Kubernetes"
    Role              = "api-load-balancer"
    Component         = "networking"
    Purpose           = "kubernetes-api-endpoint"
    ManagedBy         = "Terraform"
    CostCenter        = "Infrastructure"
    MonitoringEnabled = "true"
    LoadBalancerType  = "network"
    Scheme            = "internal"
    Protocol          = "tcp"
    HighAvailability  = "true"
    SecurityLevel     = "high"
    CreatedDate       = formatdate("YYYY-MM-DD", timestamp())
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"]]
  }
}

resource "aws_lb_target_group" "k8s_api" {
  name     =    "k8s-api-tg"
  port     =    6443
  protocol =    "TCP"
  vpc_id   =    var.vpc_id

  health_check {
    protocol            =   "TCP"
    port                =   6443
    healthy_threshold   =   2
    unhealthy_threshold =   2
    interval            =   10
  }

  tags = {
    Name              = "${terraform.workspace} - Kubernetes API Target Group"
    Environment       = terraform.workspace
    Project           = "Kubernetes"
    Role              = "api-target-group"
    Component         = "networking"
    Purpose           = "kubernetes-api-health-check"
    ManagedBy         = "Terraform"
    CostCenter        = "Infrastructure"
    MonitoringEnabled = "true"
    Protocol          = "TCP"
    Port              = "6443"
    HealthCheck       = "enabled"
    ServiceType       = "kubernetes-api-server"
    TargetType        = "control-plane-nodes"
    CreatedDate       = formatdate("YYYY-MM-DD", timestamp())
  }

  lifecycle {
    ignore_changes = [tags["CreatedDate"]]
  }
}

# Master node attachment
resource "aws_lb_target_group_attachment" "k8s_api_master" {
  target_group_arn  =     aws_lb_target_group.k8s_api.arn
  target_id         =     aws_instance.control_plane["0"].id
  port              =     6443
}

# Secondary nodes attachment
resource "aws_lb_target_group_attachment" "k8s_api_secondary" {
  for_each         =    aws_instance.control_plane_secondary
  target_group_arn =    aws_lb_target_group.k8s_api.arn
  target_id        =    each.value.id
  port             =    6443
}

resource "aws_lb_listener" "k8s_api" {
  load_balancer_arn =   aws_lb.k8s_api.arn
  port              =   6443
  protocol          =   "TCP"

  default_action {
    type             =  "forward"
    target_group_arn =  aws_lb_target_group.k8s_api.arn
  }
}