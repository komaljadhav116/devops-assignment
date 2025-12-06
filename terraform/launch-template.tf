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

# Install Node.js 18 and Git via dnf
dnf module reset nodejs -y
dnf module enable nodejs:18 -y
dnf install -y nodejs git

# Install and start SSM agent
dnf install -y amazon-ssm-agent
systemctl enable --now amazon-ssm-agent

# Install CloudWatch Agent
dnf install -y amazon-cloudwatch-agent
systemctl enable --now amazon-cloudwatch-agent

# Setup application
mkdir -p /opt/app
cd /opt/app
git clone https://github.com/komaljadhav116/devops-assignment.git
cd devops-assignment/app
npm install

# Create systemd service for Node.js app
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
StandardOutput=journal
StandardError=journal

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
