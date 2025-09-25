# OpenStack Instance Generation Template

This is a Terraform project intended to generate an instance on OpenStack, using variables and modules for flexibility. The goal is to make it easy to create and manage instances across different environments.

## Prerequisites

1. **Terraform**: Ensure Terraform is installed on your machine.
2. **OpenStack Credentials**: You need valid OpenStack credentials including `OS_AUTH_URL`, `OS_USERNAME`, `OS_PASSWORD`, `OS_PROJECT_NAME`, and `OS_REGION_NAME`.
3. **SSH Key Pair**: A public SSH key pair that you want to use for the instance.

## Getting Started

1. **Clone the Repository**:
   