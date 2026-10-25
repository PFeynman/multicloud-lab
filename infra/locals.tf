locals {
  aws_region              = "eu-west-2"
  aws_profile             = "multicloud-lab"
  aws_az                  = "eu-west-2a"
  aws_vpc_cidr            = "10.10.0.0/16"
  aws_private_subnet_cidr = "10.10.0.0/24"
  aws_vm_ip               = "10.10.0.10"
  aws_asn                 = 65433

  gcp_project             = "multicloud-lab-prp"
  gcp_region              = "europe-west2"
  gcp_zone                = "europe-west2-a"
  gcp_private_subnet_cidr = "10.30.0.0/24"
  gcp_vm_ip               = "10.30.0.10"
  gcp_asn                 = 65432
}