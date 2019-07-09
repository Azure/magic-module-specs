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
  3   versions:
  4     - !ruby/object:Api::Product::Version
  5       name: <Not used in Azure but required by GCP>
  6       base_url: <Not used in Azure but required by GCP>
  7   scopes:
  8     - <Not used in Azure but required by GCP>

  9   objects:
 10     - !ruby/object:Api::Resource
 11       name: <Azure Resource Name, used as Terraform resource name and Ansible module name>
 12       api_name: <Not used in Azure but required by GCP>
 13       base_url: <Not used in Azure but required by GCP>

 14       azure_sdk_definition: !ruby/object:Api::Azure::SDKDefinition
 15         provider_name: <Azure service provider, see below>
 16         <Go client definitions, required>
 17         <Python client definitions, required>
 18         create: !ruby/object:Api::Azure::SDKOperationDefinition
 19           <Create operation definitions, required>
 20           request:
 21             <Create request parameters and body definitions, required>
 22         read: !ruby/object:Api::Azure::SDKOperationDefinition
 23           <Read operation definitions, required>
 24           request:
 25             <Read request parameters definitions, required>
 26           response:
 27             <Read response body definitions, required>
 28         update: !ruby/object:Api::Azure::SDKOperationDefinition
 29           <Update operation definitions, optional if update is included in create>
 30           request:
 31             <Update request parameters and body definitions, required>
 32         delete: !ruby/object:Api::Azure::SDKOperationDefinition
 33           <Delete operation definitions, required>
 34           request:
 35             <Delete request parameters definitions, required>
 36         list_by_resource_group: !ruby/object:Api::Azure::SDKOperationDefinition
 37           <List by resource group operation definitions, optional, only used in Ansible info module>
 38           request:
 39             <List by resource group request parameters definitions, required>

 40       description: <Any value makes sense, used in documentation>
 41       parameters:
 42         <Parameter definitions, user interface of DevOps tools, see below>
 43       properties:
 44         <Property definitions, user interface of DevOps tools, see below>
```

#### Resource Definition

The major definition starts from the resource definition (line 11). Unlike the GCP resources definitions, we support **one and only one object** definition in `objects`.

A resource definition contains three parts:

* Name (line 12) and description (line 41)
* Azure SDK definition (line 15 - 40)
* Parameters (line 42 - 43) and properties (line 44 - 45)

We will explain name and description here, and leave the other two later.

Resource name has to be in PascalCase, magic-module will convert it to appropriate casing in the generated code. For example, "BatchAccount", will be used in the following senarios:

* File names: data_source_**batch_account**.go, resource_arm_**batch_account**.go, azure_rm_**batchaccount**.py, azure_rm_**batchaccount**_info.py
* Terraform resource name: azurerm_**batch_account**
* Ansible module name: azure_rm_**batchaccount**
* Class and function names: `AzureRM`**`BatchAccount`**, `delete_`**`batchaccount`**, `resourceArm`**`BatchAccount`**, `expandArm`**`BatchAccount`**`KeyVaultReference`

Resource description will be used in documentations. Here are the examples for batch account: [Terraform](https://github.com/Azure/magic-module-specs/blame/master/generated-terraform/website/docs/r/batch_account.html.markdown#L19-L24) and [Ansible](https://github.com/Azure/magic-module-specs/blob/master/generated-ansible/lib/ansible/modules/cloud/azure/azure_rm_batchaccount.py#L31).

#### SDK Client Definition

The biggest difference between Azure extended magic-module and the original Google magic-module is that we added Azure SDK definitions, because all DevOps tools for Azure are required to use one of the Azure SDKs (like Go SDK, Python SDK). So we need to define what the resource CRUD operations look like in different Azure SDKs.

The client definition ranges from line 16 to line 18, you can define the following attributes:

```yaml
  1   provider_name: <Azure service provider>
  2   go_client_namespace: <Go package name of this resource>
  3   go_client: <Go client expression in Terraform code base>
  4   python_client_namespace: <Python namespace name of this resource>
  5   python_client: <Python client expression of this resource>
