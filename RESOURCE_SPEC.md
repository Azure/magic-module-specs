# Azure Resource Specification

## Overview

In this document, we will introduce the detailed specification items of an Azure resource. You can find anything you need to generate the code for you DevOps tools like Terraform or Ansible. You might refer to [README](README.md) to have a general view of the entire folder structure used in this repository.

## Required Inputs

The minimum requirement would be to have an API definition file as well as an overrides definition file for a DevOps tool.

* **api.yaml** is the API definition file defines all Azure SDK structure and the user interface shared across all DevOps tools.
* **&lt;provider&gt;.yaml** is the definition file overrides the default api.yaml for one specific DevOps tool (e.g. `terraform.yaml`, `ansible.yaml`).

Typically we prefer to generate `api.yaml` automatically from [azure-rest-api-specs](https://github.com/Azure/azure-rest-api-specs) by using [autorest.devops](https://github.com/Azure/autorest.devops) to avoid the tedious work of defining Azure SDK structure. But we still accept manually written `api.yaml` in this repository.

`<provider>.yaml` is used to override the values defined in `api.yaml` when generating code for a DevOps tool. It also provides additional inputs to that specific DevOps tool as well. Common usages include but not limited to: renaming attribute names, defining test cases, defining examples used in documentation, adding customized code snippet.

### API Definition: api.yaml

`api.yaml` is a strongly-typed YAML file for Ruby, which means you will encounter some ruby-specific syntax in this yaml file. Since `api.yaml` is shared across all DevOps tools, we request all values using **camelCase** (the only exception is the resource name), and magic-module will convert it to the targeting casing (e.g. snake_case in Terraform).

Firstly I would like to give you a big picture of what `api.yaml` looks like (we suggest you to view the actual [batchaccount `api.yaml`](https://github.com/Azure/magic-module-specs/blob/master/batchaccount/api.yaml) file side-by-side to better understand the concepts here):

```yaml
  1   --- !ruby/object:Api::Product
  2   name: <Azure Resource Name, without restrictions>
  3   prefix: <Any value makes sense, without restrictions>
  4   versions:
  5     - !ruby/object:Api::Product::Version
  6       name: <Not used in Azure but required by GCP>
  7       base_uirl: <Not used in Azure but required by GCP>
  8   scopes:
  9     - <Not used in Azure but required by GCP>

 10   objects:
 11     - !ruby/object:Api::Resource
 12       name: <Azure Resource Name, used as Terraform resource name and Ansible module name>
 13       api_name: <Not used in Azure but required by GCP>
 14       base_url: <Not used in Azure but required by GCP>

 15       azure_sdk_definition: !ruby/object:Api::Azure::SDKDefinition
 16         provider_name: <Azure service provider, see below>
 17         <Go client definitions, required>
 18         <Python client definitions, required>
 19         create: !ruby/object:Api::Azure::SDKOperationDefinition
 20           <Create operation definitions, required>
 21           request:
 22             <Create request parameters and body definitions, required>
 23         read: !ruby/object:Api::Azure::SDKOperationDefinition
 24           <Read operation definitions, required>
 25           request:
 26             <Read request parameters definitions, required>
 27           response:
 28             <Read response body definitions, required>
 29         update: !ruby/object:Api::Azure::SDKOperationDefinition
 30           <Update operation definitions, optional if update is included in create>
 31           request:
 32             <Update request parameters and body definitions, required>
 33         delete: !ruby/object:Api::Azure::SDKOperationDefinition
 34           <Delete operation definitions, required>
 35           request:
 36             <Delete request parameters definitions, required>
 37         list_by_rg: !ruby/object:Api::Azure::SDKOperationDefinition
 38           <List by resource group operation definitions, optional, only used in Ansible info module>
 39           request:
 40             <List by resource group request parameters definitions, required>

 41       description: <Any value makes sense, used in documentation>
 42       parameters:
 43         <Parameter definitions, user interface of DevOps tools, see below>
 44       properties:
 45         <Property definitions, user interface of DevOps tools, see below>
```

#### Resource Definition

The major definition starts from the resource definition (line 11). Unlike the GCP resources definitions, we support **one and only one object** definition in `objects`.

#### SDK Client Definition

#### SDK Operation Definition

#### Parameters v.s. Properties

#### DevOps User Interface Definition

### Ansible Overrides: ansible.yaml

`ansible.yaml` defines overrides and additional inputs for Ansible. The overall structure is demonstrated below, and please refer to [batchaccount `ansible.yaml`](https://github.com/Azure/magic-module-specs/blob/master/batchaccount/ansible.yaml) as a real-world example.

```yaml
  1   --- !ruby/object:Provider::Ansible::Config
  2   manifest: !ruby/object:Provider::Ansible::Manifest
  3     metadata_version: <Used in ANSIBLE_METADATA>
  4     status:
  5       <Used in ANSIBLE_METADATA>
  6     supported_by: <Used in ANSIBLE_METADATA>
  7     requirements:
  8       <Not used in Azure>
  9     version_added: <Used in DOCUMENTATION>
 10     author: <Used in DOCUMENTATION>

 11   datasources: !ruby/object:Provider::ResourceOverrides
 12     <objects[0].name in api.yaml>: !ruby/object:Provider::Azure::Ansible::ResourceOverride
 13       version_added: <Used in DOCUMENTATION of info module>
 14       properties:
 15         <Property overrides for info module>
 16       examples:
 17         <EXAMPLES definitions for info module>

 18   overrides: !ruby/object:Provider::ResourceOverrides
 19     <objects[0].name in api.yaml>: !ruby/object:Provider::Azure::Ansible::ResourceOverride
 20       properties:
 21         <Property overrides for resource module>
 22       examples:
 23         <EXAMPLES definitions for resource module>
 24       inttests:
 25         <Integration test definitions for resource module, at most one for now>
```

### Terraform Overrides: terraform.yaml

`terraform.yaml` defines overrides and additional inputs for Terraform. The overall structure is demonstrated below, and please refer to [batchaccount `terraform.yaml`](https://github.com/Azure/magic-module-specs/blob/master/batchaccount/terraform.yaml) as a real-world example.

```yaml
  1   --- !ruby/object:Provider::Terraform::Config
  2   overrides: !ruby/object:Provider::ResourceOverrides
  3     <objects[0].name in api.yaml>: !ruby/object:Provider::Azure::Terraform::ResourceOverride
  4       azure_sdk_definition: !ruby/object:Api::Azure::SDKDefinitionOverride
  5         <Azure SDK structure overrides, optional>
  6       properties:
  7         <Property overrides for resource, required>
  8       custom_code: !ruby/object:Provider::Terraform::CustomCode
  9         <Customized code snippets for resource, optional>
 10       document_examples:
 11         <Example definitions for resource documentation, optional>
 12       acctests:
 13         <Acceptance test definitions for resource, optional>

 14   datasources: !ruby/object:Provider::ResourceOverrides
 15     <objects[0].name in api.yaml>: !ruby/object:Provider::Azure::Terraform::ResourceOverride
 16       properties:
 17         <Property overrides for data source, required>
 18       datasource_example_outputs:
 19         <Output variable definition for data source documentation, optional>
 20       acctests:
 21         <Acceptance test definitions for data source, optional>
```

Please note that it is critical to define `overrides` before `datasources` in `terraform.yaml`, otherwise everything defined in `overrides` will be lost in `datasources`.

## Advanced Topics

### Test Case and Example

One of the advantages not mentioned above is that magic-module for Azure also generates test cases and documentation examples for DevOps tools.

### Customized Code

It is not uncommon that some additional code is required to handle special cases. We support that through customized code snippets.
