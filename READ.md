# Rationale

## Resources

For this exercise I have decided to go with serverless for both the Compute and Datastore in order to reduce the security concerns required mainteinance and  by offloading some of those to AWS. 

This can be changed to EC2 for compute if required by the workload that we will be running, in that case we would take some extra measurements such as using encrypted hardened AMIs, using a Configuration Management tool like Ansible or Chef to deploy our baseline tools such as 
Secure Access Service Edge (SASE)


## Terraform

The terraform code is broken down in a file per AWS service so it is easier to navigate, find and manage resources. Values are passed via locals.tf since it makes it easier for managing terraform for multiple AWS accounts in a mono repo, it also integrates easier with CI/CD pipelines. This can easily be converted to variables.tf depending on particular needs. We are also using a naming convention to easily identify resources in the environment. 

A simple tagging strategy isimplemented across all resources so we can enforce compliance based on tags using AWS Config and track cost via AWS Cost Center. Both can be easily modified for all resources in the locals.tf


For creation of the resources in terraform, I went with well known terraform modules wrote and constantly maintained by the community from [terraform-aws-modules](https://registry.terraform.io/namespaces/terraform-aws-modules). This keep us DRY, up to date with latest improvements, and sets safe defaults for those properties we didn't set.

For the terraform backend I would usually go with a S3 hosted backend (unless HashiCorp Cloud Platform is available), but in this case since we can't provision the backend with the same stack (chicken and egg situation) I have left the exercise with a local backend.

## Resources

### VPC

Since we are not sure if there is an existent VPC in the environment, I am provisioning a VPC for the compute resources. In a different case we could use terraform data sources to programatically chose existing network resources based on naming convention or tags.

The network architecture is using the AWS well architected framework:
- Private and public subnets to isolate resources
- NAT gateway to allow the private subnets outbound access to the internet
- Subnets distributed across multiple Availability Zones in case HA is required
- If we were to use Data Bases for data store we could also provision private subnets for these
- VPC Endpoint for S3 keeps the traffic within AWS and reduce costs
- Security Groups for restrictive firewall rules with least privilege access

### IAM

In order to allow Compute resources to access other AWS resources we are provision IAM roles with well defined policies, narrow actions and resource. This follows the least privilege principle.

### S3 
