output "bastion_security_group_id" {
  value = aws_security_group.bastion.id
}

output "control_plane_security_group_id" {
  value = aws_security_group.control_plane.id
}

output "worker_node_security_group_id" {
  value = aws_security_group.worker_node.id
}