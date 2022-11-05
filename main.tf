#
#  Provider Statement and Controller Config. 
#

provider "aviatrix" {
  controller_ip = "YOURcontrollersIPaddressHERE"
    username = "admin"
    password = "YOURcontrollersPASSWORDhere"
    skip_version_validation = true
}

#
#  S3 Bucket / Bootstrap Files / IAM role/policy creation for FireNet  
#

resource "random_string" "bucket" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "bootstrap" {
  bucket = "panw-bootstrap-terraform-${random_string.bucket.result}"
}

resource "aws_s3_bucket_acl" "bootstrap_acl" {
  bucket = aws_s3_bucket.bootstrap.id
  acl    = "private"
}

resource "aws_s3_object" "folder_config" {
  bucket = aws_s3_bucket.bootstrap.id
  key    = "config/"
  source = "/dev/null"
}

resource "aws_s3_object" "folder_content" {
  bucket = aws_s3_bucket.bootstrap.id
  key    = "content/"
  source = "/dev/null"
}

resource "aws_s3_object" "folder_license" {
  bucket = aws_s3_bucket.bootstrap.id
  key    = "license/"
  source = "/dev/null"
}

resource "aws_s3_object" "folder_software" {
  bucket = aws_s3_bucket.bootstrap.id
  key    = "software/"
  source = "/dev/null"
}

resource "aws_s3_object" "xml" {
  bucket = aws_s3_bucket.bootstrap.id
  key    = "config/bootstrap.xml"
  source = "config/bootstrap.xml"
}

resource "aws_s3_object" "init" {
  bucket = aws_s3_bucket.bootstrap.id
  key    = "config/init-cfg.txt"
  source = "config/init-cfg.txt"
}

#
#Create IAM role and policy for the FW instance to access the bucket.
#

resource "aws_iam_role" "bootstrap" {
  name               = "bootstrap-terraform"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "bootstrap" {
  name   = "bootstrap-terraform"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "policy_role" {
  role       = aws_iam_role.bootstrap.name
  policy_arn = aws_iam_policy.bootstrap.arn
}

resource "aws_iam_instance_profile" "instance_role" {
  name = "bootstrap-terraform"
  role = aws_iam_role.bootstrap.name
}

#
#  Transit Architecture code begins // 3 Transits \ 3 Firenets \ 3 Transit Peerings 
#


module "mc_transit-1" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "v2.3.0"

  cloud                  = "AWS"
  cidr                   = "10.10.0.0/23"
  region                 = "us-west-2"
  account                = "AWS"
  enable_transit_firenet = true
  name = "Non-Prod-AVX-Tranist-01"
  gw_name = "TransitGW-1"
  insane_mode   = true
  instance_size = "c5n.2xlarge"


}

module "firenet_1" {
  source  = "terraform-aviatrix-modules/mc-firenet/aviatrix"
  version = "v1.3.0"

  transit_module = module.mc_transit-1
  firewall_image = "Palo Alto Networks VM-Series Next-Generation Firewall Bundle 1"
  bootstrap_bucket_name_1 = aws_s3_bucket.bootstrap.bucket
  fw_amount = "2"
  iam_role_1 = aws_iam_role.bootstrap.name
      
}

module "mc_transit-2" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "v2.3.0"

  cloud                  = "AWS"
  cidr                   = "10.20.0.0/23"
  region                 = "us-east-2"
  account                = "AWS"
  enable_transit_firenet = true
  name = "Non-Prod-AVX-Tranist-02"
  gw_name = "TransitGW-2"
  insane_mode   = true
  instance_size = "c5n.2xlarge"
}

module "firenet_2" {
  source  = "terraform-aviatrix-modules/mc-firenet/aviatrix"
  version = "v1.3.0"

  transit_module = module.mc_transit-2
  firewall_image = "Palo Alto Networks VM-Series Next-Generation Firewall Bundle 1"
  bootstrap_bucket_name_1 = aws_s3_bucket.bootstrap.bucket
  fw_amount = "2"
  iam_role_1 = aws_iam_role.bootstrap.name
}

module "mc_transit-3" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "v2.3.0"

  cloud                  = "AWS"
  cidr                   = "10.30.0.0/23"
  region                 = "us-east-1"
  account                = "AWS"
  enable_transit_firenet = true
  name = "Non-Prod-AVX-Tranist-03"
  gw_name = "TransitGW-3"
  insane_mode   = true
  instance_size = "c5n.2xlarge"
}

module "firenet_3" {
  source  = "terraform-aviatrix-modules/mc-firenet/aviatrix"
  version = "v1.3.0"

  transit_module = module.mc_transit-3
  firewall_image = "Palo Alto Networks VM-Series Next-Generation Firewall Bundle 1"
  bootstrap_bucket_name_1 = aws_s3_bucket.bootstrap.bucket
  fw_amount = "2"
  iam_role_1 = aws_iam_role.bootstrap.name
}