```

Let's still use the batch account example.

Part of the URL of the [create RESTful API](https://docs.microsoft.com/en-us/rest/api/batchmanagement/batchaccount/create) looks like: `.../providers/Microsoft.Batch/batchAccounts/...`. Here, we should set the provider name `Microsoft.Batch` (the string between `/providers/` and `/batchAccounts/`) to `provider_name`.

To define `go_client_namespace`, you should reference the corresponding [Azure Go SDK package](https://github.com/Azure/azure-sdk-for-go/blob/master/services/batch/mgmt/2018-12-01/batch/account.go#L1), which is `batch` for batch account. However, you should use the [client expression in Terraform](https://github.com/Azure/magic-module-specs/blob/master/generated-terraform/azurerm/resource_arm_batch_account.go#L92) instead of Go SDK to define `go_client`, we can see the value for batch account is `batchAccountClient` (everything after `meta.(*ArmClient).`).

Similarly, navigate to [Azure Python SDK](https://github.com/Azure/azure-sdk-for-python/blob/master/sdk/batch/azure-mgmt-batch/azure/mgmt/batch/batch_management_client.py) to define the `python_client_namespace`, which is `azure.mgmt.batch`. Put the [client expression](https://github.com/Azure/azure-sdk-for-python/blob/master/sdk/batch/azure-mgmt-batch/azure/mgmt/batch/batch_management_client.py#L100) `BatchManagementClient.batch_account` to `python_client` as well.

Keep in mind that you will frequently reference Azure Go SDK and Azure Python SDK repositories throughout the entire Azure SDK definition.

#### SDK Operation Definition

Next, it is time to define all SDK CRUD operations of the resource. We supports five operation types:

* `create`: operation to create or create_or_update a resource depending on the actual SDK code
* `read`: operation to get a resource
* `update`: operation to update a resource (if exists in SDK)
* `delete`: operation to delete a resource
* `list_by_resource_group`: operation to list all resources of this type in a resource group
* `list_by_subscription`: operation to list all resources of this type in a subscription
* `list_by_parent`: operation to list all sub-resources of this type in its parent resource

Magic-module cares about `request`s of all operations, and only needs the `response` of `read` operations. So you can omit `response`s in operations other than `read`.

When Azure SDK uses `create or update` to provision a resource (like [service bus queues](https://docs.microsoft.com/en-us/rest/api/servicebus/queues/createorupdate)), we can get rid of the `update` operation definition:

```yaml
  1   create: !ruby/object:Api::Azure::SDKOperationDefinition
  2     <Create operation definitions, required>
  3     request:
  4       <Create request parameters and body definitions, required>
  5   read: !ruby/object:Api::Azure::SDKOperationDefinition
  6     <Read operation definitions, required>
  7     request:
  8       <Read request parameters definitions, required>
  9     response:
 10       <Read response body definitions, required>
 11   delete: !ruby/object:Api::Azure::SDKOperationDefinition
 12     <Delete operation definitions, required>
 13     request:
 14       <Delete request parameters definitions, required>
```

For all operations, we need to define the function names used in different SDKs.

```yaml
  1   async: <true or false, by default false>
  2   go_func_name: <Function name in Go SDK>
  3   python_func_name: <Method name in Python SDK>
```

I will use the `create` operation of batch account as an example. It is straightforward to get the `go_func_name` from [Go SDK](https://github.com/Azure/azure-sdk-for-go/blob/master/services/batch/mgmt/2018-12-01/batch/account.go#L53), and `python_func_name` from [Python SDK](https://github.com/Azure/azure-sdk-for-python/blob/master/sdk/batch/azure-mgmt-batch/azure/mgmt/batch/operations/batch_account_operations.py#L101). But there are no simple ways to determine whether an operation is `async` or not, the only possible solution would be taking a look at the [Go SDK](https://github.com/Azure/azure-sdk-for-go/blob/master/services/batch/mgmt/2018-12-01/batch/account.go#L53), if it returns some "Future", we can say the operation is `async: true`, otherwise just remove this line.

#### SDK Operation Request

We use a hash table to define operation request. Usually a request is a tree-like structure:

```
A: x1
B: x2
|- C: x3
   |- D: x4
|- E: x5
```

The first step is to flatten it and make a hash table:

```
'A': x1
'B': x2
'B/C': x3
'B/C/D': x4
'B/E': x5
```

Using the example of [batch account create function in Go SDK](https://github.com/Azure/azure-sdk-for-go/blob/master/services/batch/mgmt/2018-12-01/batch/account.go#L53), there are four function parameters: `ctx`, `resourceGroupName`, `accountName` and `parameters`. We don't care about `ctx`, get rid of it. So let's put the parameters definition one-by-one to our `request` in `create` now are:

First of all is `resourceGroupName`:

```yaml
  1   'resourceGroupName': !ruby/object:Api::Azure::SDKTypeDefinition::StringObject
  2     id_portion: resourceGroups
  3     go_variable_name: resourceGroup
  4     python_parameter_name: resource_group_name
  5     python_variable_name: resource_group
