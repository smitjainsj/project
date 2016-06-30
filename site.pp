node default {

class { 'java': distribution => 'jdk' } ->
class { 'nginx' : } ->
class {'tomcat':
  version     => 7,
  sources     => true,
  sources_src => 'http://archive.apache.org/dist/tomcat/',
}
tomcat::instance {'companynews':
  ensure      => 'present',
  server_port => '8005',
  http_port   => '8080',
  ajp_port    => '8009',
}

file{'/srv/tomcat/companynews/webapps/companyNews.war':
 ensure => present,
 mode => '0755',
 owner => 'tomcat',
 group => 'adm',
 source =>  'puppet:///modules/tomcat/companyNews.war' ,
 }
	exec{'deploy':
		path   => '/usr/bin:/usr/sbin:/bin:/sbin',
		command => '/bin/bash /srv/tomcat/companynews/bin/startup.sh', 
		onlyif  =>  "/bin/ls /srv/tomcat/comanpynews/webapps/companyNews.war" ,
		require => File['/srv/tomcat/companynews/webapps/companyNews.war'],	
            }
}
