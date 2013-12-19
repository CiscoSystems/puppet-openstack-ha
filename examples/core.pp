# This document serves as an example of how to deploy
# a high-availability openstack environment.
# In this scenario nova-network and nova-volumes is
# being used instead of Neutron and Cinder.

node base {

  $build_node_fqdn = "${::build_node_name}.${::domain_name}"

  # Disable pipelining to avoid unfortunate interactions between apt and
  # upstream network gear that does not properly handle http pipelining
  # See https://bugs.launchpad.net/ubuntu/+source/apt/+bug/996151 for details
  file { '/etc/apt/apt.conf.d/00no_pipelining':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => 'Acquire::http::Pipeline-Depth "0";'
  }

  # Load apt prerequisites.  This is only valid on Ubuntu systmes
  apt::source { "cisco-openstack-mirror_folsom":
    location => $::location, 
    release => "folsom",
    repos => "main",
    key => "E8CC67053ED3B199",
    key_content => '-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.11 (GNU/Linux)

mQENBE/oXVkBCACcjAcV7lRGskECEHovgZ6a2robpBroQBW+tJds7B+qn/DslOAN
1hm0UuGQsi8pNzHDE29FMO3yOhmkenDd1V/T6tHNXqhHvf55nL6anlzwMmq3syIS
uqVjeMMXbZ4d+Rh0K/rI4TyRbUiI2DDLP+6wYeh1pTPwrleHm5FXBMDbU/OZ5vKZ
67j99GaARYxHp8W/be8KRSoV9wU1WXr4+GA6K7ENe2A8PT+jH79Sr4kF4uKC3VxD
BF5Z0yaLqr+1V2pHU3AfmybOCmoPYviOqpwj3FQ2PhtObLs+hq7zCviDTX2IxHBb
Q3mGsD8wS9uyZcHN77maAzZlL5G794DEr1NLABEBAAG0NU9wZW5TdGFja0BDaXNj
byBBUFQgcmVwbyA8b3BlbnN0YWNrLWJ1aWxkZEBjaXNjby5jb20+iQE4BBMBAgAi
BQJP6F1ZAhsDBgsJCAcDAgYVCAIJCgsEFgIDAQIeAQIXgAAKCRDozGcFPtOxmXcK
B/9WvQrBwxmIMV2M+VMBhQqtipvJeDX2Uv34Ytpsg2jldl0TS8XheGlUNZ5djxDy
u3X0hKwRLeOppV09GVO3wGizNCV1EJjqQbCMkq6VSJjD1B/6Tg+3M/XmNaKHK3Op
zSi+35OQ6xXc38DUOrigaCZUU40nGQeYUMRYzI+d3pPlNd0+nLndrE4rNNFB91dM
BTeoyQMWd6tpTwz5MAi+I11tCIQAPCSG1qR52R3bog/0PlJzilxjkdShl1Cj0RmX
7bHIMD66uC1FKCpbRaiPR8XmTPLv29ZTk1ABBzoynZyFDfliRwQi6TS20TuEj+ZH
xq/T6MM6+rpdBVz62ek6/KBcuQENBE/oXVkBCACgzyyGvvHLx7g/Rpys1WdevYMH
THBS24RMaDHqg7H7xe0fFzmiblWjV8V4Yy+heLLV5nTYBQLS43MFvFbnFvB3ygDI
IdVjLVDXcPfcp+Np2PE8cJuDEE4seGU26UoJ2pPK/IHbnmGWYwXJBbik9YepD61c
NJ5XMzMYI5z9/YNupeJoy8/8uxdxI/B66PL9QN8wKBk5js2OX8TtEjmEZSrZrIuM
rVVXRU/1m732lhIyVVws4StRkpG+D15Dp98yDGjbCRREzZPeKHpvO/Uhn23hVyHe
PIc+bu1mXMQ+N/3UjXtfUg27hmmgBDAjxUeSb1moFpeqLys2AAY+yXiHDv57ABEB
AAGJAR8EGAECAAkFAk/oXVkCGwwACgkQ6MxnBT7TsZng+AgAnFogD90f3ByTVlNp
Sb+HHd/cPqZ83RB9XUxRRnkIQmOozUjw8nq8I8eTT4t0Sa8G9q1fl14tXIJ9szzz
BUIYyda/RYZszL9rHhucSfFIkpnp7ddfE9NDlnZUvavnnyRsWpIZa6hJq8hQEp92
IQBF6R7wOws0A0oUmME25Rzam9qVbywOh9ZQvzYPpFaEmmjpCRDxJLB1DYu8lnC4
h1jP1GXFUIQDbcznrR2MQDy5fNt678HcIqMwVp2CJz/2jrZlbSKfMckdpbiWNns/
xKyLYs5m34d4a0it6wsMem3YCefSYBjyLGSd/kCI/CgOdGN1ZY1HSdLmmjiDkQPQ
UcXHbA==
=v6jg
-----END PGP PUBLIC KEY BLOCK-----',
    proxy => $::proxy,
  }

  # Pin the Cisco repo so new Ubuntu packages do not take precendence.
  apt::pin { "cisco":
    priority   => '990',
    originator => 'Cisco'
  }

  # NTP must be configured correctly for OpenStack to work properly.
  # [$::ntp_server] is defined in the site manifest.
  # (Must be a reachable NTP Server by your build-node, i.e. ntp.esl.cisco.com)
  class { ntp:
    servers    => [$::ntp_server],
    ensure     => running,
    autoupdate => true,
  }

  # /etc/hosts entries for nova controller and swift proxy nodes
  host { $::controller_vip_hostname:
    ip => $::controller_cluster_vip
  }

  host { $::controller01_hostname:
    ip => $::controller01_mgt_ip
  }

  host { $::controller02_hostname:
    ip => $::controller02_mgt_ip
  }

  host { $::controller03_hostname:
    ip => $::controller03_mgt_ip
  }

  host { $::swiftproxy01_hostname:
    ip => $::swiftproxy01_ip
  }

  host { $::swiftproxy02_hostname:
    ip => $::swiftproxy02_ip
  }

  host { $::swiftproxy_vip_hostname:
    ip => $::swiftproxy_cluster_vip
  }

}

