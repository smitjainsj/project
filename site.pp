node default {

	class { 'nginx' : }
	class { 'java': distribution => 'jdk' }

}