```

The hash table key `resourceGroupName` could be actually any string as long as it follows the rule mentioned in the tree-hash structure above, but we commend to use something make sense. The type `!ruby/object:Api::Azure::SDKTypeDefinition::StringObject` means this is a string value when invoking the SDK. We support the following types:

* `!ruby/object:Api::Azure::SDKTypeDefinition::BooleanObject`: a boolean value in SDK.
* `!ruby/object:Api::Azure::SDKTypeDefinition::ComplexObject`: a structure value in SDK.
* `!ruby/object:Api::Azure::SDKTypeDefinition::ComplexArrayObject`: an array of structures value in SDK.
* `!ruby/object:Api::Azure::SDKTypeDefinition::EnumObject`: an enumeration value in SDK.
* `!ruby/object:Api::Azure::SDKTypeDefinition::FloatObject`: a double-precision floating-point value in SDK.
* `!ruby/object:Api::Azure::SDKTypeDefinition::IntegerObject`: a native-bit-size integer value in SDK (like `int` in C).
* `!ruby/object:Api::Azure::SDKTypeDefinition::Integer32Object`: a 32-bit integer value in SDK (like `int32_t` in C).
* `!ruby/object:Api::Azure::SDKTypeDefinition::Integer64Object`: a 64-bit integer value in SDK (like `int64_t` in C).
* `!ruby/object:Api::Azure::SDKTypeDefinition::ISO8601DateTimeObject`: a datetime value in SDK.
* `!ruby/object:Api::Azure::SDKTypeDefinition::ISO8601DurationObject`: a timespan value in SDK.
* `!ruby/object:Api::Azure::SDKTypeDefinition::StringObject`: a string value in SDK.
* `!ruby/object:Api::Azure::SDKTypeDefinition::StringArrayObject`: an array of strings value in SDK.
* `!ruby/object:Api::Azure::SDKTypeDefinition::StringMapObject`: a string-to-string hash table value in SDK.

All types support the following attributes (all optional, because not every attribute makes sense in different kinds of types):

```yaml
id_portion: <Only makes sense in root parameters>
applicable_to: <Only applies to a specific SDK>
empty_value_sensitive: <null and empty string are different>
is_pointer_type: <Explicitly tell whether this parameter/field is a Go pointer or not>
go_variable_name: <Go variable name in Terraform>
go_field_name: <Go SDK structure field name>
go_type_name: <Go SDK type name>
python_variable_name: <Python SDK parameter name>
python_parameter_name: <Python variable name in Ansible>
python_field_name: <Python SDK structure field name>
```

`id_portion` is part of the resource ID URL. For example, the ID of a batch account looks like `.../resourceGroups/rg/providers/Microsoft.Batch/batchAccounts/ba`. Then the `id_portion` of `resourceGroupName` is `resourceGroups` (the subpart before `/rg/`), and the `id_portion` of `accountName` is `batchAccounts` (the subpart before `/ba`). The `id_portion` only makes sense when it is used to identify a resource, for example, `resourceGroupName` and `accountName`.

You need to specify `applicable_to` when the definition is different between different SDKs. For example, when specifying `applicable_to: [go]`, this definition only applies to Go SDK. By default, it applies to all SDKs.

`empty_value_sensitive` means whether Azure treats zero-value differently than null-value. Most of the time, empty string is equivalent to null for Azure resources. And this undocumented behavior is heavily leveraged in Terraform.

`is_pointer_type` is a boolean value which explicitly specifies whether this parameter or field is a Go pointer or not. Typically we do not need to set it because magic-modules could handle almost all of the cases. But sometimes Go SDK has a weird type definition, and you have to use this field to override the default behavior. We recommend you to override the default behavior in `terraform.yaml` if `api.yaml` is auto-generated.

`go_variable_name` is the variable which will be used in the [generated Terraform code](https://github.com/Azure/magic-module-specs/blob/master/generated-terraform/azurerm/resource_arm_batch_account.go#L96). `go_field_name` and `go_type_name` only makes sense in `ComplexObject` or `ComplexArrayObject`, you can get them from the [Go SDK](https://github.com/Azure/azure-sdk-for-go/blob/master/services/batch/mgmt/2018-12-01/batch/models.go#L585).

`python_variable_name` will be used in the [generated Ansible code](https://github.com/Azure/magic-module-specs/blob/master/generated-ansible/lib/ansible/modules/cloud/azure/azure_rm_batchaccount.py#L171). `python_parameter_name` only makes sense when defining a parameter of [method in Python SDK](https://github.com/Azure/azure-sdk-for-python/blob/master/sdk/batch/azure-mgmt-batch/azure/mgmt/batch/operations/batch_account_operations.py#L102). `python_field_name` makes sense in `ComplexObject` or `ComplexArrayObject`, you can get it from the [Python SDK](https://github.com/Azure/azure-sdk-for-python/blob/master/sdk/batch/azure-mgmt-batch/azure/mgmt/batch/models/_models.py#L233).

In addition to those, `!ruby/object:Api::Azure::SDKTypeDefinition::EnumObject` supports two more:

```yaml
  1   go_enum_type_name: <The enumeration type defined in Go SDK, required>
  2   go_enum_const_prefix: <The enumeration constant prefix defined in Go SDK, optional>
