ROOT=$(shell pwd)
SPECROOT=$(ROOT)/specs
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
	@if [ ! -d "$(TFROOT)" ]; then \
		mkdir -p "$(TFROOT)"; \
	fi

	@echo "==> cloning repository for terraform..."
	@if [ ! -d "$(TFROOT)/$(TFREPO)" ]; then \
		git clone $(TFGITURL) $(TFROOT)/$(TFREPO); \
	fi

	@echo "==> cloning repository for ansible..."
	@if [ ! -d "$(GENROOT)/$(ASREPO)" ]; then \
		git clone $(ASGITURL) $(GENROOT)/$(ASREPO); \
	fi

	@echo "==> initializing submodules..."
	@git submodule update --init

	@echo "==> installing gem packages..."
	@cd $(MMROOT) && \
	gem install bundler && \
	bundle install --retry=3 --jobs=4

clean:
	@echo "==> cleaning code generation folder..."
	@rm -rf $(GENROOT)

build: build-terraform build-ansible

build-terraform:
	@echo "==> Generating source code for terraform..."
	@if [ -z "$(RESOURCE)" ]; then \
		echo "==> Generating source code for terraform from resource list..."; \
		cd $(MMROOT) && \
		sh $(ROOT)/list_resources.sh $(SOURCE_BRANCH) | xargs -I '{}' bundle exec compiler -d -p $(SPECROOT)/'{}' -e terraform -c azure -o $(TFROOT)/$(TFREPO)/; \
	else \
		echo "==> Generating source code for terraform from given name..."; \
		cd $(MMROOT) && \
		bundle exec compiler -d -p $(SPECROOT)/$(RESOURCE) -e terraform -c azure -o $(TFROOT)/$(TFREPO)/; \
	fi

format-terraform:
	@echo "==> Importing packages and formatting code for terraform..."
	@cd $(TFROOT)/$(TFREPO) && \
	goimports -w azurerm && \
	make fmt

build-ansible:
	@echo "==> Generating source code for ansible..."
	@if [ -z "$(RESOURCE)" ]; then \
		echo "==> Generating source code for ansible from resource list..."; \
		cd $(MMROOT) && \
		sh $(ROOT)/list_resources.sh $(SOURCE_BRANCH) | xargs -I '{}' bundle exec compiler -d -p $(SPECROOT)/'{}' -e ansible -c azure -o $(GENROOT)/$(ASREPO)/; \
	else \
		echo "==> Generating source code for ansible from given name..."; \
		cd $(MMROOT) && \
		bundle exec compiler -d -p $(SPECROOT)/$(RESOURCE) -e ansible -c azure -o $(GENROOT)/$(ASREPO)/; \
	fi

.PHONY: init clean build build-terraform format-terraform build-ansible