package test

import (
	"context"
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// This is a complicated, end-to-end integration test. It builds the AMI from examples/packer-docker-example,
// deploys it using the Terraform code on examples/terraform-packer-example, and checks that the web server in the AMI
// response to requests. The test is broken into "stages" so you can skip stages by setting environment variables (e.g.,
// skip stage "build_ami" by setting the environment variable "SKIP_build_ami=true"), which speeds up iteration when
// running this test over and over again locally.
func TestTerraformAwsEks(t *testing.T) {
	t.Parallel()

	// The folder where we have our Terraform code
	workingDir := "../examples/test"

	// At the end of the test, undeploy the web app using Terraform
	defer test_structure.RunTestStage(t, "cleanup_terraform", func() {
		undeployUsingTerraform(t, workingDir)
	})

	// Deploy the cluster using Terraform
	test_structure.RunTestStage(t, "deploy_terraform", func() {
		awsRegion := aws.GetRandomStableRegion(t, []string{"eu-west-2", "eu-west-1"}, nil)
		test_structure.SaveString(t, workingDir, "awsRegion", awsRegion)
		deployUsingTerraform(t, awsRegion, workingDir)
	})

	// Validate that the cluster is deployed and is responsive
	test_structure.RunTestStage(t, "validate_cluster", func() {
		awsRegion := test_structure.LoadString(t, workingDir, "aws")
		validateClusterRunning(t, awsRegion, workingDir)
	})
}

// Deploy the terraform-packer-example using Terraform
func deployUsingTerraform(t *testing.T, awsRegion string, workingDir string) {
	t.Logf("Running in aws region: %s", awsRegion)

	// a unique cluster ID so we won't clash with anything already in the AWS account
	clusterID := fmt.Sprintf("terratest-%s", random.UniqueId())
	test_structure.SaveString(t, workingDir, "cluster_id", clusterID)

	// Some AWS regions are missing certain instance types, so pick an available type based on the region we picked
	instanceType := aws.GetRecommendedInstanceType(t, awsRegion, []string{"t3.medium", "t2.medium"})

	// Construct the terraform options with default retryable errors to handle the most common retryable errors in
	// terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: workingDir,

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"aws_region":               awsRegion,
			"cluster_name":             clusterID,
			"node_group_instance_type": instanceType,
		},
	})

	// Save the Terraform Options struct, instance name, and instance text so future test stages can use it
	test_structure.SaveTerraformOptions(t, workingDir, terraformOptions)

	// This will run `terraform init` and `terraform apply` and fail the test if there are any errors
	terraform.InitAndApply(t, terraformOptions)
}

// Undeploy the terraform-aws-eks deployment using Terraform
func undeployUsingTerraform(t *testing.T, workingDir string) {
	// Load the Terraform Options saved by the earlier deploy_terraform stage
	terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)

	terraform.Destroy(t, terraformOptions)
}

// Validate the web server has been deployed and is working
func validateClusterRunning(t *testing.T, awsRegion string, workingDir string) {
	// Load the Terraform Options saved by the earlier deploy_terraform stage
	terraformOptions := test_structure.LoadTerraformOptions(t, workingDir)

	expectedClusterID := test_structure.LoadString(t, workingDir, "cluster_id")

	// Run `terraform output` to get the value of an output variable
	clusterID := terraform.Output(t, terraformOptions, "eks_cluster_id")
	t.Log("Asserting cluster id")
	assert.Equal(t, clusterID, expectedClusterID)

	t.Log("Getting clientset")
	// Get Kubernetes client set to verify responsiveness
	clientset, err := newEksClientset(clusterID, awsRegion)
	if err != nil {
		t.Errorf("Error getting EKS client set: %v", err)
	}
	t.Log("Getting nodes")
	// Run query on nodes
	nodes, err := clientset.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		t.Errorf("Error getting EKS nodes: %v", err)
	}
	t.Log("Asserting nodes")
	assert.Equal(t, len(nodes.Items), 1)
}
