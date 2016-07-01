
## ASSIGNMENT DETAILS
##### Version 1.0.0
-----------------------------------
## Problem Statement
You need to create two environments ​one for training and one for production. You should prepare the production environments for the limited release and plan for the scale out during
fully public release.<br />
- The development team has a continuous integration build that produces two artifacts:​ .zip file ​ with the image and style sheet used for the application a ​.war file​ with the dynamic parts of the application. You should deploy the static assets to a web server and the .war file to a separate application server. Any compatible servers are acceptable.

We will have two environments namely the _**training**_ and _**production**_ environment as per the problem statement.

## TRAINING ENVIRONMENT

#### INTRODUCTION !!!
Firstly, clone the git repository shared below and then proceed further.The repository will contain two directories **terraform** and **vagrant**. Below are the details for each directories and it's respective config files.

The _Vagrantfile_ present inside vagrant folder will create a linux Vagrant [**ubuntu/trusty64**](https://vagrantcloud.com/ubuntu/boxes/trusty64/versions/20160621.0.0/providers/virtualbox.box) installing Ubuntu 14.04, post install it will also configure fewer options with passing along a shell script _provision.sh_ to configure the vagrant according to the problem given.

**Directories** <br />
1. Terraform: It contains three files _main.tf_,_variables.tf_ and _provision.sh_ .<br />
 - main.tf : This contains configuration of AWS Infrastructure primarily VPC Name, Subnets, Instance and other Infrastructure level details.It also contains the AutoScale policy rules and action alarms. For more details on how to write the config files for AWS,kindly go through the terraform [documentation.](https://www.terraform.io/docs/)
 - variable.tf : This contain the variables which are liable to change from user to user.
 - provision.sh : This is the user-data script that will configure the server according the problem given.**Puppet** will be primarily used to setup the machine in an automatic fashion.

 _Note all the commands given below are used with root user for easy of use. If you are not using root user, kindly use **sudo** as applicable._

### IMPLEMENTATION
#### TRAINING ENVIRONMENT
One must have Virtualbox  and Vagrant installed on the local machine with a virtualbox image of **ubuntu/trusty64** added. You can also use the below command to add the box if you dont have.  

````
$vagrant box add https://vagrantcloud.com/ubuntu/boxes/trusty64/versions/20160621.0.0/providers/virtualbox.box1
````

Clone the git repository to your system under to your home directory.<br />
````
$git clone -b production https://github.com/smitjainsj/project.git
$cd project/vagrant
````
Kindly change the **root** value in _Vagrantfile_ to make sure you don't face stdout error.<br />
>
s.inline = "sudo sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' **/root/**.profile"
>
````
$vagrant up --provision
````
Once the vagrant is up, you can access the webapp on the URL _192.168.33.10_ .

#### PRODUCTION ENVIRONMENT
To setup production environment I have chose below tools and technologies for setting up the Infrastructure.<br />
- Amazon Web Services: This will hosting our cloud environment, where all the instances will be running and hosting our _companyNews_ app.
- Terraform: [Terraform](https://www.terraform.io) is automation tool to setup Cloud Infrastructure in a single go. It's easy and reliable to use to build,scale and strength your deployment on any cloud Infrastructure.
- Operating System: Ubuntu 14.04 will be our prime linux distro to cater the web application.
- Apache Tomcat: [Tomcat](http://tomcat.apache.org/) 7.x will used to host our webapp, it's easy to configure and deploy. Also, it very stable and been there in open source world for a quite long time.
- Nginx : [Nginx](https://www.nginx.com/resources/wiki/) will be used to serve as a reverse proxy and web server to serve the static images and CSS files.It's the best lightweight web server to entertain your HTTP/HTTPS requests and serve the static content.
- GitHub: [Github](https://github.com/) hosts our configuration files used by Puppet to configure the server.The most used versioning tool to keep track of all the development done.
- Puppet: For configuration management, I used Puppet 3.4.x standalone setup to setup the server.Using standalone mode is more feasible if you have instances confiured on autoscaling as they will be created and terminated as per load.

#### AWS Blueprint
- Here we are using multi tenant setup to cater fault tolerance. For testing purpose tI have chose the **Singapore Region** althought this can be changed in the _variables.tf_ file as per the needs.
- This will have 2 Public Subnets and 2 Private Subnets with NAT instance running in Public Subnet A Zone to cater the internet needs from the instances.
- The instances will be private and can only be accessed via NAT instance as jump server.
- We will require two pairs to RSA key to insert in the NAT and Application servers.To generate the keys use this [digitalocean link.](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2)
- How to use terraform to setup the AWS Infrastructure is given in later stage in this readme file.
- Initially two application servers will be created in each avaliability zone A & B. As the CPU load crosses the threshold autoscale configuration will create 2 more instances respectively and add them to the Elastic Load Balancer. It will also scale down the instances back to 2 as soon as the cool threshold is reached which is 30% CPU Load here. All these setting can be changed and set accordingly the requirements.

Puppet Modules used are as follows :-
- Tomcat: [camptocamp](https://forge.puppet.com/camptocamp/tomcat)
- Nginx: [jfryman/nginx](https://forge.puppet.com/jfryman/nginx)

We have also used _hiera.yaml_ to setup the NGINX.

#### Using Terraform to setup the Production environment.
Before moving ahead,be ready with two pairs of SSH keys and place them in a standard location.Here we will place them in **_/opt/poc/keys._**
 We have copied 4 keys in the folder which are _nat, nat.pub,instance and instance.pub._
It will also require AWS access keys to create the AWS Infrastructure. <br />

````
cd /opt/poc
$wget https://releases.hashicorp.com/terraform/0.6.16/terraform_0.6.16_linux_amd64.zip -P /opt
$unzip /opt/terraform_0.6.16_linux_amd64.zip -P /opt
$vim ~/.bashrc
PATH=/opt/terraform/:$PATH
$mkdir ~/.aws
$cat >  ~/.aws/credentials

[default]
aws_access_key_id = xxxxxxxxxxxxxxx
aws_secret_access_key = yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy

$git clone -b production https://github.com/smitjainsj/project.git
$cd project/terraform
$terraform plan
var.instance_key_name
  Desired name of AWS key pair

  Enter a value: instance

var.instance_public_key_path
  Path to the SSH public key to be used for authentication.
  Ensure this keypair is added to your local SSH agent so provisioners can
  connect.

  Example: ~/.ssh/terraform.pub

  Enter a value: /opt/poc/keys/instance.pub

var.key_name
  Desired name of AWS key pair

  Enter a value: nat

var.public_key_path
  Path to the SSH public key to be used for authentication.
  Ensure this keypair is added to your local SSH agent so provisioners can
  connect.

  Example: ~/.ssh/terraform.pub

  Enter a value: /opt/poc/key/nat.pub

$terraform destroy ### To destroy the environment created.
````


Now relax and let the magic begin.You can login to the AWS Console after a while and check the instance getting created on the console.
All the user-data logs will logged to the file _/var/log/user-data.log_ file.In order to access the machines, pull the elastic ip of the NAT instance from the console and use as below.<br />
````
ssh -i nat ec2-user@<ipaddress>
````
Also, SCP the file private key of the instance to login further to the application servers.
To access the application just the copy the URL generated from the ELB and paste in your browser.

#### Paths and Locations
- All the NGINX logs will be placed in _/var/log/nginx/companynews*.log_
- Tomcat will be running as a service, to start and stop the service use the syntax  
````
$service tomcat-companynews stop/start/status
````

#### Further Improvements
- As of now only Port 80 is open on ELB but to increase the security we can use SSL on ELB from security perspective.
- The security groups (web and nat) has only ports 80 and 22 to allow tcp traffic.
- This is just a sample setup your automation and can scaled up to use in big production enviornments.
- Errors and issues are welcome and can be reported at this [Github link.](https://github.com/smitjainsj/project/issues)
