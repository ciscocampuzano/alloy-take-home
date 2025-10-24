# Rationale

## Terraform

The terraform code is broken down in a file per AWS service so it us easier to navigate and find resources. Values are passed via locals.tf since it makes it easier for managing terraform for multiple AWS accounts in a mono repo and integrate with automation. This can easily be converted to variables.tf depending on particular needs.

For this exercise I have decided to go with serverless for both the Compute and Datastore in order to reduce the required mainteinance and security by offloading some of those to AWS services. 

For creation of the resources in terraform, I went with well knonw terraform modules wrote and constantly mainteinaded by the community from [terraform-aws-modules](https://registry.terraform.io/namespaces/terraform-aws-modules). This keep us DRY, up to date with latest improvements, and sets safe defaults for those properties we didn't set.

For the terraform backend I would usually go with a S3 hosted backend (unless HashiCorp Cloud Platform is available), but in this case since we can't provision the backend with the same stack (chicken and egg situation) so I have left the exercise with a local terraform state.

## Resources

### VPC

Since we are not sure if there is an existent VPC in the environment, I am provisioning a VPC for the compute resources. In a different case we could use terraform data sources to programatically chose existing network resources based on naming convention or tags.

The network architecture is using the aws well architected framework:
- private and public subnets to isolate resources
- NAT gateway to allow the private subnets outbound access to the internet
- Subnets distributed across multiple Availability Zones in case HA is required
- If we were to use Data Bases for data store we could also provision private subnets for these

### IAM

In order to allow Compute resources to access other AWS resources we are provision IAM roles with well defined policies, narrow actions and resource following the least privilege principle.

### 
