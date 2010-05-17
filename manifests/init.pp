#XXX: Most of this stuff is already done in kickstart, maybe we should skip it here
class glider_common{
	package {["ntp", "puppet", "openssh-server"]:
		ensure => installed
	}
	service {["ntpd", "puppet", "sshd"]:
		ensure => running,
		enable => true
	}
	package { "epel-release":
		provider => "rpm",
		source => "http://download.fedora.redhat.com/pub/epel/5/i386/epel-release-5-3.noarch.rpm",
		ensure => installed;
	}
    
    file{"/etc/puppet/puppet.conf":
        content => template("glider-common/puppet.conf.erb"),
        notify  => Service["puppet"]
    }
    
    augeas{ "make_hosts_entry" :
        context => "/files/etc/hosts/1",
        changes => ["set alias[last()+1] $fqdn",
                    "set alias[last()+1] $hostname"],
        onlyif  => "get alias[last()] == localhost"
    }
}
define download_file(
		$site="",
		$local_path="", 
		$user="") {

	exec { "mkdir_for_$name":
		command => "mkdir -p $local_path",
		path => "/bin",
		creates => "$local_path",
		user => $user,
		notify => Exec[$name]
	}
	exec { $name:
		path => "/usr/bin",
		command => "rsync -a ${site}/${name} .",
		cwd => $local_path,
		refreshonly => true,
		timeout => "-1",
		user => $user
	}

}

