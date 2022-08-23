# AWS EKS Terraform module :ghost:

Terraform module which creates a simple public EKS cluster and all supporting resources.

## Usage

```hcl
module "eks" {
  source    = "github.com/stuxcd/terraform-aws-eks"
  # version = ""

  ## required
  cluster_name = "test"

  ## optional
  create_spot_service_linked_role = true
}
```
