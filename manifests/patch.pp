# Class to ensure the necessary packages are present
# to patch OpenStack services.
#
class openstack-ha::patch {
  package { 'patch':
    ensure => present,
  }
}
