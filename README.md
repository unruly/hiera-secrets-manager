# Hiera AWS Secrets Manager Backend

[![Build Status](https://travis-ci.org/unruly/hiera-secrets-manager.svg?branch=master)](https://travis-ci.org/unruly/hiera-secrets-manager)

## Installation
To get the repository on your system:
```bash
git clone git@github.com:unruly/hiera-secrets-manager
```

#### File Location

Once this is developed, this needs to be properly implemented, but rough steps: 

- Move `secrets_manager_backend.rb` to where Hiera stores its backend files
    - Using the mlocate CLI tool, you can run `locate yaml_backend.rb` to find where the default YAML backend file lives, which should inform your decision.

#### Credentials
The system running this setup will need to have their AWS credentials properly set up, conventionally in a file located at `~/.aws/credentials`. If not already set up, you can obtain your access credentials in AWS, and run `aws configure` to add them to your system.

More information can be found [here.](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)


## Usage

#### With `puppet apply`:

Once your project has correctly set the backend up, you can use the Puppet CLI tools to check your connection.
<br/>
- First, create a local Puppet file (e.g. `some_puppet_file_using_hiera.pp`).
- In the Puppet file, use the `hiera()` function to ask Hiera to fetch a credential in your AWS Secrets Manager. For example:
```puppet
notice(hiera('the_name_of_some_credential_in_secrets_manager'))
```
- Create a `hiera.yaml` Hiera config file, and tell it to use the Secrets Manager backend:
```yaml
:backends:
  - secrets_manager
```
- Then, run `puppet apply` using the `--hiera_config` flag to point to the Hiera config file:
 ```bash
 puppet apply --hiera_config=/path/to/hiera.yaml /path/to/some_puppet_file_using_hiera.pp
# Notice: Scope(Class[main]): <YOUR_PASSWORD>
# Notice: Compiled catalog for <YOUR_SYSTEM> in environment <ENV> in 0.40 seconds
# Notice: Finished catalog run in 0.02 seconds
 ```
 
#### With `hiera` CLI:
This gives a faster feedback loop as to whether the hiera setup on your system is working.

- Follow the same steps as above to create a `hiera.yaml` file pointing to the Secrets Manager backend.
- Use the Hiera CLI tool to query the Secrets Manager backend, using the aforementioned config file, optionally using the debug flag:
    - The config flag tells Hiera to use the Secrets Manager backend, and the debug flag will show you that it's working.
```bash
cd hiera-secrets-manager-backend
hiera <CREDENTIAL_IN_HIERA> --config hiera.yaml --debug
#DEBUG: 2018-08-15 15:52:34 +0000: AWS Secrets Manager Hiera backend starting
#<YOUR_PASSWORD>
```

#### Integrate into your own Puppet projects
TBC
