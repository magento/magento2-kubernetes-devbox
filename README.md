# Magento 2 Kubernetes DevBox

[![Build Status](https://travis-ci.com/magento/magento2-kubernetes-devbox.svg?branch=master)](https://travis-ci.com/magento/magento2-kubernetes-devbox)
<!--[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)-->
<!--[![Semver](http://img.shields.io/SemVer/2.0.0.png?color=blue)](http://semver.org/spec/v2.0.0.html)-->
<!--[![Latest GitHub release](docs/images/release_badge.png)](https://github.com/paliarush/magento2-vagrant-for-developers/releases/latest)-->

 * [What You get](#what-you-get)
 * [How to install](#how-to-install)
   * [Requirements](#requirements)
   * [Installation steps](#installation-steps)
   * [Default credentials and settings](#default-credentials-and-settings)
   * [Getting updates and fixes](#getting-updates-and-fixes)
 * [Day-to-day development scenarios](#day-to-day-development-scenarios)
   * [Access Magento](#access-magento)
   * [Reinstall Magento](#reinstall-magento)
   * [Clear Magento cache](#clear-magento-cache)
   * [Switch between CE and EE](#switch-between-ce-and-ee)
   * [Sample data installation](#sample-data-installation)
   * [Basic data generation](#basic-data-generation)
   * [Use Magento CLI (bin/magento)](#use-magento-cli-binmagento)
   * [Debugging with XDebug](#debugging-with-xdebug)
   * [Connecting to MySQL DB](#connecting-to-mysql-db)
   * [View emails sent by Magento](#view-emails-sent-by-magento)
   * [Accessing PHP and other config files](#accessing-php-and-other-config-files)
   * [Upgrading Magento](#upgrading-magento)
   * [Multiple Magento instances](#multiple-magento-instances)
   * [Update Composer dependencies](#update-composer-dependencies)
   * [Running Magento tests](#running-magento-tests)
 * [Environment configuration](#environment-configuration)
   * [Switch between PHP versions](#switch-between-php-versions)
   * [Activating Varnish](#activating-varnish)
   * [Activating ElasticSearch](#activating-elasticsearch)
   * [Redis for caching](#redis-for-caching)
   * [Reset environment](#reset-environment)
   * [Switch NodeJS Versions](#switch-nodejs-versions)
 * [DevBox tests](#devbox-tests)
 * [FAQ](#faq)

## What You get

:warning: This project is under development and may become official Magento DevBox in the future. There is also a [DevBox for Magento Cloud](https://github.com/magento/magento-cloud-docker).

It's expected that the Magento 2 project source code will be located and managed on the host to allow quick indexing of project files by IDE. All other infrastructure is deployed in kubernetes cluster on Minikube.

Current DevBox aims to support multi-service multi-instance deployment in one click. Multiple Magento projects should be installed in a single Kubernetes cluster and share resoruces. Each of the Magento projects may be deployed as a monolith or a set of services. The DevBox is optimized for development scenarios using local environment.

The environment also suitable for for Magento Commerce and Magento B2B development.

<!--It is easy to [install multiple Magento instances](#multiple-magento-instances) based on different codebases simultaneously.-->

The [project initialization script](init_project.sh) configures a complete development environment:

<!-- 1. Adds some missing software on the host -->
 1. Configures all software necessary for Magento 2: Nginx, PHP 7.x, MySQL 5.6, Git, Composer, XDebug, Redis, Rabbit MQ, Varnish
 1. Installs Magento 2 from Git repositories or Composer packages (can be configured via `checkout_source_from` option in [etc/instance/config.yaml](etc/instance/config.yaml.dist))
<!-- 1. Configures PHP Storm project (partially at the moment)-->
<!-- 1. Installs NodeJS, NPM, Grunt and Gulp for front end development

  :information_source: This box uses the [n package manager](https://www.npmjs.com/package/n) to provide the latest NodeJS LTS version.<br />
-->
## How to install

If you never used Kubernetes before, read the [Kubernetes Docs](https://kubernetes.io) first.

### Requirements

The software listed below should be available in [PATH](https://en.wikipedia.org/wiki/PATH_\(variable\)) (except for PHP Storm).

- [Docker](https://docs.docker.com/docker-for-mac/install/)
- [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/)
- [Helm](https://docs.helm.sh/using_helm/#installing-helm)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) - Ensure that SSH keys are generated and associated with your Github account. See [how to check](https://help.github.com/articles/testing-your-ssh-connection/) and [how to configure](https://help.github.com/articles/generating-ssh-keys/), if not configured.<br />
  :information_source: To obtain the codebase without cloning, just use the Magento 2 codebase instead of `devbox-magento/magento2ce`. Either method will produce a successful installation.<br />

<!--  :information_source: On Windows hosts ![](docs/images/windows-icon.png) Git must be [v2.7+](http://git-scm.com/download/win). Also make sure to set the following options to avoid issues with incorrect line separators:

    ```
    git config --global core.autocrlf false
    git config --global core.eol LF
    git config --global diff.renamelimit 5000
    ```
-->
- [PHP Storm](https://www.jetbrains.com/phpstorm), optional but recommended. To get Helm support in PhpStorm make sure to get v2018.3+
- [NFS server](https://en.wikipedia.org/wiki/Network_File_System) ![](docs/images/linux-icon.png)![](docs/images/osx-icon.png) must be installed and running on \*nix and OSX hosts; usually available, follow [installation steps](#how-to-install) first

### Installation steps

:information_source: In case of any issues during installation, please read [FAQ section](#faq)

 1. Open terminal and change your directory to the one you want to contain Magento project. <!--![](docs/images/windows-icon.png) On Windows use Git Bash, which is available after Git installation.-->

 1. Download or clone the project with DevBox configuration:
    
    :warning: Do not open it in PhpStorm until `init_project.sh` has completed PhpStorm configuration in the initialize project step below.

     ```bash
     git clone --recursive git@github.com:magento/magento2-kubernetes-devbox.git magento2-devbox
     ```

    Optionally, if you use private repositories on GitHub or download packages from the Magento Marketplace using Composer.

     1. Copy [etc/composer/auth.json.dist](etc/composer/auth.json.dist) to `etc/composer/auth.json`.
     1. Specify your GitHub token by adding `"github.com": "your-github-token"` to the `github-oauth` section for GitHub authorization.
     1. Add the Magento Marketplace keys for Marketplace authorization to the `repo.magento.com` section.
     1. Copy (optional) [etc/instance/config.yaml.dist](etc/instance/config.yaml.dist) as `etc/instance/<instance_name>.yaml` and make the necessary customizations. Instance name is Magento instance identifier that can only include letters and numbers.
     1. Copy (optional) [etc/env/config.yaml.dist](etc/env/config.yaml.dist) as `etc/env/config.yaml` and make the necessary customizations.

 1. Initialize the project (this will configure the environment, install Magento<!--, and configure the PHPStorm project-->):

    ```bash
    cd magento2-devbox
    
    # NFS configuration is needed just once for each project, it will prompt for your password to make changes on the host
    
    bash scripts/host/configure_nfs_exports.sh
    
    bash init_project.sh
    ```
    <!--
    To initialize project with checkout container,
    clone sources to checkout directory and use -e parameter to init_project.sh call.
    ```bash
    bash init_project.sh -e
    ```
    -->
    
 1. Use the `magento2-devbox` directory as the project root in PHP Storm (not `magento2-devbox/magento`). This is important, because in this case PHP Storm will be configured automatically by [init_project.sh](init_project.sh).<!-- If NFS files sync is disabled in [config](etc/instance/config.yaml.dist) and ![](docs/images/windows-icon.png)on Windows hosts [verify the deployment configuration in PHP Storm](docs/phpstorm-configuration-windows-hosts.md).-->

    <!--Use the URL for accessing your Magento storefront in the browser as your Web server root URL. Typically this is the localhost, which refers to your development machine. Depending on how you've set up your VM you may also need a port number, like `http://localhost:8080`.-->

 1. Configure the remote PHP interpreter in PHP Storm. Go to Preferences, then Languages and Frameworks. Click PHP and add a new remote interpreter. Select Deployment configuration as a source for connection details.

### Default credentials and settings

Some of default settings are available for override. These settings can be found in the [etc/instance/config.yaml.dist](etc/instance/config.yaml.dist) and [etc/env/config.yaml.dist](etc/env/config.yaml.dist).

To override settings create a copy of [etc/env/config.yaml.dist](etc/env/config.yaml.dist) under the name 'config.yaml' and add your custom settings.

You can create multiple copies of [etc/instance/config.yaml.dist](etc/instance/config.yaml.dist), each of those copies will be responsible for a separate Magento instance deployed in the DevBox. Config file name must only include alpha-numeric characters and will be used to isolate instances (for instance domain name generation, DB name etc).

<!--When using [init_project.sh](init_project.sh), if not specified manually, random IP address is generated and is used as suffix for host name to prevent collisions, in case when two or more instances are running at the same time.-->

Upon a successful installation, you'll see the location and URL of the newly-installed Magento 2 application in console.

**Web access**:
- Access storefront at `http://magento.<instance_name>` (can be found in `etc/instance/<instance_name>.yaml`)
- Access admin panel at `http://magento.<instance_name>/admin/`
- Magento admin user/password: `admin/123123q`
- Rabbit MQ control panel: run `bash k-open-rabbitmq`, credentials `admin`/`123123q`

:information_source: Your admin URL, storefront URL, and admin user and password are located in `etc/instance/<instance_name>.yaml`.

**Codebase and DB access**:
- Path to your Magento installation in the container is the same as on the host
  <!-- - Can be retrieved from environment variable: `echo ${DEVBOX_ROOT}/` -->
  <!--  - ![](docs/images/windows-icon.png) On Windows hosts: `/var/www/magento`-->
  <!-- - ![](docs/images/linux-icon.png)![](docs/images/osx-icon.png) On Mac and \*nix hosts: the same as on host -->
- MySQL DB host: 
  - inside the container: `localhost`
  - remotely: run `minikube ip` to get the IP and use port `30306`
- MySQL DB name: `magento_<instance_name>`, `magento_<instance_name>_integration_tests`
- MySQL DB user/password: `root:123123q`

**Codebase on host**
- CE codebase: `magento2-devbox/<instance_name>`
- Magento Commerce codebase will be available if path to commerce repository is specified in `etc/instance/<instance_name>.yaml`: `magento2-devbox/<instance_name>/magento2ee`

### Getting updates and fixes

Current devbox project follows [semantic versioning](http://semver.org/spec/v2.0.0.html) so feel free to pull the latest features and fixes, they will not break your project.
For example your current branch is `2.0`, then it will be safe to pull any changes from `origin/2.0`. However branch `3.0` will contain changes backward incompatible with `2.0`.
Note, that semantic versioning is only used for `x.0` branches (not for `develop` or `master`).

:information_source: To apply changes run `bash k-upgrade-environment`.

## Day-to-day development scenarios

### Access Magento

Use the following command to open current instance:
```bash
./m-open
```

Hostname can also be found in `magento/host_name` section of [etc/instance/<instance_name>.yaml](etc/instance/config.yaml.dist).

### Reinstall Magento

Use commands described in [Switch between CE and EE](#switch-between-ce-and-ee) section with `-f` flag. Before doing actual re-installation, these commands update linking of EE codebase, clear cache, update composer dependencies.

If no composer update and relinking of EE codebase is necessary, use the following command. It will clear Magento DB, Magento caches and reinstall Magento instance.

Go to the root of the project in command line and execute:

```bash
./m-reinstall
```

### Clear Magento cache

Go to the root of the project in command line and execute:

```bash
./m-clear-cache
```

### Switch between CE and EE

Assume, that EE codebase is available in `magento2-devbox/magento/magento2ee`.
The following commands will link/unlink EE codebase, clear cache, update composer dependencies and reinstall Magento.
Go to 'magento2-devbox' created earlier and run in command line:

```bash
./m-switch-to-ce
# OR
./m-switch-to-ee
```

Force switch can be done using `-f` flag even if already switched to the target edition. May be helpful to relink EE modules after switching between branches.

Upgrade can be performed instead of re-installation using `-u` flag.

<!--:information_source: On Windows hosts (or when NFS mode is disabled in [config.yaml](etc/instance/config.yaml.dist) explicitly) you will be asked to wait until code is uploaded to guest machine by PhpStorm (PhpStorm must be launched). To continue the process press any key.-->

### Sample data installation

Make sure that `ce_sample_data` and `ee_sample_data` are defined in [etc/instance/<instance_name>.yaml](etc/instance/config.yaml.dist) and point CE and optionally EE sample data repositories.
During initial project setup or during `bash init_project.sh -fc` (with `-fc` project will be re-created from scratch), sample data repositories willl be checked out to `magento2-devbox/magento/magento2ce-sample-data` and `magento2-devbox/magento/magento2ee-sample-data`.

To install Magento with sample data specify/uncomment sample data repository link at `repository_url_additional_repositories` in [etc/instance/<instance_name>.yaml](etc/instance/config.yaml.dist) and run `./m-switch-to-ce -f` or `./m-switch-to-ee -f`, depending on the edition to be installed. To disable sample data, comment out additional repositories and force-switch to necessary edition (using the same commands).

### Basic data generation

Several entities are generated for testing purposes by default using REST API after Magento installation:
- Customer with address (credentials `customer@example.com`:`123123qQ`)
- Category
- Couple simple products
- Configurable product

To disable this feature, set `magento/generate_basic_data` in [etc/instance/<instance_name>.yaml](etc/instance/config.yaml.dist) to `0` and run `./m-switch-to-ce -f` or `./m-switch-to-ee -f`, depending on the edition to be installed.

### Use Magento CLI (bin/magento)

Go to 'magento2-devbox' created earlier and run in command line:

```bash
./m-bin-magento <command_name>
# e.g.
./m-bin-magento list
```

### Debugging with XDebug

XDebug is already configured to connect to the host machine automatically. So just:

 1. Set XDEBUG_SESSION=1 cookie (e.g. using 'easy Xdebug' extension for Firefox). See [XDebug documentation](http://xdebug.org/docs/remote) for more details
 1. Start listening for PHP Debug connections in PhpStorm on default 9000 port. See how to [integrate XDebug with PhpStorm](https://www.jetbrains.com/phpstorm/help/configuring-xdebug.html#integrationWithProduct)
 1. Set beakpoint or set option in PhpStorm menu 'Run -> Break at first line in PHP scripts'

<!--To debug a CLI script:

 1. Create [remote debug configuration](https://www.jetbrains.com/help/phpstorm/2016.1/run-debug-configuration-php-remote-debug.html) in PhpStorm, use `phpstorm` as IDE key
 1. Run created remote debug configuration
 1. Run CLI command on the guest as follows (`xdebug.remote_host` value might be different for you):

 ```bash
 php -d xdebug.remote_autostart=1 <path_to_cli_script>
 ```

To debug Magento Setup script, go to [Magento installation script](scripts/guest/m-reinstall) and find `php ${install_cmd}`. Follow steps above for any CLI script

:information_source: In addition to XDebug support, [config.yaml](etc/instance/config.yaml.dist) has several options in `debug` section which allow storefront and admin UI debugging. Plus, desired Magento mode (developer/production/default) can be enabled using `magento_mode` option, default is developer mode.
-->
### Connecting to MySQL DB

Go to 'magento2-devbox' created earlier and run in command line:

```bash
bash k-ssh-mysql
```

After successful login to the container run the following command and enter `123123q` when prompted for a password:

```bash
mysql -uroot -p
```

To connect remotely run `minikube ip` to get the IP and use port `30306`

### View emails sent by Magento

Not available yet.
<!--All emails are saved to 'magento2-devbox/log/email' in HTML format.-->

### Accessing PHP and other config files

The following configuration files are used by default:
- [NGINX](etc/helm/templates/configmap.yaml)
- PHP-FPM: [ini](scripts/etc/php-fpm.ini), [conf](scripts/etc/php-fpm.conf)
- [xDebug](scripts/etc/php-xdebug.ini)
- [Dockerfile for monolith base image](scripts/Dockerfile)
- [Actually applied Dockerfile for monolith with customizations](etc/docker/monolith/Dockerfile)
- [Actually applied Dockerfile for monolith with xDebug and customizations](etc/docker/monolith-with-xdebug/Dockerfile)
- [Kubernetes config for Monolith](etc/helm/templates/magento2-deployment.yaml)
- [Kubernetes Helm variables](etc/helm/values.yaml)
<!--- [Configs for Checkout service](etc/helm/charts/checkout)-->
<!--It is possible to view/modify majority of guest machine config files directly from IDE on the host. They will be accessible in [etc/guest](etc/guest) directory only when guest machine is running. The list of accessible configs includes: PHP, Apache, Mysql, Varnish, RabbitMQ.
Do not edit any symlinks using PhpStorm because it may break your installation.

After editing configs in IDE it is still required to restart related services manually.
-->
### Upgrading Magento

Sometimes it is necessary to test upgrade flow. This can be easily done as follows (assuming that you have installed instance):

 - For git-based installation - check out codebase corresponding to the target Magento version. Or modify your `composer.json` in case of composer-based installation
 - Use commands described in [Switch between CE and EE](#switch-between-ce-and-ee) section with `-u` flag

### Multiple Magento instances

Not available yet.
<!--To install several Magento instances based on different code bases, just follow [Installation steps](#installation-steps) to initialize project in another directory on the host.
Unique IP address, SSH port and domain name will be generated for each new instance if not specified manually in `etc/config.yaml`
-->
### Update Composer dependencies

Go to 'magento2-devbox' created earlier and run in command line:

```bash
./m-composer install
# OR
./m-composer update
```

### Running Magento tests

See [how to run Magento tests from PhpStorm using remote PHP in Kubernetes cluster](docs/running-tests/running-tests.md)


## Environment configuration

### Switch between PHP versions

Not available yet.
<!--Switch between PHP versions using "php_version: <version>" option in [config.yaml](etc/instance/config.yaml.dist). Supported versions are 5.6, 7.0, 7.1 and 7.2.
PHP version will be applied after "devbox reload".
-->

### Activating Varnish

Use the following commands to enable/disable varnish <!--without reinstalling Magento-->: `m-varnish disable` or `m-varnish enable`.

You can also set `use_varnish: 1` in [etc/env/config.yaml](etc/env/config.yaml.dist) to use varnish. Changes will be applied on `init_project.sh -f`.

The VCL content can be found in [configmap.yaml](etc/helm/templates/configmap.yaml).

### Activating ElasticSearch

Set `search_engine: "elasticsearch"` in [etc/env/config.yaml](etc/env/config.yaml.dist) to use ElasticSearch as current search engine or `search_engine: "mysql"` to use MySQL. Changes will be applied on `m-reinstall`.

Use the following commands to switch between search engines without reinstalling Magento: `m-search-engine elasticsearch` or `m-search-engine mysql`.

### Redis for caching

<!--:information_source: Available in Magento v2.0.6 and higher.-->

Redis is configured as cache backend by default. <!--It is still possible to switch back to filesystem cache by changing `environment_cache_backend` to `filesystem` in [config.yaml](etc/instance/config.yaml.dist).-->

### Reset environment

It is possible to reset project environment to default state, which you usually get just after project initialization. The following command will re-initialize Kubernetes cluster. Magento 2 code base (`magento` directory) and [etc/instance/<instance_name>.yaml](etc/instance/config.yaml.dist) and PhpStorm settings will stay untouched<!--, but guest config files (located in [etc/guest](etc/guest)) will be cleared-->.

Go to 'magento2-devbox' created earlier and run in command line:

```bash
./init_project.sh -f
```

It is possible to reset Magento 2 code base at the same time. Magento 2 code base will be deleted and then cloned from the repositories specified in [etc/config.yaml](etc/instance/config.yaml.dist)

```bash
./init_project.sh -fc
```

To reset PhpStorm project configuration, in addition to `-f` specify `-p` option:

```bash
./init_project.sh -fp
```

Ultimate project reset can be achieved by combining all available flags:

```bash
./init_project.sh -fcp
```

### Switch NodeJS Versions

NodeJS not available yet.
<!--
By default, the box will install the latest `NodeJS LTS` version using the [n package manager](https://www.npmjs.com/package/n). If you need another version of `Node` because of Magento's `package.json` requirements, simply run:

```js
n <version>
```

Note: See [Working with npm](https://www.npmjs.com/package/n#working-with-npm) if after switching versions with `n`, `npm` is not working properly.
-->

### DevBox tests

The tests are executed on every PR on Travis CI. It is possible to configure the same tests to run on the forked repository.
In order to run composer-based Magento tests for the fork, repo.magento.com credentials must be set to `COMPOSER_AUTH` [environment variable](https://docs.travis-ci.com/user/environment-variables/#defining-variables-in-repository-settings) on Travis CI, the variable value should be:
```json
'{"http-basic": {"repo.magento.com": {"username": "<public_key>","password": "<secret_key>"}}}'
```

An extended testsuite by default is executed against the master branch only.
It is possible to execute an extended testsuite on every build by commenting out `if: branch = master` in the [.travis.yaml](./.travis.yml)

The same tests can be run on local using the following command. :warning: only one devbox can be running on the same host at the same time. The tests will destroy existing devbox installation.

```bash
cd tests
bash ./<test-name>.sh
```

### FAQ
 1. To debug any CLI script in current Devbox project, set `debug:devbox_project` option in [etc/env/config.yaml](etc/env/config.yaml.dist) to `1`
 1. Make sure that you used `magento2-devbox` directory as project root in PHP Storm (not `magento2-devbox/magento`)
 1. If project opened in PhpStorm looks broken, close PhpStorm  and remove `magento2-devbox/.idea`. Run `./magento2-devbox/scripts/host/configure_php_storm.sh`. After opening project in PhpStorm again everything should look good
 1. Please make sure that currently installed software, specified in [requirements section](#requirements), meets minimum version requirement
 1. Be careful if your OS is case-insensitive, NFS might break the symlinks if you cd into the wrong casing and you power the devbox up. Just be sure to cd in to the casing the directory was originally created as.
 1. Cannot run unit tests from PHPStorm on Magento 2.2, see possible solution [here](https://github.com/paliarush/magento2-vagrant-for-developers/issues/167)
 1. [Permission denied (publickey)](https://github.com/paliarush/magento2-vagrant-for-developers/issues/165)
 1. If you get [minikube time out error restarting cluster](https://github.com/kubernetes/minikube/issues/3843) while initializing project, run `minikube stop && minikube delete && ./init_project.sh`.
 1. To modify the docker image used for php-fpm container:
    * Make changes in `etc/docker/monolith/Dockerfile`
    * Run `./k-upgrade-environment`
    * Run `./k-status` to open kubernetes dashboard and delete Replica Set named `magento2-monolith-*`. The container should be restarted and its Age should reset
