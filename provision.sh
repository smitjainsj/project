#!/usr/bin/env bash

apt-get update > /dev/null 2>&1

echo "Installing Git ..."
apt-get -q -y install git unzip

echo "Checking Puppet Package ..."
if [ $(dpkg-query -W -f='${Status}' puppet 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  echo -e "Installing Puppet ..."
  apt-get -y install puppet;
else
 echo -e "Puppet is already installed ..."
 puppet -V
fi

echo "Downloading Puppet Modules ... "
puppet module install jfryman-nginx > /dev/null 2>&1
puppet module install puppetlabs-java > /dev/null 2>&1 
puppet module install camptocamp-tomcat > /dev/null 2>&1

if [ -d "/etc/puppet/project" ]
then
	echo "GIT REPO ALREADY PRESENT."
else
	echo "Cloning Git Repo ... "
	cd /etc/puppet
        git clone  -b dev https://github.com/smitjainsj/project 

fi

if [ -f "/etc/puppet/hiera.yaml" ]
then
	echo "Hiera File Present"
else
	/bin/cp /etc/puppet/project/*.yaml /etc/puppet
	/bin/cp /etc/puppet/project/site.pp /etc/puppet/manifests
fi


if [ -f "/tmp/companyNews.war" ]
then
	echo "WAR File already downloaded"
else 
	echo "Downloading Artifacts ...."
	wget https://s3.amazonaws.com/infra-assessment/companyNews.war -P /tmp > /dev/null 2>&1
	wget https://s3.amazonaws.com/infra-assessment/static.zip -P /tmp > /dev/null 2>&1
	/usr/bin/unzip /tmp/static.zip
	mkdir -p /var/www/html/companyNews
	/bin/cp -r /tmp/static/* /var/www/html/companyNews
fi

if [ -f "/etc/puppet/manifests/site.pp" ]
then
	puppet apply /etc/puppet/manifests/site.pp --debug 
else
	echo "Site.pp File missing .... "
fi

if [ -d "/etc/apache-tocmat-* " ]
then
	echo "Deploying Webapp"
	/bin/cp /tmp/companyNews.war /opt/apache-tomcat/webapps
	bash /opt/apache-tomcat/bin/startup.sh
else
	echo "CANNOT DEPLOY WEBAPP, APACHE NOT FOUND!!! "
fi
