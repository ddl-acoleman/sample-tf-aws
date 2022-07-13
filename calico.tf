resource "null_resource" "calico" {
  provisioner "local-exec" {
    command = "kubectl --kubeconfig ${local_file.kubeconfig.filename} apply -f ${path.module}/k8s_addons/calico.yaml"
  }
}
