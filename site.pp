node default {

class { 'java': distribution => 'jdk' } -> class { 'nginx' : }


class { 'tomcat':
  version     => 7,
  sources     => true,
  sources_src => 'http://archive.apache.org/dist/tomcat/',
}


file{'/opt/apache-tomcat/webapps/companyNews.war':
 ensure => 'present' ,
 mode => '0755',
 owner => 'root',
 group => 'root',
 source =>  'puppet:///modules/tomcat/companyNews.war' ,
 }

	exec{'deploy':
		path   => '/usr/bin:/usr/sbin:/bin:/sbin',
		command => '/bin/bash /opt/apache-tomcat*/bin/startup.sh', 
		onlyif  =>  "/bin ls /opt/apache-tomcat/webapps/companyNews.war" ,
		}


}
