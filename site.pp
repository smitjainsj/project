node default {

	class { 'nginx' : }
	class { 'java': distribution => 'jdk' }

class { 'tomcat':
  version     => 8,
  sources     => true,
  sources_src => 'http://archive.apache.org/dist/tomcat/',
	}
	tomcat::instance {'tomcat1':
	  ensure      => present,
	  http_port   => '8080',
	}

	service  {'tomcat-tomcat1':
		ensure => 'stopped'
	}

#	exec {'tocmat':
#		command => '/bin/cp /opt/companyNews.war /opt/apache-tomcat/webapps \
#			bash /opt/apache-tomcat/bin/startup.sh ' ,
#		require => Class['tomcat'], 
#		}
	}	




