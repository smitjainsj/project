node default {

        class { 'java': distribution => 'jdk' } -> class { 'nginx' : }

class { 'tomcat':
  version     => 7,
  sources     => true,
  sources_src => 'http://archive.apache.org/dist/tomcat/',
  require => Service['nginx'],
}

tomcat::instance {'companynews':
  ensure      => present,
  server_port => '8005',
  http_port   => '8080',
  ajp_port    => '8009',
  before => Exec['deploy'],
}

exec{'deploy':
	command => "/bin/cp /tmp/companyNews.war /opt/apache-tomcat/webapps \
			bash /opt/apache-tomcat/bin/startup.sh " ,
	}

}


