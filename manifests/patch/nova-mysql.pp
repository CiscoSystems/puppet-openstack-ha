class openstack-ha::patch::nova-mysql {
  include openstack-ha::patch

  file { "/tmp/mysql.patch":
    ensure => present,
    source => 'puppet:///modules/openstack-ha/nova-mysql.patch'
  }

  exec { 'patch-nova-mysql':
    unless    => "/bin/grep sql_inc_retry_interval /usr/lib/python2.7/dist-packages/nova/flags.py",
    command   => "/usr/bin/patch -p1 -d /usr/lib/python2.7/dist-packages/nova </tmp/mysql.patch",
    require   => [[File['/tmp/mysql.patch']],[Package['patch','python-nova']]], 
    subscribe => Package['python-nova']
  } ->
  # Do this BEFORE any nova services are started
  Nova_config <| |>
}