node os_base inherits base {

  # Deploy a script that can be used to test nova
  class { 'openstack::test_file': }

  # Deploy a file to OpenStack nodes used for credentials
  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_cluster_vip,
  }
}

class controller (
  $public_address,
  $internal_address,
  $admin_address,
  $galera_master_ip,
  # address used to bind OpenStack services to (instead of all interfaces)
  $api_bind_address   = $public_address,
  # address used to bind MySQL to (instead of all interfaces)
  $mysql_bind_address = $internal_address,
  # List of RabbitMQ Brokers for nova-scheduler to use for RPC messages.
  $rabbit_hosts       = [$controller01_hostname, $controller02_hostname, $controller03_hostname],
  # IP address to use for memcached (instead of loopback IP).
  $cache_server_ip    = $internal_address,
) {

  class { 'openstack-ha::controller':
    # Addressing and interface information
    public_address          => $public_address,
    internal_address        => $internal_address,
    admin_address           => $admin_address,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    # Nova Information
    api_bind_address        => $api_bind_address,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    memcached_servers       => $memcached_servers,
    # Nova Networking Information
    multi_host              => true,
    floating_range          => $floating_ip_range,
    fixed_range             => $fixed_network_range,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    # MySQL, Galera and Database Information
    db_host                 => $controller_cluster_vip,
    mysql_bind_address      => $mysql_bind_address,
    mysql_root_password     => $mysql_root_password,
    mysql_account_security  => false,
    galera_master_ip        => $galera_master_ip,
    galera_monitor_password => $galera_monitor_password,
    wsrep_sst_password      => $wsrep_sst_password,
    # Keystone Information
    keystone_host           => $keystone_host,
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $keystone_admin_token,
    # Glance Information
    glance_api_servers      => "${controller_cluster_vip}:9292",
    glance_registry_host    => $controller_cluster_vip,
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    swift_store_user        => "${swift_auth_tenant}:${swift_auth_user}",
    swift_store_key         => $swift_auth_password,
    # RabbitMQ Information
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    cluster_rabbit          => $cluster_rabbit,
    rabbit_hosts            => $rabbit_hosts,
    cluster_disk_nodes      => $cluster_disk_nodes,
    # Horizon Information
    secret_key              => $horizon_secret_key,
    cache_server_ip         => $cache_server_ip,
    # General Information
    verbose                 => $verbose,
    admin_email             => $admin_email,
    admin_password          => $admin_password,
  }

}

