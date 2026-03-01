.SILENT:

TF=terraform

# Terraform

tf-init:
	cd terraform && $(TF) init

tf-plan:
	cd terraform && $(TF) plan

tf-apply:
	cd terraform && $(TF) apply -auto-approve

tf-destroy:
	cd terraform && $(TF) destroy -auto-approve

# SSH convenience
ssh:
	bin/ssh.sh