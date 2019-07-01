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
export GOPATH=$(GENROOT)/go
export GO111MODULE=on
export GOFLAGS=-mod=vendor

default: init

all: clean init build format-terraform

init:
	@echo "==> creating folders for code generation..."
	if [ ! -d "$(TFROOT)" ]; then \
		mkdir -p "$(TFROOT)"; \
	fi

	@echo "==> cloning repository for terraform..."
	if [ ! -d "$(TFROOT)/$(TFREPO)" ]; then \
		git clone $(TFGITURL) $(TFROOT)/$(TFREPO); \
	fi

	@echo "==> cloning repository for ansible..."
	if [ ! -d "$(GENROOT)/$(ASREPO)" ]; then \
		git clone $(ASGITURL) $(GENROOT)/$(ASREPO); \
	fi

	@echo "==> initializing submodules..."
	git submodule update --init

	@echo "==> installing gem packages..."
	cd $(MMROOT) && \
	gem install bundler && \
	bundle install --retry=3 --jobs=4

clean:
	@echo "==> cleaning code generation folder..."
	rm -rf $(GENROOT)

build: build-terraform build-ansible

build-terraform:
	@echo "==> Generating source code for terraform..."
	cd $(MMROOT) && \
	if [ -z "$(NAME)" ]; then \
		@echo "==> Generating source code for terraform from resource list..." \
		jq '.[]' $(ROOT)/resources.json | xargs -I '{}' bundle exec compiler -d -p $(ROOT)/'{}' -e terraform -o $(TFROOT)/$(TFREPO)/; \
	else \
		@echo "==> Generating source code for terraform from given name..." \
		bundle exec compiler -d -p $(ROOT)/$(NAME) -e terraform -o $(TFROOT)/$(TFREPO)/; \
	fi

format-terraform:
	cd $(TFROOT)/$(TFREPO) && \
	@echo "==> Importing packages for terraform..." \
	goimports -w azurerm && \
	@echo "==> Formatting code for terraform..." \
	make fmt

build-ansible:
	@echo "==> Generating source code for ansible..."
	cd $(MMROOT) && \
	if [ -z "$(NAME)" ]; then \
		@echo "==> Generating source code for ansible from resource list..." \
		jq '.[]' $(ROOT)/resources.json | xargs -I '{}' bundle exec compiler -d -p $(ROOT)/'{}' -e ansible -o $(GENROOT)/$(ASREPO)/; \
	else \
		@echo "==> Generating source code for ansible from given name..." \
		bundle exec compiler -d -p $(ROOT)/$(NAME) -e ansible -o $(GENROOT)/$(ASREPO)/; \
	fi

.PHONY: init clean build build-terraform format-terraform build-ansible