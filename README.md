# Porter Example

This is an example of how we could use porter and CNAB do the following things:

- [x] Deploy terraform to azure using a azurerm tfstate
- [ ] Deploy some bicep to azure
- [x] Deploy a k8s namespace
- [x] Deploy an application via helm to the namespace

## Getting started

To get started

- Create a credential set using `porter credentials generate`
- Create a parameters set using `porter parameters generate`
- Use `porter install` to deploy the bundle
