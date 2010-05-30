# Most of this stuff is already done in kickstart, just making sure it's still there
class glider_common{
	package {["ntp", "puppet", "openssh-server"]:
		ensure => installed
	}
	service {["puppet", "sshd"]:
		ensure => running,
		enable => true
	}
	
	# NTP is useless in OpenVZ
	if $isvirtual {	
		service {["ntpd"]:
			ensure => stopped,
			enable => false,
		}
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
    
    augeas{ "fix_etc_hosts" :
        context => "/files/etc/hosts/1",
        changes => ["set canonical $fqdn",
                    "set alias[1] $hostname",
                    "set alias[2] localhost"],
        onlyif  => "get canonical != $fqdn"
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

define nfs_server($shares,
		$hosts 	= "*",
		$options= "rw,no_root_squash"){
	package { ["nfs-utils","portmap"]:
        	ensure => present,
	}	
	file{"/etc/exports":
		content => template("glider-common/exports.erb"),
		notify  => Service["portmap", "nfs"],
		require => Package["nfs-utils","portmap"],
	}
	service {["portmap", "nfs"]:
		ensure => running,
		require => File["/etc/exports"],
	}
}
