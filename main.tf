provider "aws" {
  region = "ap-south-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "mon" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  monitoring    = true
  user_data     = <<-EOT
    #!/bin/bash
    echo "*/2 * * * * root timeout 60 sh -c 'while :; do :; done'" > /etc/cron.d/load
  EOT
  tags = {
    Name = "devansh-p21-monitor"
  }
}
resource "aws_cloudwatch_dashboard" "d" {
  dashboard_name = "devansh-p21-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title   = "CPU Utilization"
          region  = "ap-south-1"
          stat    = "Average"
          period  = 60
          metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.mon.id]]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "Network In/Out"
          region = "ap-south-1"
          stat   = "Average"
          period = 60
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.mon.id],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.mon.id]
          ]
        }
      }
    ]
  })
}

output "instance_id" {
  value = aws_instance.mon.id
}
