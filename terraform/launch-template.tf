resource "aws_launch_template" "template" {
  name_prefix   = "hello-api-"
  image_id      = "ami-0d176f79571d18a8f" 
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm_profile.name
  }

 user_data = base64encode(<<EOF
#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -x

# Update system
dnf update -y

# Install Node.js 18 and Git
dnf module reset nodejs -y
dnf module enable nodejs:18 -y
dnf install -y nodejs git

# Install and start SSM agent
dnf install -y amazon-ssm-agent
systemctl enable --now amazon-ssm-agent

# Install CloudWatch Agent
dnf install -y amazon-cloudwatch-agent
systemctl enable --now amazon-cloudwatch-agent

# Create CloudWatch Agent configuration
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cat << 'EOT' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/nodeapp/user-data",
            "log_stream_name": "{instance_id}",
            "timestamp_format": "%Y-%m-%d %H:%M:%S"
          },
          {
            "file_path": "/opt/app/devops-assignment/app/logs/app.log",
            "log_group_name": "/nodeapp/app-logs",
            "log_stream_name": "{instance_id}",
            "timestamp_format": "%Y-%m-%d %H:%M:%S"
          }
        ]
      }
    }
  }
}
EOT

# Start CloudWatch Agent with new configuration
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Application setup
mkdir -p /opt/app
cd /opt/app
git clone https://github.com/komaljadhav116/devops-assignment.git
cd devops-assignment/app
npm install

# Create systemd service for Node.js app
mkdir -p logs

cat << 'EOT' > /etc/systemd/system/nodeapp.service
[Unit]
Description=Node.js Hello API
After=network.target

[Service]
ExecStart=/usr/bin/npm start
WorkingDirectory=/opt/app/devops-assignment/app
Restart=always
Environment=PORT=8080
User=root
StandardOutput=append:/opt/app/devops-assignment/app/logs/app.log
StandardError=append:/opt/app/devops-assignment/app/logs/app.log

[Install]
WantedBy=multi-user.target
EOT

# Enable and start Node.js service
systemctl daemon-reload
systemctl enable --now nodeapp

EOF
)


  network_interfaces {
    security_groups             = [aws_security_group.ec2_sg.id]
    associate_public_ip_address = false
  }
}
