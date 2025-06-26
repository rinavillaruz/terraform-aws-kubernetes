# Create the parameter (script will update the value)
resource "aws_ssm_parameter" "join_command" {
  name  = "/k8s/control-plane/join-command"
  type  = "SecureString"
  value = "placeholder-will-be-updated-by-script"
  
  lifecycle {
    ignore_changes = [value]  # Let the script update the value
  }
}