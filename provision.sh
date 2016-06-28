#!/usr/bin/env bash

apt-get update > /dev/null 2>&1

echo "Installing Git ..."
apt-get -q -y install git unzip

echo "Checking Puppet Package ..."
if [ $(dpkg-query -W -f='${Status}' puppet 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  echo -e "Installing Puppet ..."
  apt-get install puppet;
else
 echo -e "Puppet is already installed ..."
 puppet -V
fi

echo "Downloading Puppet Modules ... "
puppet module install jfryman-nginx > /dev/null 2>&1
puppet module install puppetlabs-java > /dev/null 2>&1 
puppet module install camptocamp-tomcat > /dev/null 2>&1

cd /etc/puppet
echo "Cloning Git Repo ... "
git clone  -b dev https://github.com/smitjainsj/project

cp project/*.yaml /etc/puppet
cp project/site.pp /etc/puppet/manifests

echo "Downloading Artifacts ...."

wget https://s3.amazonaws.com/infra-assessment/companyNews.war -P /tmp > /dev/null 2>&1
wget https://s3.amazonaws.com/infra-assessment/static.zip -P /tmp > /dev/null 2>&1

unzip /tmp/static.zip
mkdir -p /var/www/html/companyNews
cp -r /tmp/static/* /var/www/html/companyNews

puppet apply /etc/puppet/manifests/site.pp --debug 

cp /opt/companyNews.war /opt/apache-tomcat/webapps

bash /opt/apache-tomcat/bin/startup.sh


