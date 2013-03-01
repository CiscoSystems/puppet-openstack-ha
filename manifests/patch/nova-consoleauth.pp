# This class installs a patch for nova-consoleauth that enables HA support
# and configures the appropriate parameters.
#
# ==Parameters
#  [memcached_servers] List of memcahced server ip addresses.
class openstack-ha::patch::nova-consoleauth (
    $memcached_servers = false
  ) {

  file { "/usr/lib/python2.7/dist-packages/nova/consoleauth/manager.py":
    ensure => present,
    source => 'puppet:///modules/openstack-ha/patched-consoleauth-manager.py',
    owner   => 'root',
    group   => 'root',
    mode    => '755',
    require => Package['nova-consoleauth'],
    notify  => Service['nova-consoleauth'],
  }
  
#  exec { "patch-consoleauth":
#    unless  => "/bin/grep \"(str(token)\" /usr/lib/python2.7/dist-packages/nova/consoleauth/manager.py",
#    command => "/usr/bin/patch -p1 -d /usr/lib/python2.7/dist-packages/nova/consoleauth </tmp/consoleauth-manager.patch",
#    require => [ [File['/tmp/consoleauth-manager.patch']],[Package['patch']]],
    #subscribe => Package['nova-consoleauth']
#  }
  
  if $memcached_servers {
    nova_config { 'memcached_servers': value => inline_template("<%= @memcached_servers.map {|x| x+':11211'}.join ',' %>") }
  } else {
    Nova_config <<| title == 'memcached_servers' |>>
  }
}
