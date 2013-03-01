#
# Example file for building out a multi-node Swift environment.
# The file should be imported int your site manifest: import 'swift-nodes'
# This manifest has been tested with the folsom_ha branches of Puppet modules.
#
# This example creates nodes of the following roles:
#   swift_storage - nodes that host storage servers
#   swift_proxy - nodes that serve as a swift proxy
#   swift_ringbuilder - nodes that are responsible for
#     rebalancing the rings
#
# This example assumes a few things:
#   * the multi-node scenario requires a puppetmaster
#   * networking is correctly configured
#
# The SWift Nodes need to be brought up in the following order:
#
# 1. storage nodes
# 2. proxy node 1
# 3. run the storage nodes again (to synchronize the ring db)
# 4. proxy node 2
# 5. test that everything works!!

# Swift Authentication Parameters
$swift_auth_tenant   = 'services'
$swift_auth_user     = 'swift'
$swift_auth_password = 'swift_pass'
$swift_shared_secret = 'Gdr8ny7YyWqy2'

# External-facing Swift Proxy Network definitions.  
# Create additional node definitions as required.
$swiftproxy01_public_net_ip   = '192.168.220.61'
$swiftproxy02_public_net_ip   = '192.168.220.62'

# Internal Storage Network definitions.
# Create additional node definitions as required.
$swiftproxy01_local_net_ip    = '192.168.222.61'
$swiftproxy02_local_net_ip    = '192.168.222.62'
$swift01_local_net_ip         = '192.168.222.71'
$swift02_local_net_ip         = '192.168.222.72'
$swift03_local_net_ip         = '192.168.222.73'
$swift_local_net_mask         = '255.255.255.0'

# Memcached definitions used by Proxy Nodes.  
# Create additional definitions if you have more than 2 Proxy Nodes.
$swift_memcache_servers  = ["${swiftproxy01_local_net_ip}:11211,${swiftproxy02_local_net_ip}:11211"]

# Configurations that need to be applied to all swift nodes
node swift_base inherits base  {

  class { 'ssh::server::install': }

  class { 'swift':
    swift_hash_suffix => "$swift_shared_secret",
    package_ensure    => latest,
  }  
}

