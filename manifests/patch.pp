# Class to ensure the necessary packages are present
# to patch OpenStack services.
#
class openstack-ha::patch {
  package { 'patch':
    ensure => present,
  }

  package { 'python-pip':
    ensure => present,
    require => Package['python'],
  }

  package { 'kombu':
    ensure => '2.4.7',
    provider => pip,
    require => Package['python-pip'],
  }

  package { 'anyjson':
    ensure => '0.3.3',
    provider => pip,
    require => Package['python-pip'],
  }

  package { 'amqp':
    ensure => '0.9.4',
    provider => pip,
    require => Package['python-pip'],
  }

}
