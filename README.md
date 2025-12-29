# Multi-AZ-VPC-EC2-Scaling-ALB-Terraform-Project-
AWS Multi-AZ Web Application Infrastructure(Terraform)
Project Overview</br>
This project provisions a highly available AWS web application infrastructure using Terraform. It deploys a custom VPC with public and private subnets across multiple Availability Zones, an Application Load Balancer (ALB), Auto Scaling Group (ASG), NAT Gateway, Bastion Host, and security groups following AWS best practices.
The infrastructure is fully automated using Infrastructure as Code (IaC) and designed for scalability, security, and fault tolerance.

Architecture Summary:</br>
•	Custom VPC (10.0.0.0/16)</br>
•	2 Public Subnets (Multi-AZ)</br>
•	2 Private Subnets (Multi-AZ)</br>
•	Internet Gateway & NAT Gateway</br>
•	Application Load Balancer (ALB)</br>
•	Auto Scaling Group (EC2)</br>
•	Bastion Host for secure access</br>
•	Security Groups with least-privilege access

Step by Step Project Breakdown </br>
Step 1: Ensure a provider for consistent deployments across environments. Created Environmental Variables to provide security for public documentation. 
 
Step 2: Created a VPC  for AWS resources 
-	Serves as the network boundary for all AWS Resurces
 

Step 3: Public and Private Subnets (Multi-AZ)
-	Created 2 public subnet and 2 private subnets
 
Step 4: Internet Gateway and NAT Gateway
-	Created an Internet Gateway to provide Inbound/Outbound internet access to for public subnets
-	Created a NAT Gateway to allow private EC2 access securely
 
Step 5: Route Table Associations 
-	
 
Step 6: Security Groups
-	Created a ALB, Bastion, and Application security group to control access between infrastructure layers.
 
 
Step 8: Bastion Host
-	Created a bastion host to allow SSH access to private EC2 instances
 

Step 9: Application Load Balancer
-	Created an ALB to route HTTP traffic to backend instances
 
Step 10: Target Group
-	Registers EC2 instances from the autoscaling group
 
Step 11: Launch Template
-	Defines EC2 configurations for AMI, Instance Type and security groups
-	Includes user data script that installs Apache, starts a web server, and serves a test html page
 
Step 12: Autoscaling Group 
-	Created an autoscaling group to provide scalability and fault tolerance
-	Desired Capacity - 2
-	Min – 1
-	Max - 3
 
