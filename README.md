<h1 align="center"><img alt="Hotel Booking" title="Hotel Booking" src=".github/logo.png" width="250" /></h1>

# Hotel Booking

## 💡 Project's Idea

This project was developed to create an online hotel booking API platform, using an event driven microservices architecture.

## 🔍 Features

* Login and signup to the application;

## 🛠 Technologies

During the development of this project, the following techologies were used:

- [Python](https://www.python.org/)
- [Amazon Cognito](https://aws.amazon.com/pt/cognito/)
- [Terraform](https://www.terraform.io/)
- [GitHub Actions (CI/CD)](https://github.com/features/actions)

## 💻 Project Configuration

After creating the required AWS infrastructure resources, you must update the following lines at [cognito.js](./web-app/scripts/cognito.js) with the Cognito's created service data, as well as the redirect callback and sign out URLs to your application's URL:

```javascript
const config={
    cognito:{
        identityPoolId:"user_pool_id",
        cognitoDomain:"cognito_domain",
        appId:"app_client_id"
    }
}
//...
var cognitoApp={
    //...
    {
        var authData = {
            //...
            RedirectUriSignIn : 'https://your-app.domain.com/',
            RedirectUriSignOut : 'https://your-app.domain.com/',
        };
        //...
    }
}
```

You must also update the form action for [addHotel.html](./web-app/addHotel.html) with the API Gateway invoke url:

```javascript
action="invoke_url"
```

## 🏗️ Infrastructure as Code (IaC) with Terraform

To make it easier to provision infrastructure on cloud providers, you can make use of the [Terraform template](main.tf) provided.

First, you'll need to [install Terraform](https://developer.hashicorp.com/terraform/downloads) on your machine; then, since we're using AWS for the specified resources, you'll need to install the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) as well.

After that, you must set up an IAM user with permissions to manage resources, create an access key for the new user and configure the AWS CLI with the following command (entering the access key ID, secret access key, default region and outout format):

```bash
$ aws configure
```

Once these steps are done, you can use the Terraform commands to create, update and delete resources.

```bash
$ terraform init # Downloads the necessary provider plugins and set up the working directory
$ terraform plan # Creates the execution plan for the resources
$ terraform apply # Executes the actions proposed in a Terraform plan
$ terraform destroy # Destroys all remote objects managed by a particular Terraform configuration
```

If you want to provide the required variables for Terraform automatically when executing the script, you can create a file called *prod.auto.tfvars* file on the root directory, with all needed variables, according to the sample provided ([auto.tfvars](auto.tfvars)).

### Documentation:
* [aussiearef / MicroservicesWithAWS_FrontEnd](https://github.com/aussiearef/MicroservicesWithAWS_FrontEnd)
* [Terraform | Resource: aws_cognito_user_pool](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool#attributes_require_verification_before_update)

## 📄 License

This project is under the **MIT** license. For more information, access [LICENSE](./LICENSE).
