resource "local_file" "kubeconfig" {
  content         = local.kubeconfig
  filename        = var.kubeconfig_output_path != "" ? var.kubeconfig_output_path : "${path.cwd}/eks-kubeconfig"
  file_permission = "0644"
}
