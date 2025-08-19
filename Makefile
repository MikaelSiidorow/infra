.SILENT:

TF=terraform
ANS=ansible-playbook

# Terraform

tf-init:
	cd terraform && $(TF) init

tf-plan:
	cd terraform && $(TF) plan

tf-apply:
	cd terraform && $(TF) apply -auto-approve

tf-destroy:
	cd terraform && $(TF) destroy -auto-approve

# Inventory
inventory:
	bin/make-inventory.sh

# Provision (Ansible)
provision:
	$(ANS) -i ansible/inventory.ini ansible/playbook.yml

# SSH convenience
ssh:
	bin/ssh.sh