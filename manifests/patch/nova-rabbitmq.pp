# This class installs a patch to nova that enables RabbitMQ HA support
# and configures the appropriate parameters.
# Code Review https://review.openstack.org/#/c/13665/
#
# ==Parameters
#  [rabbit_hosts] List of RabbitMQ HA cluster members (host:port)
class openstack-ha::patch::nova-rabbitmq (
    $rabbit_hosts = false
  ) {
  include openstack-ha::patch
  
  file { "/tmp/nova-rabbit.patch":
    ensure => present,
    source => 'puppet:///modules/openstack-ha/nova-rabbit.patch'
  }
  
  exec { "patch-nova":
    unless  => '/bin/grep x-ha-policy /usr/lib/python2.7/dist-packages/nova/openstack/common/rpc/impl_kombu.py',
    command => '/usr/bin/patch -p1 -d /usr/lib/python2.7/dist-packages/nova </tmp/nova-rabbit.patch',
    require => [[File['/tmp/nova-rabbit.patch']],[Package['patch', 'python-nova']]],
    subscribe => Package['python-nova']
  } ->  Nova_config <| |>
  
  nova_config { 'rabbit_ha_queues': value => 'True' }

  if $rabbit_hosts {
    nova_config { 'rabbit_hosts': value => inline_template("<%= @rabbit_hosts.map {|x| x+':5672'}.join ',' %>") }
  } else {
    Nova_config <<| title == 'rabbit_hosts' |>>
  }
}
