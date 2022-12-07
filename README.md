# AWS EKS Terraform module :ghost:

Terraform module which creates a simple public EKS cluster and all supporting resources.

## Usage

```hcl
module "eks" {
  source = "github.com/stuxcd/terraform-aws-eks"

  ## required
  cluster_name = "test"

  ## optional
  cluster_version                 = "1.24"
  create_spot_service_linked_role = false
  tags                            = {}
}
```

## Contribute

```bash
# install requirements
make install_reqs

# checkout your branch
git checkout -b branch
# make your changes
git add <files>

# commit changes
pre-commit run --all
cz commit

# test your changes
make test

# push and make PR
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.45.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.7.1 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 1.14.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.16.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ebs_csi_irsa_role"></a> [ebs\_csi\_irsa\_role](#module\_ebs\_csi\_irsa\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | >= 5.3 |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | ~> 18.0 |
| <a name="module_karpenter_irsa_role"></a> [karpenter\_irsa\_role](#module\_karpenter\_irsa\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | >= 5.3 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.karpenter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_service_linked_role.spot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.karpenter_provisioner](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_storage_class.gp2_encrypted](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_kms_key.aws_ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | Expose Kubernetes API in private subnets | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Expose Kubernetes API publicly | `bool` | `false` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Version of the EKS cluster | `string` | `"1.24"` | no |
| <a name="input_create_spot_service_linked_role"></a> [create\_spot\_service\_linked\_role](#input\_create\_spot\_service\_linked\_role) | Indicates whether or not to create the spot.amazonaws.com service linked role | `bool` | `true` | no |
| <a name="input_deploy_karpenter_provisioner"></a> [deploy\_karpenter\_provisioner](#input\_deploy\_karpenter\_provisioner) | Wether to deploy the a default Karpenter provisioner | `bool` | `true` | no |
| <a name="input_karpenter_provisioner_max_cpu"></a> [karpenter\_provisioner\_max\_cpu](#input\_karpenter\_provisioner\_max\_cpu) | The max number of cpu's the default provisioner will deploy | `number` | `40` | no |
| <a name="input_karpenter_provisioner_max_memory"></a> [karpenter\_provisioner\_max\_memory](#input\_karpenter\_provisioner\_max\_memory) | The max memory the default provisioner will deploy | `number` | `80` | no |
| <a name="input_node_volume_size"></a> [node\_volume\_size](#input\_node\_volume\_size) | Volume size of nodes in the cluster in GB | `number` | `40` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | IDs of subnets to deploy cluster into | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of vpc to deploy cluster into | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
