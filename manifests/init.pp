# Most of this stuff is already done in kickstart, just making sure it's still there
class glider_common{
	package {["ntp", "puppet", "openssh-server", "bridge-utils"]:
		ensure => installed
	}
	service {["puppet", "sshd", "network"]:
		ensure => running,
		enable => true,
		hasstatus => true,
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
		source => "http://download.fedora.redhat.com/pub/epel/5/i386/epel-release-5-4.noarch.rpm",
		ensure => installed;
	}
    
    file{"/etc/puppet/puppet.conf":
        content => template("glider-common/puppet.conf.erb"),
        notify  => Service["puppet"]
    }
    	
}

define etc_hosts(){
    file{"/etc/hosts":
	content => template("glider-common/hosts.erb")
    }
}

}


define ntp_conf(){
    file{"/etc/ntp.conf":
        content => template("glider-common/ntp.conf.erb")
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

define iscsi_client($host, $username, $password){
	package{"iscsi-initiator-utils":
		ensure => installed
	}
	file{"/etc/iscsid.conf":
		content => template("glider-common/iscsid.conf.erb"),
		notify =>  Service["iscsi"],
	}
	service{"iscsi":
		ensure => running,
		enable => true,
		require => [Package["iscsi-initiator-utils"], File["/etc/iscsid.conf"]],
	}
	
}

define ifcfg($ip="", $netmask="", $gateway="",
		$iftype="", $bridge="", $vlan="", $onboot="yes", $master="", bootproto="")
	{
	$device = $name

	if $master { 
		$slave="yes" 
	}
	if !$bootproto {
		if $ip { $bproto="static" }
		else { $bproto="none" }
	}
	if $bootproto == "dhcp" { $bproto="dhcp"}

	if $iftype == "bridge"{
		$delay="0"
}
	
	file{"/etc/sysconfig/network-scripts/ifcfg-$device":
		content => template("glider-common/ifcfg.erb"),
		notify =>  Service["network"],
	}
}
