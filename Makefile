VAULT_FILES=ansible/inventory/group_vars/*/secrets/*.yml
VAULT_ID=default@.vault_pass

# Dev
dev.install:
	rye sync

dev.docs:
	mdbook serve docs --open

# Ansible
ansible.install:
	cd ansible && ansible-galaxy install -r requirements.yml -f

ansible.nas:
	cd ansible && ansible-playbook playbooks/nas.yml

# Docker
docker.nas.up:
	cd docker && docker compose up -d nas

docker.nas.up.build:
	cd docker && docker compose up -d nas --build

docker.nas.restart:
	cd docker && docker rm -f nas && docker compose up -d nas

docker.nas.destroy:
	cd docker && docker rm -f nas

docker.nas.provision:
	cd docker && ansible-playbook --extra-vars "@./ansible-extra-vars.yml" --vault-id default@../.vault_pass playbooks/nas.yml

# Vagrant
vagrant.cluster.up:
	cd vagrant && VAGRANT_DISABLE_STRICT_DEPENDENCY_ENFORCEMENT=1 vagrant up cluster-node1 cluster-node2 cluster-node3 cluster-node4

vagrant.cluster.provision:
	cd vagrant && vagrant provision cluster-node1 cluster-node2 cluster-node3 cluster-node4

vagrant.cluster.restart: vagrant.destroy vagrant.cluster.up

vagrant.nas.up:
	cd vagrant && VAGRANT_DISABLE_STRICT_DEPENDENCY_ENFORCEMENT=1 vagrant up nas-archlinux

vagrant.nas.provision:
	cd vagrant && vagrant provision nas-archlinux

vagrant.nas.restart: vagrant.destroy vagrant.nas.up

vagrant.reload:
	cd vagrant && vagrant reload

vagrant.destroy:
	cd vagrant && vagrant destroy -f

# Terraform
terraform.init:
	cd terraform/$(WS) && \
	terraform init

terraform.plan:
	cd terraform/$(WS) && \
	terraform plan \
		-var "nomad_secret_id=$(shell jq -r .SecretID ./.secrets/.nomad_bootstrap.json)" \
		-var "consul_secret_id=$(shell jq -r .SecretID ./.secrets/.consul_bootstrap.json)" \
		-var "vault_token=$(shell jq -r .SecretID ./.secrets/.vault_root_token.txt)"

terraform.apply:
	cd terraform/$(WS) && \
	terraform apply \
		-auto-approve \
		-var "nomad_secret_id=$(shell jq -r .SecretID ./.secrets/.nomad_bootstrap.json)" \
		-var "consul_secret_id=$(shell jq -r .SecretID ./.secrets/.consul_bootstrap.json)" \
		-var "vault_token=$(shell jq -r .SecretID ./.secrets/.vault_root_token.txt)"

terraform.refresh:
	cd terraform/$(WS) && \
	terraform refresh \
		-var "nomad_secret_id=$(shell jq -r .SecretID ./.secrets/.nomad_bootstrap.json)" \
		-var "consul_secret_id=$(shell jq -r .SecretID ./.secrets/.consul_bootstrap.json)" \
		-var "vault_token=$(shell jq -r .SecretID ./.secrets/.vault_root_token.txt)"

terraform.apply-all: terraform.init terraform.plan WS=$(WS)

conda.export:
	conda env export > environment.yml

conda.update:
	conda update -n base -c conda-forge conda

vault.encrypt:
	@echo "Encrypt all Ansible vault files"
	ansible-vault encrypt --vault-id $(VAULT_ID) $(VAULT_FILES)

vault.decrypt:
	@echo "Decrypt all Ansible vault files"
	ansible-vault decrypt --vault-id $(VAULT_ID) $(VAULT_FILES)