resource "aviatrix_transit_gateway_peering" "transit_gateway_peering_1-2" {
  transit_gateway_name1                       = module.mc_transit-1.transit_gateway.gw_name
  transit_gateway_name2                       = module.mc_transit-2.transit_gateway.gw_name
}

resource "aviatrix_transit_gateway_peering" "transit_gateway_peering_2-3" {
  transit_gateway_name1                       = module.mc_transit-2.transit_gateway.gw_name
  transit_gateway_name2                       = module.mc_transit-3.transit_gateway.gw_name
}

resource "aviatrix_transit_gateway_peering" "transit_gateway_peering_3-1" {
  transit_gateway_name1                       = module.mc_transit-3.transit_gateway.gw_name
  transit_gateway_name2                       = module.mc_transit-1.transit_gateway.gw_name
}

#
#  Aviatrix FireNet Vendor Integration Data Source. This is where it gets a little messy. The data blocks below MUST be commented out 
#  while the above code runs. Dennis and team have specified this until he figures out how to do them together. 
#

data "aviatrix_firenet_vendor_integration" "transit1_fw1" {
  vpc_id        = module.mc_transit-1.transit_gateway.vpc_id
  instance_id   = module.firenet_1.aviatrix_firewall_instance[0].id
  vendor_type   = "Palo Alto Networks VM-Series"
  public_ip     = module.firenet_1.aviatrix_firewall_instance[0].public_ip
  username      = "avxadmin"
  password      = "Aviatrix123#"
  firewall_name = module.firenet_1.aviatrix_firewall_instance[0].firewall_name
  save          = true
}

data "aviatrix_firenet_vendor_integration" "transit1_fw2" {
  vpc_id        = module.mc_transit-1.transit_gateway.vpc_id
  instance_id   = module.firenet_1.aviatrix_firewall_instance[1].id
  vendor_type   = "Palo Alto Networks VM-Series"
  public_ip     = module.firenet_1.aviatrix_firewall_instance[1].public_ip
  username      = "avxadmin"
  password      = "Aviatrix123#"
  firewall_name = module.firenet_1.aviatrix_firewall_instance[1].firewall_name
  save          = true
}

data "aviatrix_firenet_vendor_integration" "transit2_fw1" {
  vpc_id        = module.mc_transit-2.transit_gateway.vpc_id
  instance_id   = module.firenet_2.aviatrix_firewall_instance[0].id
  vendor_type   = "Palo Alto Networks VM-Series"
  public_ip     = module.firenet_2.aviatrix_firewall_instance[0].public_ip
  username      = "avxadmin"
  password      = "Aviatrix123#"
  firewall_name = module.firenet_2.aviatrix_firewall_instance[0].firewall_name
  save          = true
}

data "aviatrix_firenet_vendor_integration" "transit2_fw2" {
  vpc_id        = module.mc_transit-2.transit_gateway.vpc_id
  instance_id   = module.firenet_2.aviatrix_firewall_instance[1].id
  vendor_type   = "Palo Alto Networks VM-Series"
  public_ip     = module.firenet_2.aviatrix_firewall_instance[1].public_ip
  username      = "avxadmin"
  password      = "Aviatrix123#"
  firewall_name = module.firenet_2.aviatrix_firewall_instance[1].firewall_name
  save          = true
}
data "aviatrix_firenet_vendor_integration" "transit3_fw1" {
  vpc_id        = module.mc_transit-3.transit_gateway.vpc_id
  instance_id   = module.firenet_3.aviatrix_firewall_instance[0].id
  vendor_type   = "Palo Alto Networks VM-Series"
  public_ip     = module.firenet_3.aviatrix_firewall_instance[0].public_ip
  username      = "avxadmin"
  password      = "Aviatrix123#"
  firewall_name = module.firenet_3.aviatrix_firewall_instance[0].firewall_name
  save          = true
}

data "aviatrix_firenet_vendor_integration" "transit3_fw2" {
  vpc_id        = module.mc_transit-3.transit_gateway.vpc_id
  instance_id   = module.firenet_3.aviatrix_firewall_instance[1].id
  vendor_type   = "Palo Alto Networks VM-Series"
  public_ip     = module.firenet_3.aviatrix_firewall_instance[1].public_ip
  username      = "avxadmin"
  password      = "Aviatrix123#"
  firewall_name = module.firenet_3.aviatrix_firewall_instance[1].firewall_name
  save          = true
}


provider "aviatrix" {
  controller_ip = "YOURcontrollersIPaddressHERE"
    username = "admin"
    password = "YOURcontrollersPASSWORDhere"
    skip_version_validation = true
}
