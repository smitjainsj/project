node default {

        class { 'nginx' : }
        class { 'java': distribution => 'jdk' }

class { 'tomcat':
  version     => 7,
  sources     => true,
  sources_src => 'http://archive.apache.org/dist/tomcat/',
}

tomcat::instance {'companynews':
  ensure      => present,
  server_port => '8005',
  http_port   => '8080',
  ajp_port    => '8009',
}


}