# The following specifies the 1st swift storage node
node /swift01/ inherits swift_base {

  network_config { "$::storage_interface":
    ensure     => 'present',
    family     => 'inet',
    ipaddress  => $swift01_local_net_ip,
    method     => 'static',
    netmask    => $swift_local_net_mask,
    onboot     => 'true',
    notify     => Exec['network-restart']
  }

  # Changed from service to exec due to Ubuntu bug #440179
  exec { 'network-restart':
    command     => '/etc/init.d/networking restart',
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    refreshonly => true
  }

  # install all swift storage servers together
  class { 'swift::storage::all':
    storage_local_net_ip => $swift01_local_net_ip,
  }

  # Include class to configure hard disks
  include swift-ucs-disk

  # Specify the zone the storage node should reside in
  $swift_zone = 1
 
  # specify endpoints per device to be added to the ring specification
  @@ring_object_device { "${swift01_local_net_ip}:6000/sdb":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_object_device { "${swift01_local_net_ip}:6000/sdc":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_object_device { "${swift01_local_net_ip}:6000/sdd":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_object_device { "${swift01_local_net_ip}:6000/sde":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_object_device { "${swift01_local_net_ip}:6000/sdf":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_container_device { "${swift01_local_net_ip}:6001/sdb":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_container_device { "${swift01_local_net_ip}:6001/sdc":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_container_device { "${swift01_local_net_ip}:6001/sdd":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_container_device { "${swift01_local_net_ip}:6001/sde":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_container_device { "${swift01_local_net_ip}:6001/sdf":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_account_device { "${swift01_local_net_ip}:6002/sdb":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_account_device { "${swift01_local_net_ip}:6002/sdc":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_account_device { "${swift01_local_net_ip}:6002/sdd":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_account_device { "${swift01_local_net_ip}:6002/sde":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_account_device { "${swift01_local_net_ip}:6002/sdf":
    zone        => $swift_zone,
    weight      => 1,
  }

  # collect resources for synchronizing the ring databases
  # You need to comment-out the following line after the node has been added to the ring.
  # Or else you will receive a puppet agent error: 
  # Exported resource Swift::Ringsync[account] cannot override local resource.
  Swift::Ringsync<<||>>
}

# The following specifies the 2nd Swift Storage Node.
node /swift02/ inherits swift_base {

  network_config { "$::storage_interface":
    ensure     => 'present',
    hotplug    => 'false',
    family     => 'inet',
    method     => 'static',
    ipaddress  => $swift02_local_net_ip,
    netmask    => $swift_local_net_mask,
    onboot     => 'true',
    notify     => Exec['network-restart']
  }

  # Changed from service to exec due to Ubuntu bug #440179
  exec { 'network-restart':
    command     => '/etc/init.d/networking restart',
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    refreshonly => true
  }

  # install all swift storage servers together
  class { 'swift::storage::all':
    storage_local_net_ip => $swift02_local_net_ip,
  }

  # Include class to configure hard disks
  include swift-ucs-disk

  # Specify the zone the storage node should reside in
  $swift_zone = 2

  # specify endpoints per device to be added to the ring specification
  @@ring_object_device { "${swift02_local_net_ip}:6000/sdb":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_object_device { "${swift02_local_net_ip}:6000/sdc":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_object_device { "${swift02_local_net_ip}:6000/sdd":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_object_device { "${swift02_local_net_ip}:6000/sde":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_object_device { "${swift02_local_net_ip}:6000/sdf":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_container_device { "${swift02_local_net_ip}:6001/sdb":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_container_device { "${swift02_local_net_ip}:6001/sdc":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_container_device { "${swift02_local_net_ip}:6001/sdd":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_container_device { "${swift02_local_net_ip}:6001/sde":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_container_device { "${swift02_local_net_ip}:6001/sdf":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_account_device { "${swift02_local_net_ip}:6002/sdb":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_account_device { "${swift02_local_net_ip}:6002/sdc":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_account_device { "${swift02_local_net_ip}:6002/sdd":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_account_device { "${swift02_local_net_ip}:6002/sde":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_account_device { "${swift02_local_net_ip}:6002/sdf":
    zone        => $swift_zone,
    weight      => 1,
  }

  # collect resources for synchronizing the ring databases
  # You need to comment-out the following line after the node has been added to the ring.
  # Or else you will receive a puppet agent error: 
  # Exported resource Swift::Ringsync[account] cannot override local resource.
  Swift::Ringsync<<||>>
}

# The following specifies the 3rd Swift Storage Node.
node /swift03/ inherits swift_base {

  network_config { "$::storage_interface":
    ensure     => 'present',
    hotplug    => 'false',
    family     => 'inet',
    method     => 'static',
    ipaddress  => $swift03_local_net_ip,
    netmask    => $swift_local_net_mask,
    notify     => Exec['network-restart']
  }

  # Changed from service to exec due to Ubuntu bug #440179
  exec { 'network-restart':
    command     => '/etc/init.d/networking restart',
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    refreshonly => true
  }

  # install all swift storage servers together
  class { 'swift::storage::all':
    storage_local_net_ip => $swift03_local_net_ip,
  }

  # Include class to configure hard disks
  include swift-ucs-disk

  # Specify the zone the storage node should reside in
  $swift_zone = 3

  # specify endpoints per device to be added to the ring specification
  @@ring_object_device { "${swift03_local_net_ip}:6000/sdb":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_object_device { "${swift03_local_net_ip}:6000/sdc":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_object_device { "${swift03_local_net_ip}:6000/sdd":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_object_device { "${swift03_local_net_ip}:6000/sde":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_object_device { "${swift03_local_net_ip}:6000/sdf":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_container_device { "${swift03_local_net_ip}:6001/sdb":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_container_device { "${swift03_local_net_ip}:6001/sdc":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_container_device { "${swift03_local_net_ip}:6001/sdd":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_container_device { "${swift03_local_net_ip}:6001/sde":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_container_device { "${swift03_local_net_ip}:6001/sdf":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_account_device { "${swift03_local_net_ip}:6002/sdb":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_account_device { "${swift03_local_net_ip}:6002/sdc":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_account_device { "${swift03_local_net_ip}:6002/sdd":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_account_device { "${swift03_local_net_ip}:6002/sde":
    zone        => $swift_zone,
    weight      => 1,
  }

  @@ring_account_device { "${swift03_local_net_ip}:6002/sdf":
    zone        => $swift_zone,
    weight      => 1,
  }

  # collect resources for synchronizing the ring databases
  # You need to comment-out the following line after the node has been added to the ring.
  # Or else you will receive a puppet agent error: 
  # Exported resource Swift::Ringsync[account] cannot override local resource.
  Swift::Ringsync<<||>>
}

# Used to create XFS volumes for Swift storage nodes.
class swift-ucs-disk {

  $byte_size = '1024'
  $size = '499GB'
  $mnt_base_dir = '/srv/node'

  swift::storage::disk { 'sdb':
    device => "sdb",
    mnt_base_dir => $mnt_base_dir,
    byte_size => $byte_size,
    size => $size
  }

  swift::storage::disk { 'sdc':
    device => "sdc",
    mnt_base_dir => $mnt_base_dir,
    byte_size => $byte_size,
    size => $size
  }

  swift::storage::disk { 'sdd':
    device => "sdd",
    mnt_base_dir => $mnt_base_dir,
    byte_size => $byte_size,
    size => $size
  }

  swift::storage::disk { 'sde':
    device => "sde",
    mnt_base_dir => $mnt_base_dir,
    byte_size => $byte_size,
    size => $size
  }

  swift::storage::disk { 'sdf':
    device => "sdf",
    mnt_base_dir => $mnt_base_dir,
    byte_size => $byte_size,
    size => $size
  }
}

# The following specifies the 1st swift proxy node
node /swiftproxy01/ inherits swift_base {

  network_config { "$::storage_interface":
    ensure     => 'present',
    hotplug    => 'false',
    family     => 'inet',
    method     => 'static',
    ipaddress  => $swiftproxy01_local_net_ip,
    netmask    => $swift_local_net_mask,
    onboot     => 'true',
    notify     => Exec['network-restart']
  }
  
  # Changed from service to exec due to Ubuntu bug #440179
  exec { 'network-restart':
    command     => '/etc/init.d/networking restart',
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    refreshonly => true
  }

  # curl is only required to run tests against the proxy server
  package { 'curl': ensure => present }

  class { 'memcached':
    listen_ip => $swiftproxy01_local_net_ip,
  }

  # specify swift proxy and all of its middlewares
  class { 'swift::proxy':
    proxy_local_net_ip => $swiftproxy01_public_net_ip,
    pipeline           => [
      'catch_errors',
      'healthcheck',
      'cache',
      'ratelimit',
      # Disable 'swift3' to support the original Cisco Swift Puppet module
      #'swift3',
      's3token',
      'authtoken',
      'keystone',
      'proxy-server'
    ],
    account_autocreate => true,
    require            => Class['swift::ringbuilder'],
  }

  # configure all of the middlewares
  class { [
    'swift::proxy::catch_errors',
    'swift::proxy::healthcheck',
    # Disable 'swift3' to support the original Cisco Swift Puppet module
    #'swift::proxy::swift3',
  ]: 
  }
  
  class { 'swift::proxy::cache':
    memcache_servers  	   => $swift_memcache_servers,   
  }

  class { 'swift::proxy::ratelimit':
    clock_accuracy         => 1000,
    max_sleep_time_seconds => 60,
    log_sleep_time_seconds => 0,
    rate_buffer_seconds    => 5,
    account_ratelimit      => 0,
  }
  class { 'swift::proxy::s3token':
    auth_host     => $keystone_host,
    auth_port     => '35357',
  }
  class { 'swift::proxy::keystone':
    operator_roles => ['admin', 'SwiftOperator'],
  }
  class { 'swift::proxy::authtoken':
    admin_user        => $swift_auth_user,
    admin_tenant_name => $swift_auth_tenant,
    admin_password    => $swift_auth_password,
    auth_host         => $keystone_host,
    # The following is only needed for original Cisco Swift modules
    #signing_dir       => '/etc/swift'
  }

  # collect all of the resources that are needed to balance the ring
  Ring_object_device <<| |>>
  Ring_container_device <<| |>>
  Ring_account_device <<| |>>

  # create the ring
  class { 'swift::ringbuilder':
    # the part power should be determined by assuming 100 partitions per drive
    part_power     => '18',
    replicas       => '3',
    min_part_hours => 1,
    require        => Class['swift'],
  }

  # sets up an rsync db that can be used to sync the ring DB
  class { 'swift::ringserver':
    local_net_ip => $swiftproxy01_local_net_ip,
  }

  # exports rsync gets that can be used to sync the ring files
  @@swift::ringsync { ['account', 'object', 'container']:
   ring_server => $swiftproxy01_local_net_ip,
  }
}

# The following specifies the 2nd swift proxy node
node /swiftproxy02/ inherits swift_base {

  network_config { "$::storage_interface":
    ensure     => 'present',
    hotplug    => 'false',
    family     => 'inet',
    method     => 'static',
    ipaddress  => $swiftproxy02_local_net_ip,
    netmask    => $swift_local_net_mask,
    onboot     => 'true',
    notify     => Exec['network-restart']
  }

  # Changed from service to exec due to Ubuntu bug #440179
  exec { 'network-restart':
    command     => '/etc/init.d/networking restart',
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    refreshonly => true
  }
 
  # curl is only required to run tests aginst the proxy server.
  package { 'curl': ensure => present }

  class { 'memcached':
    listen_ip => $swiftproxy02_local_net_ip,
  }

  # specify swift proxy and all of its middlewares
  class { 'swift::proxy':
    proxy_local_net_ip => $swiftproxy02_public_net_ip,
    pipeline           => [
      'catch_errors',
      'healthcheck',
      'cache',
      'ratelimit',
      # Disable 'swift3' to support the original Cisco Swift Puppet module
      #'swift3',
      's3token',
      'authtoken',
      'keystone',
      'proxy-server'
    ],
    account_autocreate => true,
    require            => Class['swift::ringbuilder'],
  }

  # configure all of the middlewares
  class { [
    'swift::proxy::catch_errors',
    'swift::proxy::healthcheck',
    # Disable 'swift3' to support the original Cisco Swift Puppet module
    #'swift::proxy::swift3',
  ]: 
  }
  
  class { 'swift::proxy::cache':
    memcache_servers  	   => $swift_memcache_servers,   
  }

  class { 'swift::proxy::ratelimit':
    clock_accuracy         => 1000,
    max_sleep_time_seconds => 60,
    log_sleep_time_seconds => 0,
    rate_buffer_seconds    => 5,
    account_ratelimit      => 0,
  }
  class { 'swift::proxy::s3token':
    auth_host     => $keystone_host,
    auth_port     => '35357',
  }
  class { 'swift::proxy::keystone':
    operator_roles => ['admin', 'SwiftOperator'],
  }
  class { 'swift::proxy::authtoken':
    admin_user        => $swift_auth_user,
    admin_tenant_name => $swift_auth_tenant,
    admin_password    => $swift_auth_password,
    auth_host         => $keystone_host,
    # The following is only needed for original Cisco Swift modules
    #signing_dir       => '/etc/swift'  
  }

  # collect all of the resources that are needed to balance the ring
  Ring_object_device <<| |>>
  Ring_container_device <<| |>>
  Ring_account_device <<| |>>

  # create the ring
  class { 'swift::ringbuilder':
    # the part power should be determined by assuming 100 partitions per drive
    part_power     => '18',
    replicas       => '3',
    min_part_hours => 1,
    require        => Class['swift'],
  }

  # sets up an rsync db that can be used to sync the ring DB
  class { 'swift::ringserver':
    local_net_ip => $swiftproxy02_local_net_ip,
  }

  # exports rsync gets that can be used to sync the ring files
  @@swift::ringsync { ['account', 'object', 'container']:
   ring_server => $swiftproxy02_local_net_ip,
  }

}
