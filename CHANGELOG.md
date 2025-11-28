# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-11-28

### Added
- Support for ROSA Classic and Hosted Control Plane (HCP) architectures
- Network module for VPC, subnets, NAT gateways, and route tables
- IAM roles and OIDC provider configuration
- HTPasswd identity providers for admin and developer users
- Optional bastion host for private cluster access
- Cluster login automation with DNS and API readiness checks
- Optional GitOps operator (OpenShift GitOps) deployment
- Comprehensive Makefile with help system
- Pre-commit checks via `make pr` target
- File numbering scheme for logical execution order
- Agent helper files (`.cursorrules`, `.claude-directives`, `.copilot-instructions.md`)
- Project documentation in `AGENTS.md`
- Apache 2.0 license

### Changed
- Modernized Terraform provider versions (AWS ~> 6.0, RHCS ~> 1.7)
- Updated Terraform version requirement to >= 1.5.0
- Improved error handling and retry logic in cluster login scripts
- Enhanced Makefile with better error messages and environment variable handling
- Default to HCP clusters (`TF_VAR_hosted_control_plane=true`)

### Fixed
- Fixed hostname extraction in cluster login scripts
- Fixed bastion security group to conditionally allow SSH
- Fixed deprecation warnings in networking module
- Improved shell variable escaping in provisioner scripts

### Security
- Added validation to prevent GitOps deployment on private clusters
- Improved password and token handling with sensitive variables

[Unreleased]: https://github.com/rh-mobb/terraform-rosa/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/rh-mobb/terraform-rosa/releases/tag/v1.0.0
