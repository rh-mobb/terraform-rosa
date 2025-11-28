# Local variable to determine if cluster login should be performed
# Login is only needed when deploying GitOps to a public cluster
locals {
  should_perform_cluster_login = var.deploy_gitops && !var.private
}

# Validate that cluster login requirements are met
check "cluster_login_requirements" {
  assert {
    condition     = !var.deploy_gitops || !var.private
    error_message = "Cluster login is required for GitOps deployment but is not supported for private clusters. Set 'private=false' or 'deploy_gitops=false'."
  }
}

# Step 1: Wait for DNS to be resolvable
resource "terraform_data" "cluster_dns_ready" {
  count = local.should_perform_cluster_login ? 1 : 0

  input = {
    cluster_id   = local.cluster_id
    cluster_name = local.cluster_name
    api_url      = local.cluster_api_url
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e

      # Extract hostname from API URL for DNS resolution check
      api_hostname=$(echo ${local.cluster_api_url} | cut -d'/' -f3 | cut -d':' -f1)

      echo "Waiting for cluster DNS to be resolvable ($api_hostname)..."
      dns_timeout=300
      dns_elapsed=0
      while [ $dns_elapsed -lt $dns_timeout ]; do
        if host $api_hostname >/dev/null 2>&1 || nslookup $api_hostname >/dev/null 2>&1 || getent hosts $api_hostname >/dev/null 2>&1; then
          echo "DNS is resolvable"
          exit 0
        fi
        echo "Waiting for DNS resolution... ($dns_elapsed s / $dns_timeout s)"
        sleep 10
        dns_elapsed=$((dns_elapsed + 10))
      done

      echo "ERROR: DNS resolution failed for $api_hostname"
      exit 1
    EOT
  }

  depends_on = [
    rhcs_cluster_rosa_classic.rosa,
    rhcs_cluster_rosa_hcp.rosa
  ]
}

# Step 2: Wait for cluster API to be accessible
resource "terraform_data" "cluster_api_accessible" {
  count = local.should_perform_cluster_login ? 1 : 0

  input = {
    cluster_id   = local.cluster_id
    cluster_name = local.cluster_name
    api_url      = local.cluster_api_url
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e

      echo "Waiting for cluster API to be accessible..."
      api_timeout=300
      api_elapsed=0
      while [ $api_elapsed -lt $api_timeout ]; do
        http_code=$(curl -k -s -o /dev/null -w "%%{http_code}" ${local.cluster_api_url}/healthz 2>/dev/null || echo "000")
        if [ "$http_code" = "200" ]; then
          echo "Cluster API is accessible"
          exit 0
        fi
        echo "Waiting for cluster API... ($api_elapsed s / $api_timeout s)"
        sleep 10
        api_elapsed=$((api_elapsed + 10))
      done

      echo "ERROR: Cluster API not accessible after timeout"
      exit 1
    EOT
  }

  depends_on = [
    terraform_data.cluster_dns_ready[0]
  ]
}

# Step 3: Login to cluster
resource "terraform_data" "cluster_login" {
  count = local.should_perform_cluster_login ? 1 : 0

  input = {
    cluster_id   = local.cluster_id
    cluster_name = local.cluster_name
    api_url      = local.cluster_api_url
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e

      # Wait a bit for identity provider to be fully ready
      echo "Waiting for identity provider to be ready..."
      sleep 30

      # Retry login with exponential backoff
      echo "Logging into cluster ${local.cluster_name}..."
      max_attempts=5
      attempt=1
      while [ $attempt -le $max_attempts ]; do
        if oc login ${local.cluster_api_url} \
          --username ${local.admin_username} \
          --password ${var.admin_password} \
          --insecure-skip-tls-verify=false 2>/dev/null; then
          echo "Cluster login successful!"
          exit 0
        fi

        if [ $attempt -eq $max_attempts ]; then
          echo "ERROR: Failed to login after $max_attempts attempts"
          echo "This may indicate the identity provider is not ready or credentials are incorrect"
          exit 1
        fi

        echo "Login attempt $attempt failed, retrying in $((attempt * 10)) seconds..."
        sleep $((attempt * 10))
        attempt=$((attempt + 1))
      done
    EOT
  }

  depends_on = [
    terraform_data.cluster_api_accessible[0],
    rhcs_identity_provider.admin
  ]
}

# Step 4: Wait for cluster nodes to be ready
resource "terraform_data" "cluster_nodes_ready" {
  count = local.should_perform_cluster_login ? 1 : 0

  input = {
    cluster_id   = local.cluster_id
    cluster_name = local.cluster_name
    api_url      = local.cluster_api_url
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e

      echo "Waiting for cluster nodes to be ready..."
      oc wait --for=condition=Ready nodes --all --timeout=600s || exit 1
      echo "All cluster nodes are ready!"
    EOT
  }

  depends_on = [
    terraform_data.cluster_login[0]
  ]
}
