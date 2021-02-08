# Hiera AWS Secrets Manager Backend :key:

[![Build Status](https://travis-ci.org/unruly/hiera-secrets-manager.svg?branch=master)](https://travis-ci.org/unruly/hiera-secrets-manager)
[![Gem Version](https://badge.fury.io/rb/hiera-secrets-manager.svg)](https://badge.fury.io/rb/hiera-secrets-manager)

A hiera backend to query AWS Secrets Manager which uses Puppet Environments for namespacing.

```bash
$ hiera 'my_system/password' \
    environment=prod \
    --config ~/hiera.yaml \
    --debug

DEBUG: 2018-08-30 16:54:00 +0000: AWS Secrets Manager backend starting
DEBUG: 2018-08-30 16:54:00 +0000: Retrieved Secret 'production/my_system/password' with version '2d06f591-ef4c-4e4e-8c6c-5e3668db9180'

mYs3cR3TpAs5W0rD
```

## Contents

- [Install](#install)
- [Supported Lookups](#supported-lookups)
- [Configuration](#configuration)
  - [Region](#region)
  - [Credentials](#credentials)
  - [Environments](#environments)
- [Contributing](#contributing)
  - [Code of Conduct](#code-of-conduct)
  - [Getting Started](#getting-started)
  - [Building](#building)
  - [Releasing a Change](#releasing-a-change)
- [License](#license)

## Install

To install the gem manually:

```bash
gem install hiera-secrets-manager
```

Install the dependencies before attempting to use the gem:

```
bundle install
```

## Supported Lookups

hiera-secrets-manager supports `:priority` (single value) and `:hash` (key-value pair) lookups, but not `:array`.

### Priority Lookup

```puppet
# In environment 'production' with 'production/system/my-secret' set as 'some-password'
$secret = hiera('system/my-secret')

notice($secret) # prints 'Notice: Scope(Class[main]): some-password'
```

### Hash Lookup

```puppet
# In environment 'production' with 'production/system/my-secret' set as pairs 'foo:bar' and 'baz:zap'
$secret = hiera_hash('system/my-secret')

notice($secret['foo']) # prints 'Notice: Scope(Class[main]): bar'
notice($secret['baz']) # prints 'Notice: Scope(Class[main]): zap'

notice($secret) # prints 'Notice: Scope(Class[main]): {"foo"=>"bar", "baz"=>"zap"}'
```

### hieradata Lookup

```yaml
---
# In an environment with fact init_env => test and confine_to_keys set, lookup secret test/my_hiera_secret-my-secret with key 'foo'
mysecret: "%{hiera('my_hiera_secret-my-secret::foo')}"

```

```puppet
$hieradata_secret = hiera('mysecret')
notice($hieradata_secret)
```

## Configuration

Hiera Secrets Manager is configurable and the configuration has three required fields to operate: region, access_key_id, and secret_access_key.

An example hiera.yaml file implementing only hiera-secrets-manager is below:

```yaml
:backends:
  - secrets_manager
:secrets_manager:
    :region: eu-west-1
    :access_key_id: AWSACCESSKEY
    :secret_access_key: rAnd0MsTr!nG
    :env: "%{::init_env}" # facter lookup
    :confine_to_keys:
    - '^my_hiera_secret.*' 
```

An example hiera.yaml file implementing IAM auth
```yaml
:backends:
  - secrets_manager
:secrets_manager:
  :region: eu-west-1
  :iam_client: true     # Use IAM Authentication
  :environments:
    dev: development
    uat: staging
    prod: production
  :confine_to_keys:
    - '^my_hiera_secret.*'
```
### Region

Mandatory field. Corresponds to AWS Region where your secrets are stored e.g. `eu-west-1`

### Credentials

Credentials for the AWS user are mandatory. The user must have permission to use `secretsmanager:GetSecretValue` on any relevant secrets in AWS Secrets Manager. This permission can be configured in AWS IAM.

### Environments

Optional field. When used with Puppet, an environment will always be present. These key value pairs map the environments in Puppet to namespaces in AWS.

```yaml
:environments:
    dev: development
    uat: staging
    prod: production
```

- A lookup for key `foo` in environment `dev` will query AWS Secrets Manager for `development/foo`

If there is no key set for an environment, or no environments configuration at all, the secret name that will be queried in AWS Secrets Manager will by default  be prefixed with the Puppet environment name:

- A lookup for key `zap` in environment `test` will query AWS Secrets Manager for `test/zap`, because there's no entry for `test` in the environments configuration.

# IAM Client

Optional field. Use IAM instance credentials, must have permission to use `secretsmanager:GetSecretValue` on any relevant secrets in AWS Secrets Manager.

```yaml
  :iam_client: true
```

# Env

Optional field. Lookups will be performed against a defined environment name instead of a puppet environment name
e.g
- A facter variable init_env set to `env1` 
- hiera lookup to `my_hiera_secret-my-secret` will query for AWS Secrets Manager for `env1/my_hiera_secret-my-secret`

```yaml
  :env: "%{::init_env}"
```

# Confine keys

Optional field. Limit AWS Secret Mananager lookups to secrets prefixed with confined_to_keys wildcards

```yaml
  :confine_to_keys:
    - '^my_hiera_secret.*'
```

## Contributing

### Code of Conduct

Everyone interacting with this project is required to follow the [Code of Conduct](./CODE_OF_CONDUCT.md).

### Getting Started

You'll need Git, Ruby, and Bundler installed. 
Then clone this project, and install its dependencies:

```bash
$ git clone git@github.com:unruly/hiera-secrets-manager
$ bundle install
```

You can run `rake` in the project root to run RSpec tests, and check test coverage.

### Building

- To build a gem on your local machine, run `gem build hiera-secrets-manager.gemspec`, which will create a .gem file with the current version number.
- Install the gem with `gem install hiera-secrets-manager-{VERSION}.gem`, specifying the version number.

### Releasing a Change

- To release a new version:
  - Update the version number in `hiera-secrets-manager.gemspec`
  - Ensure versions are in line with the [Semantic Versioning](https://semver.org/) convention.
  - Open a pull request against this repository.

## License

The gem is available as open source under the terms of the [MIT License](./LICENSE.md).
