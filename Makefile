# Dev
dev.install:
	rye sync

dev.docs:
	mdbook serve docs --open

# Ansible
ansible.install:
	cd ansible && ansible-galaxy install -r requirements.yml

ansible.nas:
	cd ansible && ansible-playbook playbooks/nas.yml

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