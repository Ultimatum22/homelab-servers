# Dev
dev.install:
	rye sync

dev.docs:
	mdbook serve docs --open

# Vagrant
vagrant.up:
	cd vagrant/$(VAGRANTSERVER) && VAGRANT_DISABLE_STRICT_DEPENDENCY_ENFORCEMENT=1 vagrant up

vagrant.provision:
	cd vagrant/$(VAGRANTSERVER)  && vagrant provision

vagrant.reload:
	cd vagrant/$(VAGRANTSERVER)  && vagrant reload

vagrant.restart: vagrant.destroy vagrant.up

vagrant.destroy:
	cd vagrant/$(VAGRANTSERVER)  && vagrant destroy -f