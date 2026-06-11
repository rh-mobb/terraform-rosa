# Apply the default Karpenter EC2NodeClass and NodePool to the cluster via oc CLI.
# Only runs for public HCP clusters — private clusters require manual application
# of these manifests after cluster creation.
resource "terraform_data" "karpenter_ec2nodeclass" {
  count = var.karpenter && var.hosted_control_plane && !var.private ? 1 : 0

  triggers_replace = {
    cluster_id   = local.cluster_id
    cluster_name = local.cluster_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "Applying default Karpenter EC2NodeClass..."
      cat <<EOF | oc apply -f -
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  # Use the ROSA-managed AMI — always pinned to the approved OpenShift node image
  amiSelectorTerms:
    - alias: custom@latest
  # Target the private subnets created by this module
  subnetSelectorTerms:
    - tags:
        kubernetes.io/cluster/${local.cluster_name}: shared
  # Use the cluster security groups
  securityGroupSelectorTerms:
    - tags:
        kubernetes.io/cluster/${local.cluster_name}: owned
  # IAM role assigned to Karpenter-provisioned nodes
  role: ${local.cluster_name}-HCP-ROSA-Worker-Role
EOF
      echo "EC2NodeClass applied successfully"
    EOT
  }

  depends_on = [
    terraform_data.cluster_nodes_ready[0]
  ]
}

resource "terraform_data" "karpenter_nodepool" {
  count = var.karpenter && var.hosted_control_plane && !var.private ? 1 : 0

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
    spec:
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
