VAULT_FILES=ansible/inventory/group_vars/*/secrets/*.vault.*
VAULT_ID=default@.vault_pass

# Dev
dev.install:
	rye sync

dev.docs:
	mdbook serve docs --open

# Ansible
ansible.install:
	cd ansible && ansible-galaxy install -r requirements.yml -f

ansible.provision:
	cd ansible && ansible-playbook playbooks/provision.yml

ansible.run:
	@if [ -z "$(playbook)" ]; then \
		echo "Error: playbook parameter is missing. Usage: make ansible.run playbook=<nas|cluster>"; \
		exit 1; \
	fi
	@if [ -n "$(role)" ]; then \
		cd ansible && ansible-playbook playbooks/$(playbook).yml --tags $(role) -v; \
	else \
		cd ansible && ansible-playbook playbooks/$(playbook).yml -vvv; \
	fi

# Docker
docker.up:
	@if [ -z "$(env)" ]; then \
		echo "Error: env parameter is missing. Usage: make docker.up env=<nas|cluster>"; \
		exit 1; \
	fi
	cd docker && docker compose up -d $(env)

docker.up.build:
	@if [ -z "$(env)" ]; then \
		echo "Error: env parameter is missing. Usage: make docker.up.build env=<nas|cluster>"; \
		exit 1; \
	fi
	cd docker && docker compose up -d $(env) --build

docker.restart:
	@if [ -z "$(env)" ]; then \
		echo "Error: env parameter is missing. Usage: make docker.restart env=<nas|cluster>"; \
		exit 1; \
	fi
	cd docker && docker rm -f $(env) && docker compose up -d $(env)

docker.destroy:
	@if [ -z "$(env)" ]; then \
		echo "Error: env parameter is missing. Usage: make docker.destroy env=<nas|cluster>"; \
		exit 1; \
	fi
	cd docker && docker rm -f $(env)

docker.provision:
	@if [ -z "$(env)" ]; then \
		echo "Error: env parameter is missing. Usage: make docker.provision env=<nas|cluster>"; \
		exit 1; \
	fi
	cd docker && ansible-playbook --extra-vars "@./ansible-extra-vars.yml" --vault-id default@../.vault_pass playbooks/provision.yml

# Vagrant
vagrant.cluster.up:
	@if [ -z "$(playbook)" ]; then \
		echo "Error: playbook parameter is missing. Usage: make ansible.run playbook=<nas|cluster>"; \
		exit 1; \
	fi

	cd vagrant && ANSIBLE_PLAYBOOK=$(playbook) VAGRANT_DISABLE_STRICT_DEPENDENCY_ENFORCEMENT=1 vagrant up cluster-node1 cluster-node2 cluster-node3 cluster-node4

vagrant.cluster.provision:
	@if [ -z "$(playbook)" ]; then \
		echo "Error: playbook parameter is missing. Usage: make ansible.run playbook=<nas|cluster>"; \
		exit 1; \
	fi

	cd vagrant && ANSIBLE_PLAYBOOK=$(playbook) vagrant provision cluster-node1 cluster-node2 cluster-node3 cluster-node4

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

levant.deploy:
	@if [ -z "$(job)" ]; then \
		echo "Error: job parameter is missing. Usage: make levant.deploy job="; \
		exit 1; \
	fi
	docker run \
	--rm \
	-e NOMAD_ADDR="http://192.168.2.221:4646" \
	-e NOMAD_TOKEN="c62233cc-04df-7203-d753-fd77bfdfb452" \
	-e VAULT_TOKEN="hvs.FhYjjIwWIHElN10Mb6iSGQnE" \
	-e ENVIRONMENT \
	-v ${PWD}/nomad-jobs:/workdir \
	-w /workdir \
	hashicorp/levant:0.3.3 levant deploy -vault -var-file=/workdir/levant.yml /workdir/${job}/nomad.hcl

# Terraform
terraform.init:
	@if [ -z "$(workspace)" ]; then \
		echo "Error: workspace parameter is missing. Usage: make terraform.init workspace=<nomad|cluster>"; \
		exit 1; \
	fi
	cd terraform/$(workspace) && \
	terraform init

terraform.plan:
	@if [ -z "$(workspace)" ]; then \
		echo "Error: workspace parameter is missing. Usage: make terraform.plan workspace=<nomad|cluster>"; \
		exit 1; \
	fi

	cd terraform/$(workspace) && \
	terraform plan \
		-var "nomad_secret_id=$(shell jq -r .SecretID ./.secrets/.nomad_bootstrap.json)" \
		-var "consul_secret_id=$(shell jq -r .SecretID ./.secrets/.consul_bootstrap.json)"

terraform.apply:
	@if [ -z "$(workspace)" ]; then \
		echo "Error: workspace parameter is missing. Usage: make terraform.apply workspace=<nomad|cluster>"; \
		exit 1; \
	fi

	cd terraform/$(workspace) && \
	terraform apply \
		-auto-approve \
		-var "nomad_secret_id=$(shell jq -r .SecretID ./.secrets/.nomad_bootstrap.json)" \
		-var "consul_secret_id=$(shell jq -r .SecretID ./.secrets/.consul_bootstrap.json)" \
		-var "vault_token=$(shell jq -r .SecretID ./.secrets/.vault_root_token.txt)"

terraform.refresh:
	@if [ -z "$(workspace)" ]; then \
		echo "Error: workspace parameter is missing. Usage: make terraform.refresh workspace=<nomad|cluster>"; \
		exit 1; \
	fi

	cd terraform/$(workspace) && \
	terraform refresh \
		-var "nomad_secret_id=$(shell jq -r .SecretID ./.secrets/.nomad_bootstrap.json)" \
		-var "consul_secret_id=$(shell jq -r .SecretID ./.secrets/.consul_bootstrap.json)" \
		-var "vault_token=$(shell jq -r .SecretID ./.secrets/.vault_root_token.txt)"

terraform.apply-all: terraform.init terraform.plan workspace=$(workspace)

## CONDA ##
conda.export:
	conda env export > environment.yml

conda.import:
	conda env create -f environment.yml

conda.update.base:
	conda update -n base -c conda-forge conda

conda.update.file:
	conda update env --file environment.yml

## ANSIBLE VAULT ##
vault.encrypt:
	@echo "Encrypt all Ansible vault files"
	ansible-vault encrypt --vault-id $(VAULT_ID) $(VAULT_FILES)

vault.decrypt:
	@echo "Decrypt all Ansible vault files"
	ansible-vault decrypt --vault-id $(VAULT_ID) $(VAULT_FILES)
