resource "aws_efs_file_system" "this" {
  tags = {
    Name = var.name
  }
}

resource "aws_efs_access_point" "this" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    uid = 0
    gid = 0
  }

  root_directory {
    path = "/domino"

    creation_info {
      owner_uid   = 0
      owner_gid   = 0
      permissions = "777"
    }
  }

  tags = {
    Name = var.name
  }
}

resource "aws_efs_mount_target" "this" {
  count = var.private_subnet_count

  subnet_id       = aws_subnet.private[count.index].id
  file_system_id  = aws_efs_file_system.this.id
  security_groups = [aws_security_group.nodes.id]
}
