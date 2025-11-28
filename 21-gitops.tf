# Deploy GitOps operator using oc CLI (avoids Kubernetes provider interpolation issue)
resource "terraform_data" "gitops_operator" {
  count = var.deploy_gitops ? 1 : 0

  # Trigger when cluster is ready
  input = {
    cluster_id   = local.cluster_id
    cluster_name = local.cluster_name
    api_url      = local.cluster_api_url
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e

      # Create namespace for GitOps
      echo "Creating openshift-gitops namespace..."
      oc create namespace openshift-gitops-operator --dry-run=client -o yaml | oc apply -f - || exit 1

      # Install GitOps operator via OperatorHub
      echo "Installing GitOps operator..."
      cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-gitops-operator-rg
  namespace: openshift-gitops-operator
spec:
  upgradeStrategy: Default
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-gitops-operator
  namespace: openshift-gitops-operator
spec:
  channel: latest
  installPlanApproval: Automatic
  name: openshift-gitops-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

      # Wait for operator to be installed
      echo "Waiting for GitOps operator to be installed..."
      # Wait for subscription to have installedCSV set
      timeout=600
      elapsed=0
      while [ $elapsed -lt $timeout ]; do
        installed_csv=$(oc get subscription openshift-gitops-operator -n openshift-gitops-operator -o jsonpath='{.status.installedCSV}' 2>/dev/null || echo "")
        if [ -n "$installed_csv" ]; then
          echo "Subscription has installedCSV: $installed_csv"
          break
        fi
        echo "Waiting for subscription to install CSV... elapsed: $elapsed s, timeout: $timeout s"
        sleep 5
        elapsed=$((elapsed + 5))
      done

      if [ -z "$installed_csv" ]; then
        echo "ERROR: Subscription did not install CSV within timeout"
        exit 1
      fi

      # Wait for CSV to be in Succeeded phase
      echo "Waiting for CSV $installed_csv to be in Succeeded phase..."
      oc wait --for=jsonpath='{.status.phase}'=Succeeded csv/$installed_csv -n openshift-gitops-operator --timeout=600s || exit 1

      echo "GitOps operator installed successfully!"
    EOT
  }

  depends_on = [
    terraform_data.cluster_nodes_ready[0]
  ]
}