```

We have to define `go_enum_type_name` for an enumeration, you can find it in [Go SDK](https://github.com/Azure/azure-sdk-for-go/blob/master/services/preview/frontdoor/mgmt/2019-04-01/frontdoor/models.go#L209). But it is not required to define `go_enum_const_prefix`, unless the constant name is different than the enumeration value, for example, we need to set `go_enum_const_prefix: EnforceCertificateNameCheckEnabledState` due to the special case of the [constant definition in Go SDK](https://github.com/Azure/azure-sdk-for-go/blob/master/services/preview/frontdoor/mgmt/2019-04-01/frontdoor/models.go#L211-L216). Because usually the constant definition will be look like:

```go
const (
    Disabled EnforceCertificateNameCheckEnabledState = "Disabled"
    Enabled EnforceCertificateNameCheckEnabledState = "Enabled"
)
```

But it is not the case for this specific usage:

```go
const (
    EnforceCertificateNameCheckEnabledStateDisabled EnforceCertificateNameCheckEnabledState = "Disabled"
    EnforceCertificateNameCheckEnabledStateEnabled EnforceCertificateNameCheckEnabledState = "Enabled"
)
```

After we added both `resourceGroupName` and `accountName` to the `request`, we will handle the last parameter in Go SDK `parameters`. It represents the request body in a RESTful API call, and it is a **required rule** that the key for the root object of the request body **must be** `'/'`. So the definition of `parameters` would look like:

```yaml
  1   '/': !ruby/object:Api::Azure::SDKTypeDefinition::ComplexObject
  2     go_variable_name: parameters
  3     go_type_name: AccountCreateParameters
  4     python_parameter_name: parameters
  5     python_variable_name: batch_account
```

And we do the same work recursively for all fields in the root object.

#### SDK Operation Response

We use the same concept as `request` for `response`. First we flatten the tree-like structure into a hash table; then we identify the corresponding response object in [SDK](https://github.com/Azure/azure-sdk-for-go/blob/master/services/batch/mgmt/2018-12-01/batch/models.go#L392). Still, it is required to name the root respone object as `'/'`. All other attributes are the same as `request`.

#### Parameters v.s. Properties

`Parameters` and `properties` together define the user interface of DevOps tools (i.e. resource schema in Terraform, module arg spec in Ansible). There is **no difference** between `parameters` and `properties` other than semantic best practice. During code generation stage, magic-module combines `parameters` and `proeprties` together and using the exactly same logic to handle them. The subtle difference between them is, `parameters` will not be persisted in Azure, while `properties` will. For example, resource group name is not persisted in any Azure APIs, it is only used to locate a specific resource, thus it should be put under `parameters`.

> When writing your own `api.yaml`, we suggest you to put everything under `properties` only.

#### DevOps User Interface Definition

One principle of defining user interface is it should make sense to the user, not the SDK. In order to do this, we might need to change the data type and flatten some nested properties. For example, the `resourceGroupName` definition would look like:

```yaml
  1   - !ruby/object:Api::Azure::Type::ResourceGroupName
  2     name: resourceGroupName
  3     description: The name of the resource group in which to create the Batch Account.
  4     required: true
  5     input: true
  6     azure_sdk_references: ['resourceGroupName']
