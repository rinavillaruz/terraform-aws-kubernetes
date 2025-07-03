# Ec2
resource "aws_instance" "bastion" {
  count                   = length(var.public_subnet_cidrs)
  ami                     = "ami-084568db4383264d4"  # Replace with a Ubuntu 12 AMI ID
  instance_type           = "t3.micro"
  key_name                = aws_key_pair.generated_key.key_name
  vpc_security_group_ids  = [aws_security_group.bastion.id]
  subnet_id               = aws_subnet.public_subnets[count.index].id  # This should work now
  private_ip              = "10.0.1.10"

  tags = {
    Name = "${terraform.workspace} - Bastion Host"
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
  depends_on = [null_resource.wait_for_master_ready]  # Add this dependency!
  
  provisioner "file" {
    source      = "${path.module}/scripts/common-functions.sh"
    destination = "/tmp/common-functions.sh"
    
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.example.private_key_pem
      host        = aws_instance.control_plane["0"].private_ip
      bastion_host = aws_eip.bastion_eip[0].public_ip
      bastion_user = "ubuntu"
      bastion_private_key = tls_private_key.example.private_key_pem
    }
  }
  
  # Make sure the file is executable
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/common-functions.sh",
      "echo 'Common functions uploaded successfully'"
    ]
    
    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = tls_private_key.example.private_key_pem
      host                = aws_instance.control_plane["0"].private_ip
      bastion_host        = aws_eip.bastion_eip[0].public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = tls_private_key.example.private_key_pem
    }
  }
}

resource "aws_instance" "control_plane" {
  for_each                = { "0" = true }  # Only master node
  # count                   = 3  # High availability with 3 control plane nodes
  ami                     = "ami-084568db4383264d4"  # Replace with a Ubuntu 12 AMI ID
  instance_type           = "t3.xlarge"
  key_name                = aws_key_pair.generated_key.key_name
  vpc_security_group_ids  = [aws_security_group.control_plane.id]
  subnet_id               = aws_subnet.private_subnets[0].id
  private_ip              = var.control_plane_private_ips[0]
  iam_instance_profile    = aws_iam_instance_profile.kubernetes_master.name

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/scripts/init-control-plane.sh.tmpl", {
    common_functions                  = file("${path.module}/scripts/common-functions.sh")
    control_plane_endpoint            = aws_lb.k8s_api.dns_name
    control_plane_master_private_ip   = var.control_plane_private_ips[0]
    is_first_control_plane            = "true"
  })

  tags = {
    Name = "${terraform.workspace} - Control Plane Node 1"
  }
}

# Wait for master control plane to be fully ready
resource "null_resource" "wait_for_master_ready" {
  depends_on = [aws_instance.control_plane]

  provisioner "remote-exec" {
    inline = [
      templatefile("${path.module}/scripts/wait-for-master.sh.tmpl", {
        common_functions = file("${path.module}/scripts/common-functions.sh")
      })
    ]

    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = tls_private_key.example.private_key_pem
      host                = aws_instance.control_plane["0"].private_ip
      bastion_host        = aws_eip.bastion_eip[0].public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = tls_private_key.example.private_key_pem
      timeout             = "30m"  # Allow enough time for installation
    }
  }

  triggers = {
    instance_id = aws_instance.control_plane["0"].id
  }
}

# Additional control plane nodes (created after master)
resource "aws_instance" "control_plane_secondary" {
  for_each                = { "1" = 1, "2" = 2 }  # Nodes 2 and 3
  
  ami                     = "ami-084568db4383264d4"  # Replace with a Ubuntu 12 AMI ID
  instance_type           = "t3.xlarge"
  key_name                = aws_key_pair.generated_key.key_name
  vpc_security_group_ids  = [aws_security_group.control_plane.id]
  subnet_id               = aws_subnet.private_subnets[each.value].id
  private_ip              = var.control_plane_private_ips[each.value]
  iam_instance_profile    = aws_iam_instance_profile.kubernetes_master.name

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/scripts/init-control-plane.sh.tmpl", {
    common_functions                  = file("${path.module}/scripts/common-functions.sh")
    control_plane_endpoint            = aws_lb.k8s_api.dns_name
    control_plane_master_private_ip   = var.control_plane_private_ips[0]
    is_first_control_plane            = "false"
  })

  depends_on = [null_resource.wait_for_master_ready]

  tags = {
    Name = "${terraform.workspace} - Control Plane Node ${each.value + 1}"
  }
}

resource "aws_instance" "worker_nodes" {
  count                   = 3  # Adjust based on workload needs
  ami                     = "ami-084568db4383264d4"  # Replace with a Ubuntu 12 AMI ID or Debian 12
  instance_type           = "t3.large"
  key_name                = aws_key_pair.generated_key.key_name
  vpc_security_group_ids  = [aws_security_group.worker_node.id]
  
  # Use modulo to distribute worker nodes across available subnets
  subnet_id               = aws_subnet.private_subnets[count.index % length(aws_subnet.private_subnets)].id

  iam_instance_profile    = aws_iam_instance_profile.kubernetes_worker.name

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/scripts/init-worker-node.sh.tmpl", {
    common_functions = file("${path.module}/scripts/common-functions.sh")
  })

  # Wait for at least the master control plane to be ready
  depends_on = [null_resource.wait_for_master_ready]

  tags = {
    Name = "${terraform.workspace} - Worker Node ${count.index + 1}"
  }
}

# Wait for worker nodes to join the cluster
resource "null_resource" "wait_for_workers_to_join" {
  depends_on = [
    aws_instance.worker_nodes,
    aws_instance.control_plane_secondary
  ]

  provisioner "remote-exec" {
    inline = [
      templatefile("${path.module}/scripts/wait-for-workers.sh.tmpl", {
        common_functions  = file("${path.module}/scripts/common-functions.sh")
        expected_workers  = length(aws_instance.worker_nodes)
        timeout_seconds   = 600
        check_interval    = 30
        log_file          = "/var/log/k8s-wait-for-workers-$(date +%Y%m%d-%H%M%S).log"
      })
    ]

    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = tls_private_key.example.private_key_pem
      host                = aws_instance.control_plane["0"].private_ip
      bastion_host        = aws_eip.bastion_eip[0].public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = tls_private_key.example.private_key_pem
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
      templatefile("${path.module}/scripts/label-worker-nodes.sh.tmpl", {
        common_functions      = file("${path.module}/scripts/common-functions.sh")
        expected_worker_count = 3
      })
    ]

    connection {
      type                = "ssh"
      user                = "ubuntu"
      private_key         = tls_private_key.example.private_key_pem
      host                = aws_instance.control_plane["0"].private_ip
      bastion_host        = aws_eip.bastion_eip[0].public_ip
      bastion_user        = "ubuntu"
      bastion_private_key = tls_private_key.example.private_key_pem
    }
  }

  triggers = {
    worker_wait_complete = null_resource.wait_for_workers_to_join.id
  }
}