class compute (
) {

  class { 'openstack-ha::compute':
    # Networking
    public_interface      => $public_interface,
    private_interface     => $private_interface,
    internal_address      => $ipaddress_eth0,
    bridge_interface      => $ovs_bridge_interface,
    neutron_bind_address  => $ipaddress_eth0,
    # Database
    db_host               => $controller_cluster_vip,
    # Nova
    nova_user_password    => $nova_user_password,
    nova_db_password      => $nova_db_password,
    api_bind_address      => $ipaddress_eth0,
    metadata_address      => $controller_cluster_vip,
    fixed_range           => $fixed_network_range,
    multi_host            => true,
    # Rabbit
    cluster_rabbit        => $cluster_rabbit,
    rabbit_hosts          => ['control01', 'control02', 'control03'],
    rabbit_user           => $rabbit_user,
    rabbit_password       => $rabbit_password,
    # Keystone
    keystone_host         => $keystone_host,
    # Neutron
    neutron_user_password => $neutron_user_password,
    neutron_db_password   => $neutron_db_password,
    # Glance
    glance_api_servers    => "${controller_cluster_vip}:9292",
    # VNC
    vncproxy_host         => $controller_cluster_vip,
    # General
    verbose               => $verbose,
  }

  network_config { "$::private_interface":
    ensure => 'present',
    hotplug => false,
    family => 'inet',
    method => 'manual',
    onboot => 'true',
    notify     => Exec['network-restart']
  }

  # Changed from service to exec due to Ubuntu bug #440179
  exec { 'network-restart':
    command     => '/etc/init.d/networking restart',
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    refreshonly => true
  }

}

########### Definition of the Build Node #######################
#
# Definition of this node should match the name assigned to the build node in your deployment.
# In this example we are using build-node, you dont need to use the FQDN. 
#
################################################################

node build-node inherits "cobbler-node" {
  
  $build_node_fqdn = "${::build_node_name}.${::domain_name}"

  host { $build_node_fqdn: 
    ip => $::cobbler_node_ip
  }

  host { $::build_node_name: 
    ip => $::cobbler_node_ip
  } 

  # Set up a local apt cache.  Eventually this may become a local mirror/repo instead
  # Some proxies have issues with range headers. 
  # Therefore avoid_if_range has been set to true.
  class { apt-cacher-ng: 
    proxy 	    => $::proxy,
    avoid_if_range  => true,
  }

  class { puppet:
    run_master 		 => true,
    puppetmaster_address => $build_node_fqdn, 
    certname 		 => $build_node_fqdn,
    mysql_password 	 => $mysql_puppet_password,
  }<-  
    
  file {'/etc/puppet/files':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file {'/etc/puppet/fileserver.conf':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => '

# This file consists of arbitrarily named sections/modules
# defining where files are served from and to whom

# Define a section "files"
# Adapt the allow/deny settings to your needs. Order
# for allow/deny does not matter, allow always takes precedence
# over deny
[files]
  path /etc/puppet/files
  allow *
#  allow *.example.com
#  deny *.evil.example.com
#  allow 192.168.0.0/24

[plugins]
#  allow *.example.com
#  deny *.evil.example.com
#  allow 192.168.0.0/24
',
    }
}

