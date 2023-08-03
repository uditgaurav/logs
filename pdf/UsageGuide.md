# Register Harness Chaos Infrastructure

This command-line interface (CLI) is used to register a new Harness Chaos infrastructure using specific parameters including a given name, namespace, API key, and account ID. Apart from creating a new chaos infrastructure, the onboard_hce_aws register command also performs a variety of tasks that streamline the onboarding process:

1. **ChaosInfra Setup:** It can install the chaos infrastructure in the given namespace of your cluster using Harness APIs and Kubernetes permissions. After installation, it will test the activation of the infrastructure for a given timeout (default to 180s).

2. **Add OIDC Provider:** It can add the OIDC provider in the target account provided using AWS credentials. If the given provider already exists, the CLI will issue a warning and skip this step.

3. **AWS Roles:** If the user opts to create a dedicated role for HCE, the CLI will do so. Alternatively, if you already have a role, you can provide it as an input, and that role will be attached to the provider added previously.

4. **Annotate Service Account:** Finally, the CLI will annotate the experiment service account on the cluster with AWS roleARN after all the configuration is done.


## Usage

```code
$ ./onboard_hce_aws register --api-key your_api_key --account-id your_account_id --infra-name your_infra_name --project your_project --optional-flags
```

### Mandatory Flags (For Install ChaosInfra)

| Flag         | Description                                          | Example                   |
|--------------|------------------------------------------------------|---------------------------|
| `--api-key` | API Key for Harness (required) | `--api-key abc123` |
| `--account-id` | Account ID for Harness (required) | `--account-id def456` |
| `--infra-name` | Name of the Harness Chaos infrastructure (required) | `--infra-name infra-name` |
| `--project` | Project Identifier (required) | `--project project_id` |

### Harness and Infra Details

| Flag                           | Description                                                                                       | Default                                   | Example                                      |
|--------------------------------|---------------------------------------------------------------------------------------------------|-------------------------------------------|----------------------------------------------|
| `--api-key`                    | API Key for Harness                                                                               | ""                                        | `--api-key your-api-key`                     |
| `--account-id`                 | Account ID for Harness                                                                            | ""                                        | `--account-id your-account-id`               |
| `--infra-name`                 | Name of the Harness Chaos infrastructure                                                          | ""                                        | `--infra-name your-infra-name`               |
| `--project`                    | Project Identifier                                                                                | ""                                        | `--project your-project-id`                  |
| `--infra-namespace`            | Namespace for the Harness Chaos infrastructure                                                    | "hce"                                     | `--infra-namespace custom-namespace`         |
| `--organisation`               | Organisation Identifier                                                                           | "default"                                 | `--organisation organisation_id`             |
| `--infra-scope`                | Infrastructure Scope                                                                              | "namespace"                               | `--infra-scope cluster`                      |
| `--infra-ns-exists`            | Does infrastructure namespace exist                                                               | true                                      | `--infra-ns-exists false`                    |
| `--infra-description`          | Infra Description                                                                                 | "Infra for Harness Chaos Testing"         | `--infra-description "custom description"`   |
| `--infra-service-account`      | Infra Service Account                                                                             | "hce"                                     | `--infra-service-account custom-account`     |
| `--is-infra-sa-exists`         | Does infrastructure service account exist                                                         | false                                     | `--is-infra-sa-exists true`                  |
| `--infra-environment-id`       | Infra Environment ID                                                                              | ""                                        | `--infra-environment-id environment_id`      |
| `--infra-platform-name`        | Infra Platform Name                                                                               | ""                                        | `--infra-platform-name platform_name`        |
| `--infra-skip-ssl`             | Skip SSL for Infra                                                                                | false                                     | `--infra-skip-ssl true`                      |
| `--timeout`                    | Timeout For Infra setup                                                                           | 180                                       | `--timeout 200`                              |
| `--delay`                      | Delay between checking the status of Infra                                                        | 2                                         | `--delay 5`                                  |
| `--config`                     | Config file containing parameters                                                                 | ""                                        | `--config register.json`                       |



### AWS Details

| Flag                           | Description                                                                                       | Default                                   | Example                                      |
|--------------------------------|---------------------------------------------------------------------------------------------------|-------------------------------------------|----------------------------------------------|
| `--provider-url`               | Provider URL                                                                                      | ""                                        | `--provider-url https://provider.com`        |
| `--role-name`                  | Role Name                                                                                         | ""                                        | `--role-name example_role`                   |
| `--resources`                  | Resources                                                                                         | "all"                                     | `--resources ec2-state,rds,lambda`           |
| `--region`                     | Target AWS Region                                                                                 | ""                                        | `--region us-east-2`                         |
| `--service-account`            | Experiment Service Account Name                                                                   | "litmus-admin"                            | `--service-account custom-account`           |
| `--kubeconfig-path`            | Path to the kubeconfig file                                                                       | ""                                        | `--kubeconfig-path /path/to/kubeconfig`      |
| `--actions`                    | Actions that are performed by this CLI                                                            | "all"                                     | `--actions create`                           |
| `--aws-credential-file`        | Path To The AWS Credential File (default $HOME/.aws/credentials)                                  | ""                                        | `--aws-credential-file /path/to/credentials` |
| `--aws-profile`                | Provide the AWS profile (Default 'default')                                                       | "default"                                 | `--aws-profile custom-profile`               |
| `--config`                     | Config file containing parameters                                                                 | ""                                        | `--config register.json`                       |


