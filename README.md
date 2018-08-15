# Hiera AWS Secrets Manager Backend


## Installation
To get the repository on your system:
```bash
git clone git@github.com:unruly/hiera-secrets-manager-backend
```

#### File Location

Once this is developed, this needs to be properly implemented, but rough steps: 

- Move `sm_backend.rb` to where Hiera stores its backend files
    - On local Unruly workstations, this appears to be `/home/dev/.gem/ruby/gems/hiera-1.3.4/lib/hiera/backend`. You can use `locate yaml_backend.rb` to find where the default yaml backend file lives, which should inform your decision.
- Setup your project to use `hiera.yaml` as your Hiera configuration file. 
    - As it stands, Hiera will go from top-to-bottom in terms of backends for hierarchy. 
    - So, in the current `hiera.yaml` file:
```yaml
:backends:
  - sm
  - yaml
```
The "`sm`" backend (which refers to the Secrets Manager `sm_backend.rb`) is priorpitised over the "`yaml`" backend. If a credential is not found on the AWS Secrets Manager, it will proceed to look for it in the yaml files setup.

#### Credentials
The system running this setup will need to have their AWS credentials properly set up, conventionally in a file located at `~/.aws/credentials`. If not already set up, you can obtain your access credentials in AWS, and run `aws configure` to add them to your system.

More information can be found [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)


## Usage

#### With `puppet apply`:

- First, modify the notice the `some_puppet_file_using_hiera.pp` to the name of a credential in your AWS Secrets Manager.
- Then:
 ```bash
 cd hiera-secrets-manager-backend
 puppet apply --hiera_config=hiera.yaml some_puppet_file_using_hiera.pp
# Notice: Scope(Class[main]): <YOUR_PASSWORD>
# Notice: Compiled catalog for <YOUR_SYSTEM> in environment <ENV> in 0.40 seconds
# Notice: Finished catalog run in 0.02 seconds
 ```
 
#### With `hiera` CLI:
This gives a fast feedback loop as to whether the hiera setup on your system is working.

The config flag tells hiera to use the Secrets Manager backend, the debug flag will show you it's working :)
```bash
 cd hiera-secrets-manager-backend
hiera <CREDENTIAL_IN_HIERA> --config hiera.yaml --debug
#DEBUG: 2018-08-15 15:52:34 +0000: AWS Secrets Manager Hiera backend starting
#<YOUR_PASSWORD>

```
