
# Magic-Module Specifications for Azure

## Overview

This repository is where we put all magic-module specifications for Azure resources. [Magic-module](https://github.com/GoogleCloudPlatform/magic-modules) is an open source utility developed by Google to autogenerate support code in a variety of open source DevOps tools.

For Azure resources, we chose to generate [Terraform](https://www.terraform.io/) and [Ansible](https://www.ansible.com/) code by magic-module. So we extended magic-module to support both Azure resources and GCP resources side-by-side. Please make sure you are using the Azure-extended magic-module instead of the original one when generating code from the specifications in this repository.

## Folder Structure

The following figure illustrates the overall folder structure of this repository:

```
magic-module-specs
  |- <resource folder 1>
  |    |- api.yaml
  |    |- ansible.yaml
  |    |- terraform.yaml
  |    |- <custom code 1>.erb
  |    |- <custom code 2>.erb
  |    |- ...
  |    |- examples
  |         |- ansible
  |         |    |- <example 1>.yaml
  |         |    |- <example 2>.yaml
  |         |    |- ...
  |         |- terraform
  |              |- <example 1>.yaml
  |              |- <example 2>.yaml
  |              |- ...
  |- <resource folder 2>
  |- ...
  |- generated-ansible
  |    |- **
  |- generated-terraform
       |- **
```

The repository contains specifications for Azure resources supported in open source DevOps tools. Each resource specifications should be put in an isolated folder under the root folder (i.e. `<resource folder i>`). For example, [`/batchaccount`](https://github.com/Azure/magic-module-specs/tree/master/batchaccount) folder contains all specifications related to [Azure batch account](https://docs.microsoft.com/en-us/rest/api/batchmanagement/batchaccount).

Specifications of a resource consist of the following items:

* An `api.yaml` defining Azure SDK structure as well as the standard user interface of the DevOps tools
* An `ansible.yaml` defining Ansible specific override to the `api.yaml`
* A `terraform.yaml` defining Terraform specific overrides to the `api.yaml`
* Zero or more `.erb` files defining special code to be embedded in the generated code
* Zero or more `.yaml` files under `examples` folder defining examples and test cases

For a detailed description of the items mentioned above, please refer to [RESOURCE_SPEC](RESOURCE_SPEC.md).

This repository also includes all generated code in `generated-ansible` and `generated-terraform`. The folder strcture within these generated folders exactly matches the [ansible](https://github.com/ansible/ansible) and [terraform provider for Azure](https://github.com/terraform-providers/terraform-provider-azurerm) respectively.

Please refer to the [Workflow](#workflow) section about how to make contributions to DevOps tools using the generated code.

## Workflow

Expert: jcline@microsoft.com.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

### Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

### License

Copyright (c) Microsoft Corporation. All rights reserved.


Licensed under the [MIT](LICENSE) license.