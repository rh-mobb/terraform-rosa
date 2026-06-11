# Apply the default Karpenter EC2NodeClass and NodePool to the cluster via oc CLI.
# For private clusters, Terraform must have network access to the cluster API — either
# by running from within the VPC, or by routing through the bastion with sshuttle.
resource "terraform_data" "karpenter_ec2nodeclass" {
  count = var.karpenter && var.hosted_control_plane ? 1 : 0

  triggers_replace = {
    cluster_id   = local.cluster_id
    cluster_name = local.cluster_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "Applying default Karpenter EC2NodeClass..."
      cat <<EOF | oc apply -f -
apiVersion: karpenter.hypershift.openshift.io/v1
kind: OpenshiftEC2NodeClass
metadata:
  name: default
spec:
  # Subnet and security group selectors are optional — ROSA AutoNode populates
  # them automatically using karpenter.sh/discovery and cluster ID tags.
  # Omitting them here lets ROSA manage the correct selectors automatically.
EOF
      echo "OpenshiftEC2NodeClass applied successfully"
    EOT
  }

  depends_on = [
    terraform_data.cluster_nodes_ready[0]
  ]
}

resource "terraform_data" "karpenter_nodepool" {
  count = var.karpenter && var.hosted_control_plane ? 1 : 0

  triggers_replace = {
    cluster_id   = local.cluster_id
    cluster_name = local.cluster_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "Applying default Karpenter NodePool..."
      cat <<EOF | oc apply -f -
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    metadata:
      labels:
        autonode: "true"
    spec:
      # nodeClassRef must point to karpenter.k8s.aws/EC2NodeClass — ROSA creates this
      # automatically from the OpenshiftEC2NodeClass via a sync controller.
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: default
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64", "arm64"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: karpenter.k8s.aws/instance-category
          operator: In
          values: ["c", "m", "r"]
        - key: karpenter.k8s.aws/instance-generation
          operator: Gt
          values: ["5"]
  # Guardrail — stop provisioning after 1000 CPU cores across all Karpenter nodes
  limits:
    cpu: 1000
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 30s
EOF
      echo "NodePool applied successfully"
    EOT
  }

  depends_on = [
    terraform_data.karpenter_ec2nodeclass[0]
  ]
}
