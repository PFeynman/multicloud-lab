data "aws_iam_policy_document" "s3_access_definition" {
  statement {
    sid = "1"

    actions = [
      "s3:*"
    ]

    resources = [
      "*",
      "arn:aws:s3:::*",
      "arn:aws:s3:::*/*"
    ]
  }

}

resource "aws_iam_policy" "s3_access" {
  name        = "s3_access"
  description = "Policy to allow access to S3 buckets for the multicloud lab VM."

  policy = data.aws_iam_policy_document.s3_access_definition.json
}

resource "aws_iam_role" "multicloud_lab_vm_role" {
  name = "multicloud-lab-vm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_attachment" {
  role       = aws_iam_role.multicloud_lab_vm_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role" "multicloud_lab_gcp_vm_role" {
  name = "multicloud-lab-gcp-vm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow",
        Principal = { "Federated" : "accounts.google.com" },
        Action    = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "accounts.google.com:aud" : "${google_service_account.multicloud_lab_vm_sa.unique_id}",
            "accounts.google.com:oaud" : "urn:multicloud-lab:gcp-to-aws:s3",
            "accounts.google.com:sub" : "${google_service_account.multicloud_lab_vm_sa.unique_id}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "gcp_s3_access_attachment" {
  role       = aws_iam_role.multicloud_lab_gcp_vm_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}
