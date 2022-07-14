output "autoscaling_group_names" {
  description = "List of compute autoscaling group names that can be added to the Domino installer config"
  value = concat(
    aws_autoscaling_group.compute[*].name,
    aws_autoscaling_group.gpu[*].name
  )
}

output "efs_id" {
  description = "EFS filesystem ID"
  value       = aws_efs_file_system.this.id
}

output "ap_id" {
  description = "EFS access point ID"
  value       = aws_efs_access_point.this.id
}

output "filesystem_id" {
  description = "Installer filesystem ID (EFS & AP)"
  value       = "${aws_efs_file_system.this.id}::${aws_efs_access_point.this.id}"
}

output "kubeconfig" {
  description = "kubeconfig file contents"
  value       = local.kubeconfig
}

output "s3_buckets" {
  description = "S3 bucket names for use with domino"
  value = [
    aws_s3_bucket.blobs_bucket.bucket,
    aws_s3_bucket.logs_bucket.bucket,
    aws_s3_bucket.backups_bucket.bucket,
    aws_s3_bucket.registry_bucket.bucket
  ]
}
