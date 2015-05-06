## Vagrant python template

### What is is
This is a template for creating an isolated environment with python, postgres
and redis installed. Its basically a set of commands listed in a file.

### Pre requirements
In order to use this you need [vagrant](https://www.vagrantup.com/) and
[virtualbox](https://www.virtualbox.org/) installed.


### How to use

	git clone git@github.com:gelbander/vagrant-python-template.git projectname

Specify database etc. by edit the `provisioner.sh` in the very top.

	vagrant up

Drink some coffe and wait for a tremendous amount of time :)

	vagrant ssh

Start doing!


