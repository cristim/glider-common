class glider:common:ssh{
        package {"openssh-server":
                ensure => installed
        }
        service {"sshd":
                ensure => running,
                enable => true
        }
	file {"/etc/ssh/sshd_config":
		source => "puppet://puppet/modules/glider-common/sshd_config.$hostname",
			 "puppet://puppet/modules/glider-common/sshd_config.wn",
		notify  => Service[dhcpd]
	}