## Description

This CLI utility is used to register a new chaos infrastructure in a Harness SaaS environment. It uses the provided API key and account ID to authenticate with the Harness API and create a new chaos infrastructure with the given name and namespace. This command-line interface (CLI) streamlines your infrastructure setup process. With just a single command, the CLI will automate the creation of your chaos infrastructure and verify its activation status. The table above lists a variety of flags. Some of these are mandatory, while others are optional. These flags allow you to customize the process of infrastructure creation according to your needs. By selecting the appropriate flags when running the CLI, you can tailor the chaos infrastructure to your specific requirements

The utility makes a POST request to the `https://app.harness.io/gateway/api/graphql?accountId=<account_id>` endpoint with a JSON payload containing the name and namespace for the new infrastructure. The `x-api-key` HTTP header is used for authentication.

## Setting AWS Permissions for Chaos Experiments

To execute AWS chaos experiments using the Harness chaos infrastructure, the experiment service account needs appropriate AWS permissions. These permissions are necessary to perform fault injections as part of the chaos experiments. You can either create a dedicated AWS Role for this purpose or reuse an existing role.

If you opt to create a dedicated AWS Role, the CLI provides an option to define your own role with attached policies. Based on your selections for different services in scope of the chaos experiment, the CLI prepares a policy with the minimum required permissions to carry out experiments for the target service. This selection is made via the `--resources` flag.

Below are the supported values for the `--resources` flag:

| Value              | Description                                                                                                               |
|--------------------|---------------------------------------------------------------------------------------------------------------------------|
| `az`               | Contains minimum permissions for AZ chaos on CLB, ALB, and NLB.                                                           |
| `ec2-state`        | Contains permissions for EC2 state change experiments like `ec2-stop-by-id`.                                             |
| `ec2`              | Contains permissions for in-VM EC2 chaos like `ec2-cpu-hog`.                                                              |
| `ebs`              | Contains permissions for EBS chaos like `ebs-loss-by-id`.                                                                 |
| `ecs-state`        | Contains permissions for out-of-band ECS experiments like `ecs-instance-stop`.                                           |
| `ecs-ec2`          | Contains permissions for ECS chaos on EC2 instances like `ecs-container-cpu-hog`.                                         |
| `ecs-fargate`      | Contains permissions for Fargate runtime chaos experiments.                                                               |
| `lambda`           | Contains permissions for Lambda chaos experiments excluding Lambda permissions chaos.                                     |
| `lambda-permission`| Contains permissions for Lambda permission chaos experiments.                                                             |
| `rds`              | Contains permissions for RDS chaos experiments.                                                                           |
| `aws-access-restrict` | Contains permissions for security group access restriction.                                                     |
| `windows`          | Contains permissions for chaos on Windows EC2 instances.                                                                  |
| `all` (default)    | Contains permissions for all AWS experiments, it has a superset of permissions.                                           |


These represent permission groups. Using the CLI, you can easily group the permissions based on your use case. For instance, if you run `--resources=ec2,lambda` the CLI will prepare a policy that has permissions to run all EC2 and Lambda chaos experiments.

## Different Modes

You have the option to run the CLI in different modes using the `--actions` flag. This flag allows you to specify the actions performed by the CLI. Here are the different parameters supported by the `--actions` flag:

| Parameter             | Description |
|-----------------------|-------------|
| `all` (default)       | The CLI performs all actions, from creating infrastructure and adding providers to updating Role and annotating the Kubernetes service account.|
| `only_install`        | The CLI only installs the chaos infrastructure and skips all further steps. This limits the permissions required and indicates the user only wants to install the chaos infrastructure using this CLI, skipping other onboarding processes.|
| `install_with_provider` | The CLI installs the chaos infrastructure and sets up AWS onboarding requirements such as creating/using roles with the OIDC provider.|
| `only_provider`      | The CLI skips the chaos infrastructure installation and only performs the AWS configuration part.|
| `only_annotate`      | The CLI only annotates the experiment service account with roleARN and skips all other steps.|


To use these modes, include the`--actions` flag in your command with your chosen parameter.

## Config File Usage


As an alternative to the numerous flag inputs, this CLI tool also offers an option to utilize a configuration file using the `--config` flag. This flag expects a path to a JSON configuration file containing all parameters required for the registration process.


```bash
$ ./onboard_hce_aws register --config register.json
```

In your configuration file, you can include all the relevant parameters as key-value pairs. Here's an example of what your configuration file could look like:

