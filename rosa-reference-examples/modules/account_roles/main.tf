#
# Copyright (c) 2022 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

data "rhcs_policies" "all_policies" {}

data "rhcs_versions" "all" {}

module "create_account_roles"{
  source  = "terraform-redhat/rosa-sts/aws"
  version = "0.0.15"  

  count = var.create_account_roles ? 1 : 0

  create_account_roles = true

  account_role_prefix      = var.account_role_prefix
  path                     = var.path
  ocm_environment          = var.ocm_environment
  rosa_openshift_version   = regex("^[0-9]+\\.[0-9]+", var.rosa_openshift_version)
  account_role_policies    = data.rhcs_policies.all_policies.account_role_policies
  all_versions             = data.rhcs_versions.all
  operator_role_policies   = data.rhcs_policies.all_policies.operator_role_policies
  tags                     = var.additional_tags

}
