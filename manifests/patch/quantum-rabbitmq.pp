# This class installs a patch to quantum that enables RabbitMQ HA support
# and configures the appropriate parameters.
#
# ==Parameters
#  [rabbit_hosts] List of RabbitMQ HA cluster members (host:port)
class openstack-ha::patch::quantum-rabbitmq (
    $rabbit_hosts = false
  ) {
  include openstack-ha::patch
  
  file { "/tmp/quantum-rabbit.patch":
    ensure => present,
    source => 'puppet:///modules/openstack-ha/quantum-rabbit.patch'
  }
  
  exec { 'patch-quantum':
    unless  => "/bin/grep x-ha-policy /usr/lib/python2.7/dist-packages/quantum/openstack/common/rpc/impl_kombu.py",
    command => "/usr/bin/patch -p1 -d /usr/lib/python2.7/dist-packages/quantum </tmp/quantum-rabbit.patch",
    require => [ [File['/tmp/quantum-rabbit.patch']],[Package['patch', 'quantum']]],
    subscribe => Package['quantum']
  } -> Quantum_config <| |>
  
  quantum_config { 'DEFAULT/rabbit_ha_queues': value => 'True' }

  if $rabbit_hosts {
    quantum_config { 'DEFAULT/rabbit_hosts': value => inline_template("<%= @rabbit_hosts.map {|x| x+':5672'}.join ',' %>") }
  } else {
    Quantum_config <<| title == 'DEFAULT/rabbit_hosts' |>>
  }
}