```json
[{
    "apiKey": "",
    "accountId": "",
    "project": "",
    "organisation": "default",
    "infra": {
        "name": "",
        "namespace": "hce",
        "infraScope": "namespace",
        "infraNsExists": true,
        "infraDescription": "Infra for Harness Chaos Testing",
        "serviceAccount": "hce",
        "infraSaExists": false,
        "platformName": "",
        "skipSsl": false
    },
    "environment": {
        "environmentDescription": "Environment for Harness Chaos Testing",
        "environmentType": "PreProduction",
        "environmentName": ""
    },
    "providerUrl": "",
    "roleName": "",
    "resources": "all",
    "region": "",
    "experimentServiceAccountName": "litmus-admin",
    "kubeConfigPath": "",
    "actions": "all",
    "awsCredentialFile": "",
    "awsProfile": "default",
    "timeout": 180,
    "delay": 2
}]

```

- Using a configuration file has numerous benefits. Primarily, it provides a cleaner command line experience by significantly reducing the length of the command you need to execute, thus eliminating the necessity to remember lengthy flag inputs. This enables you to set your configuration parameters in a standalone, reusable, and version-controllable format, thereby improving code manageability.

- Additionally, it's more conducive to automation scenarios such as in CI/CD pipelines. In such environments, you may want to source your configuration from a file that's dynamically populated based on the pipeline's environment variables or other context.

- A further advantage of the config file approach is its ability to facilitate the onboarding of multiple infrastructures simultaneously. By providing each infrastructure's onboarding details as an item in the JSON array, you can automate the process of setting up several environments concurrently.

- Finally, the use of a configuration file can serve as self-documented code, explicitly demonstrating the expected inputs for your command. This feature significantly enhances readability and understandability for other developers or operators who interact with your code, fostering a more collaborative and efficient work environment.

## Examples

- **Command for executing the full onboarding process**

Utilize this command to carry out the comprehensive onboarding process. This process includes the creation of a chaos infrastructure, adding an OIDC provider in the target account, establishing an AWS policy along with a role, and finally annotating the experiment service account with the Role ARN.

```bash
onboard_hce_aws --account-id <your-account-id> --api-key <your-api-key> --infra-name <your-infra-name> --infra-namespace <your-infra-namespace> --project <your-harness-project-id> --provider-url <your-provider-url-from-source-acoount> --region <you-aws-region> --resources <comma-separated-resources>

```

- **Command for executing the full onboarding process with a predefined AWS Role**

This command is also utilized to carry out the comprehensive onboarding process. However, in this case, the command-line interface (CLI) won't establish the policy and RoleARN, presuming that the user already possesses the AWS role for chaos. Instead, it will simply add the identity provider to the role. In this scenario, we define one additional flag: `--role-name`.

```bash
onboard_hce_aws --account-id <your-account-id> --api-key <your-api-key> --infra-name <your-infra-name> --infra-namespace <your-infra-namespace> --project <your-harness-project-id> --provider-url <your-provider-url-from-source-acoount> --region <you-aws-region> --resources <comma-separated-resources> --role-name <you-aws-chaos-role-name>

```

- **Command to solely install the chaos infrastructure**

Use this command when you want to focus exclusively on the installation of the chaos infrastructure, ensuring proper validation for infra activation.

```bash
onboard_hce_aws --account-id <your-account-id> --api-key <your-api-key> --infra-name <your-infra-name> --infra-namespace <your-infra-namespace> --project <your-harness-project-id> --actions only_install

```

- **Command to just perform the AWS operations**

This command will be used to perform only the AWS operations that is adding the provider, creating or updating the role based on the provided `--role-name`.

```bash
onboard_hce_aws --account-id <your-account-id> --api-key <your-api-key> --infra-name <your-infra-name> --infra-namespace <your-infra-namespace> --project <your-harness-project-id> --actions only_install

```

- **Command to solely execute the annotation**

Use this command when you only want to execute the annotation of the experiment service account with the target AWS role, to authenticate the service account with HCE (Harness Chaos Engine).

```bash
onboard_hce_aws --account-id <your-account-id> --api-key <your-api-key> --infra-name <your-infra-name> --infra-namespace <your-infra-namespace> --project <your-harness-project-id> --actions only_install

```

- **Command for executing both the infra installation and AWS operation**

This command allows for the execution of both the chaos infrastructure installation and the AWS operations. The latter involves adding the provider and creating or updating roles.

```bash
onboard_hce_aws --account-id <your-account-id> --api-key <your-api-key> --infra-name <your-infra-name> --infra-namespace <your-infra-namespace> --project <your-harness-project-id> --provider-url <your-provider-url-from-source-acoount> --region <you-aws-region> --resources <comma-separated-resources> --role-name <you-aws-chaos-role-name>

```


- **Command to utilize a configuration JSON file for running the CLI**

This command obtains all input from a JSON file and executes the comprehensive onboarding process.

```bash
onboard_hce_aws register --config register.json

```
Please refer to the aforementioned section for the structure and details of `register.json`.
