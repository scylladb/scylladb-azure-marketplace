# ScyllaDB on Azure VMSS

This creates a Solution Template for ScyllaDB and publishes it to the Azure Marketplace.

The Marketplace Publisher is determined by the Access of the Service Principal.
The offer details are set in the `listing_config.json`.
Only one plan per configuration file is currently supported.

## Testing
The tests for this application are located in `tests/solution-template/scylladb-vmss`.
A `main.bicep` file and `main.parameters.json` can be used to test the deployment of the Managed Application.
The default version should be updated to stable releases.
Use this to easily deploy Scylla DB without having to use the Azure portal.

## Virtual Network
Enable VNET to secure network traffic.
Some regions also offer zone redudancies, which can also be enabled (when enabled, it will be ignored for unspported regions).
You may either create a new VNET or use an existing VNET, as long as the proper access permissions are granted.

## Validate Setup
Connect via SSH to confirm the deployment was succesful.
Use the Portal to confirm the network settings are correct.
If Scylla DB does not start up automatically, it may be due to using an un-optimized skew.
Directions to start Scylla DB will be provided at login to any VM.