```

> Note that the type defined here `!ruby/object:Api::Azure::Type::ResourceGroupName` is in a different namespace than the one used in Azure SDK definition.

We reuse the following user interface types from the original magic-module:

* `!ruby/object:Api::Type::Array`: an array of any type.
* `!ruby/object:Api::Type::Boolean`: a boolean.
* `!ruby/object:Api::Type::Double`: a double-precision floating-point number.
* `!ruby/object:Api::Type::Enum`: a enumeration.
* `!ruby/object:Api::Type::Integer`: an integer number.
* `!ruby/object:Api::Type::KeyValuePairs`: a string-to-string hash table.
* `!ruby/object:Api::Type::Map`: a string-to-any-type hash table.
* `!ruby/object:Api::Type::NestedObject`: a structure containing sub-properties.
* `!ruby/object:Api::Type::String`: a string.

Besides the standard types, we introduced several Azure specific types as well:

* `!ruby/object:Api::Azure::Type::Location`: the location of an Azure data center.
* `!ruby/object:Api::Azure::Type::ResourceGroupName`: the resource group name.
* `!ruby/object:Api::Azure::Type::ResourceReference`: the ID of a resource.
* `!ruby/object:Api::Azure::Type::Tags`: the tags in Azure resources.

All types supports the following attributes:

```yaml
  1   default_value: <default value used in schema>
  2   description: <used in documentation>
  3   input: <if set to true value is used only on creation>
  4   output: <if set to true value will be set from the response, but it will not be copied to request>
  5   required: <whether it is required, false by default>
  6   sample_value: <sample value used in Ansible documentation and normalize_id>
  7   azure_sdk_references: <list of keys in request and response of azure_sdk_definition operations>
```

`azure_sdk_references` is the actual property which links this user interface field to the actual Azure SDK definition. So we need to put **ALL valid references** (the key in `request` or `response` in `azure_sdk_definition`) to it. For example, the following user interface definition:

```yaml
  1   - !ruby/object:Api::Type::String
  2     name: name
  3     description: The name of the Batch Account.
  4     required: true
  5     input: true
  6     azure_sdk_references: ['accountName', '/name']
```

It specifies the name of a batch account. When creating/reading/updating/deleting a resource, we need to copy it to the parameter `azure_sdk_definition.create.request['`**`accountName`**`']` (or `azure_sdk_definition.read.request['`**`accountName`**`']`, or `azure_sdk_definition.update.request['`**`accountName`**`']`, or `azure_sdk_definition.delete.request['`**`accountName`**`']`). But then reading a batch account, we also need to copy the value from `azure_sdk_definition.read.response['`**`/name`**`']` back to it. Therefore, the `azure_sdk_references` for this property would be `['accountName', '/name']`.

`!ruby/object:Api::Type::Array` supports more:

```yaml
item_type: <the fully-qualified ruby class name of the type of this array>
min_size: <the minimum required count of the elements>
max_size: <the maximum allowed count of the elements>
```

`!ruby/object:Api::Type::Enum` supports one more:

```yaml
values: <list of valid string values of this enumeration, it should match SDK constant definitions>
```

`!ruby/object:Api::Type::NestedObject` supports additional:

```yaml
properties: <sub-properties of this structure>
```

`!ruby/object:Api::Azure::Type::ResourceReference` supports additional:

```yaml
resource_type_name: <User-readable type name of this reference, it will be used in Ansible documentation>
```

To support nested-object in an array, we can use the following snippet (notice the indentation level of `properties`):

```yaml
- !ruby/object:Api::Type::Array
  name: 'complexArray'
  item_type: !ruby/object:Api::Type::NestedObject
    properties:
      - !ruby/object:Api::Type::String
        name: 'subProp1'
      - !ruby/object:Api::Type::String
        name: 'subProp2'
```

### Ansible Overrides: ansible.yaml

`ansible.yaml` defines overrides and additional inputs for Ansible. The overall structure is demonstrated below, and please refer to [batchaccount `ansible.yaml`](https://github.com/Azure/magic-module-specs/blob/master/batchaccount/ansible.yaml) as a real-world example.

> Note that `author`, `version_added` and `overrides.<object>.properties` itself are required, while all other properties illustrated here are optional. You can simply use `properties: {}` to tell magic-modules to override nothing in `api.yaml`.

```yaml
--- !ruby/object:Provider::Azure::Ansible::Config
author: <Used in DOCUMENTATION>
version_added: <Used in DOCUMENTATION>

