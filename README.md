# Aviatrix Transit FireNet QuickStart with All Dependencies Included 

This Repo will build you three(3) Aviatrix Transit FireNets with High Performance Encryption enabled that are fully meshed with all of the dependencies for the Firewalls built in. The bootstrap configuration files and the IAM objects needed to deploy them are built into the code. This is my first pass at writing out these details so I am doing so from the perspective of the advanced practitioner -- I will include a deeper set of instructions that will cater to the audience who is not familiar with Aviatrix at a later point. 

## Why bother: 

Getting your FireNet firewalls to deploy automatically requires some configuration files to be uploaded to S3 and some IAM objects to be created. This code base does that for you. 

### What you will need: 

1. An Aviatrix Controller -- this is simple enough to get having admin access to an AWS account, subscribing to the Marketplace [offering](https://aws.amazon.com/marketplace/pp/prodview-qzvzwigqw72ek?sr=0-3&ref_=beagle&applicationId=AWSMPContessa) (This gets you your metered license key) and launching the [cloudformation template of the BYOL Platform](https://aws.amazon.com/marketplace/pp/prodview-nsys2ingy6m3w?sr=0-2&ref_=beagle&applicationId=AWSMPContessa) ( This launches the actual AMI for your license key to go into ). Yes, you are clicking the subscribe button twice. One is to execute a metered contract on the marketplace and the other is to get access to the AMI itself. Using the AMI to build things is how the meter actually starts running. 


### Default Settings 

| Element  | Default Designation  | 
|-----:|---------------|
|    Cloud |AWS        |
|  Regions    | us-west-2, us-east-1, us-east-2               |
|      Number of Firewalls per Transit| 2              |
| HPE Enabled| Yes |
|Gateway Sizes| C5n.2xlarge | 
|Firewall Size| C5.xlarge|
|Transit Peering| Full Mesh | 
