# Dev
dev.install:
	rye sync

dev.docs:
	mdbook serve docs --open

# Ansible
ansible.install:
	cd ansible && ansible-galaxy install -r requirements.yml

# Vagrant
vagrant.up.cluster:
	cd vagrant && VAGRANT_DISABLE_STRICT_DEPENDENCY_ENFORCEMENT=1 vagrant up cluster-node1 cluster-node2 cluster-node3 cluster-node4

vagrant.provision.cluster:
	cd vagrant && vagrant provision cluster-node1 cluster-node2 cluster-node3 cluster-node4

vagrant.restart.cluster: vagrant.destroy vagrant.up.cluster

vagrant.up.nas:
	cd vagrant && VAGRANT_DISABLE_STRICT_DEPENDENCY_ENFORCEMENT=1 vagrant up nas-archlinux

vagrant.provision.nas:
	cd vagrant && vagrant provision nas-archlinux

vagrant.restart.nas: vagrant.destroy vagrant.up.nas

vagrant.reload:
	cd vagrant && vagrant reload

vagrant.destroy:
	cd vagrant && vagrant destroy -f