overrides: !ruby/object:Overrides::ResourceOverrides
  <objects[0].name in api.yaml>: !ruby/object:Provider::Azure::Ansible::ResourceOverride
    azure_sdk_definition: !ruby/object:Api::Azure::SDKDefinitionOverride
      create: !ruby/object:Api::Azure::SDKOperationDefinitionOverride
        request:
          <request key in api.yaml>: !ruby/object:Api::Azure::SDKTypeDefinitionOverride
            <SDK attribute overrides>
    properties:
      <property Name>: !ruby/object:Provider::Azure::Ansible::PropertyOverride
        <property attribute overrides>
    examples:
      - !ruby/object:Provider::Azure::Ansible::DocumentExampleReference
        example: <filename in ./examples/anisble>
        resource_name_hints:
          <id_portion of parameters in request>: <Name used in example>
    inttests:
      - !ruby/object:Provider::Azure::Ansible::IntegrationTestDefinition
        example: <filename in ./examples/anisble, main test for resource module>
        delete_example: <filename in ./examples/anisble, used to clean up resources>
        info_by_name_example: <filename in ./examples/anisble, used in info module test>
        info_by_resource_group_example: <filename in ./examples/anisble, used in info module test>

datasources: !ruby/object:Overrides::ResourceOverrides
  <objects[0].name in api.yaml>: !ruby/object:Provider::Azure::Ansible::ResourceOverride
    properties:
      <property Name>: !ruby/object:Provider::Azure::Ansible::PropertyOverride
        <property attribute overrides>
    examples:
      - !ruby/object:Provider::Azure::Ansible::DocumentExampleReference
        example: <filename in ./examples/anisble>
        resource_name_hints:
          <id_portion of parameters in request>: <Name used in example>
```

All items and attributes in `parameters`/`properties` mentioned in `api.yaml` could be overriden by this file.

### Terraform Overrides: terraform.yaml

`terraform.yaml` defines overrides and additional inputs for Terraform. The overall structure is demonstrated below, and please refer to [batchaccount `terraform.yaml`](https://github.com/Azure/magic-module-specs/blob/master/batchaccount/terraform.yaml) as a real-world example.

> Note that `overrides.<object>.properties` itself is required, while all other properties illustrated here are optional. You can simply use `properties: {}` to tell magic-modules to override nothing in `api.yaml`.

```yaml
--- !ruby/object:Provider::Azure::Terraform::Config
overrides: !ruby/object:Overrides::ResourceOverrides
  <objects[0].name in api.yaml>: !ruby/object:Provider::Azure::Terraform::ResourceOverride
    azure_sdk_definition: !ruby/object:Api::Azure::SDKDefinitionOverride
      create: !ruby/object:Api::Azure::SDKOperationDefinitionOverride
        request:
          <request key in api.yaml>: !ruby/object:Api::Azure::SDKTypeDefinitionOverride
            <SDK attribute overrides>
    properties:
      <property Name>: !ruby/object:Provider::Azure::Terraform::PropertyOverride
        <property attribute overrides>
    document_examples:
      - !ruby/object:Provider::Azure::Terraform::DocumentExampleReference
        title: <Title used in documentation>
        example_name: <filename in ./examples/terraform>
        resource_name_hints:
          <id_portion of parameters in request>: <Name used in example>
          location: <Location used in example>
    acctests:
      - !ruby/object:Provider::Azure::Terraform::AccTestDefinition
        name: <Test function name in _test.go>
        steps: [<filenames in ./examples/terraform>]
    custom_code: !ruby/object:Provider::Terraform::CustomCode
      <Customized code snippets for resource, optional>

datasources: !ruby/object:Overrides::ResourceOverrides
  <objects[0].name in api.yaml>: !ruby/object:Provider::Azure::Terraform::ResourceOverride
    properties:
      <property Name>: !ruby/object:Provider::Azure::Terraform::PropertyOverride
        <property attribute overrides>
    datasource_example_outputs:
      <Output variable name used in documentation>: <Output variable attribute>
    acctests:
      - !ruby/object:Provider::Azure::Terraform::AccTestDefinition
        name: <Test function name in _test.go>
        steps: [<filenames in ./examples/terraform>]
```

Please note that it is critical to define `overrides` before `datasources` in `terraform.yaml`, otherwise everything defined in `overrides` will be lost in `datasources`.

All items and attributes in `azure_sdk_definition` and `parameters`/`properties` mentioned in `api.yaml` could be overriden by this file.

## Advanced Topics

### Test Case and Example

One of the advantages not mentioned above is that magic-module for Azure also generates test cases and documentation examples for DevOps tools.

### Customized Code

It is not uncommon that some additional code is required to handle special cases. We support that through customized code snippets.
