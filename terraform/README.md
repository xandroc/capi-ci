## Using Terraform on Azure

See [this blog post](http://toddysm.com/2016/12/08/how-to-configure-terraform-to-work-with-azure-resource-manager/) for configuring Terraform + Azure. Summary below.

#### Creating a Client ID + Secret

1. Go to portal.azure.com > Azure Active Directory > App Registrations > Add
1. Enter a unique name, Type: Web App / API, enter any random URI for Sign-On URL (e.g. https://example.com)
1. After creating the registration, add a new Key by going to its detail page > Settings > Keys.
1. Save the Application ID as Terraform's `client_id` field and the Key value as Terraform's `client_secret`.
1. Go to the Application's Settings > Required Permissions > Add
1. Select Windows Azure Service Management API, then Access Azure Service Management as organization users (preview), Done

#### Granting your Client permissions to create necessary Terraform resources

1. Go to Subscriptions > Access Control > Add
1. Select Role matching your needs (Contributor is the most general), then search for your Client name, OK

#### Finding your Subscription ID

1. Click Azure sidebar > More Services > Search for Subscriptions

#### Finding your Tenant ID

1. Azure Active Directory > Properties > Directory ID
