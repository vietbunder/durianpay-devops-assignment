#Durianpay DevOps Assignment

Instructions
1. Please finish both problems.
2. Make sure you test your code before you submit.
3. Please put the code in GitHub and share the repo link with us (reply on the same email)
4. Please submit the assignment with approx. 24 hours of receiving it.
5. [Optional] Bonus points if we can see results on AWS free tier account.

Problem 1
Write Terraform HCL config to generate AWS infra in the following form:
A. 1 VPC
B. 1 public subnet
C. 1 private subnet connected to 1 NAT Gateway
D. 1 autoscaling group with config:
   a. minimum 2 EC2 t2.medium instances and max 5 instances,
   b. where scaling policy is CPU >= 45%.
   c. instances must be placed on the 1 private subnet created in point C above.
E. Automatically creates CloudWatch monitoring for instance and resource created:
   a. CPU monitoring
   b. memory usage
   c. status check failure
   d. network usage
F. Terraform backend should be stored on S3 bucket.

Problem 2
This second question relates to the CI/CD process.
Write 1 Dockerfile config + 1 CI/CD Pipeline YAML file.
Preferably, the YAML file should be for GitHub CI/CD, but if you are more familiar with other repos e.g., Bitbucket/Gitlab, feel free to use the syntax for those repos. The tasks are:
  A. The YAML file will deploy from a docker image created by a Dockerfile.
  B. The Dockerfile needs to simply install Nginx and put the file from the repo named "hello.txt" into the "/var/www/" folder. Let us assume that folder is the main folder that Nginx will read as a web server.
  C. The Docker image then needs to be installed on an EC2 server on AWS and running.
