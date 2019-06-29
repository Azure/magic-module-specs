ROOT=$(shell pwd)
GENROOT=$(ROOT)/generated
GOSRC=$(GENROOT)/go/src
TFROOT=$(GOSRC)/github.com/terraform-providers
TFGITURL=https://github.com/VSChina/terraform-provider-azurerm.git
TFREPO=terraform-provider-azurerm
ASGITURL=https://github.com/VSChina/ansible.git
ASREPO=ansible
MMROOT=$(ROOT)/tools/magic-modules

# Environment variables.
export GOPATH=generated/go

default: init

all: clean init build format-terraform

init:
	@echo "==> cloning repos of terraform and ansible..."
	if [ ! -d "$(TFROOT)" ]; then \
		mkdir -p "$(TFROOT)"; \
	fi

	if [ ! -d "$(TFROOT)/$(TFREPO)" ]; then \
		git clone $(TFGITURL) $(TFROOT)/$(TFREPO); \
	fi

	if [ ! -d "$(GENROOT)/$(ASREPO)" ]; then \
		git clone $(ASGITURL) $(GENROOT)/$(ASREPO); \
	fi

	git submodule update --init && \
	cd $(MMROOT) && \
	gem install bundler && \
	bundle install --retry=3 --jobs=4

clean:
	rm -rf $(GENROOT)

build: build-terraform build-ansible

build-terraform:
	cd $(MMROOT) && \
	jq '.[]' $(ROOT)/resources.json | xargs -I '{}' bundle exec compiler -d -p $(ROOT)/'{}' -e terraform -o $(TFROOT)/$(TFREPO)/ && \

format-terraform:
	cd $(TFROOT)/$(TFREPO) && \
	make goimports && \
	make fmt

build-ansible:
	cd $(MMROOT) && \
	jq '.[]' $(ROOT)/resources.json | xargs -I '{}' bundle exec compiler -d -p $(ROOT)/'{}' -e ansible -o $(GENROOT)/$(ASREPO)/

.PHONY: init clean build build-terraform format-terraform build-ansible