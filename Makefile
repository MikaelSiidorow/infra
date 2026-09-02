.SILENT:

TF=terraform
HESTIA_HOST ?= hestia.home.arpa
HESTIA_SSH := mikaelsiidorow@$(HESTIA_HOST)
HESTIA_REPO ?= /etc/nixos-repo

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

.PHONY: deploy-cerberus
deploy-cerberus:
	ssh -t $(HESTIA_SSH) "systemd-run --user --wait --pipe --collect --unit=deploy-cerberus /run/current-system/sw/bin/bash -lc 'cd $(HESTIA_REPO) && git pull --ff-only && nix run .#cerberus-deploy'"

.PHONY: deploy-hermes
deploy-hermes:
	ssh -t $(HESTIA_SSH) "systemd-run --user --wait --pipe --collect --unit=deploy-hermes /run/current-system/sw/bin/bash -lc 'cd $(HESTIA_REPO) && git pull --ff-only && nix run .#hermes-deploy'"

.PHONY: build-router-firmware
build-router-firmware:
	nix build .\#cerberus-firmware .\#hermes-firmware --no-link
