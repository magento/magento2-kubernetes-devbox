# Tests for Magento 2 Kubernetes DevBox project

Current project contains functional tests for [Kubernetes DevBox for Magento 2 Developers](https://github.com/magento/magento2-kubernetes-devbox) project.

## To run the tests:

 1. Make sure that your host meets requirements listed [here](https://github.com/magento/magento2-kubernetes-devbox#requirements)
 1. Copy [configuration.sh.dist](include/configuration.sh.dist) to `include/configuration.sh` and make necessary changes
 1. Copy [auth.json.dist](include/auth.json.dist) to `include/auth.json` and add valid keys. This step is required only for testing of Composer-based installations
 1. Run [NoCustomConfigBasicTest.sh](NoCustomConfigBasicTest.sh) or any other test in bash
