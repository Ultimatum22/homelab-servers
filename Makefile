# Dev
dev.install:
	rye sync

dev.docs:
	mdbook serve docs --open

# Ansible
ansible.install:
	cd ansible && ansible-galaxy install -r requirements.yml

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