#
# == Class: openstack-ha::nova::controller
#
# Class to define nova components used in a controller architecture.
# Basically everything but nova-compute and nova-volume
#
# === Parameters
#
# See params.pp
#
# === Examples
#
# class { 'openstack-ha::nova::controller':
#   public_address     => '192.168.1.1',
#   db_host            => '127.0.0.1',
#   rabbit_password    => 'changeme',
#   nova_user_password => 'changeme',
#   nova_db_password   => 'changeme',
# }
#

class openstack-ha::nova::controller (
  # Network Required
  $public_address,
  # Database Required
  $db_host,
  # Rabbit Required
  $rabbit_password,
  # Nova Required
  $nova_user_password,
  $nova_db_password,
  $memcached_servers,
  # Network
  $network_manager           = 'nova.network.manager.FlatDHCPManager',
  $network_config            = {},
  $floating_range            = false,
  $fixed_range               = '10.0.0.0/24',
  $admin_address             = $public_address,
  $internal_address          = $public_address,
  $auto_assign_floating_ip   = false,
  $create_networks           = true,
  $num_networks              = 1,
  $multi_host                = false,
  $public_interface          = undef,
  $private_interface         = undef,
  # quantum
  $quantum                   = true,
  $quantum_user_password     = 'quantum_pass',
  # Nova
  $nova_db_user              = 'nova',
  $nova_db_dbname            = 'nova',
  # Rabbit
  $cluster_rabbit	     = true,
  $rabbit_hosts              = [],
  $cluster_disk_nodes        = [],
  $rabbit_host		     = false,
  $rabbit_user               = 'nova',
  $rabbit_virtual_host       = '/',
  # Database
  $db_type                   = 'mysql',
  # Glance
  $glance_api_servers        = undef,
  # VNC
  $vnc_enabled               = true,
  # General
  $keystone_host             = '127.0.0.1',
  $api_bind_address          = '0.0.0.0',
  $cinder		     = false,
  $nova_volume               = true,
  $verbose                   = 'False',
  $enabled                   = true
) {

  # Configure the db string
  case $db_type {
    'mysql': {
      $nova_db = "mysql://${nova_db_user}:${nova_db_password}@${db_host}/${nova_db_dbname}"
      Class['openstack::db::mysql'] -> Class['nova::rabbitmq']
    }
  }

  if ($glance_api_servers == undef) {
    $real_glance_api_servers = "${public_address}:9292"
  } else {
    $real_glance_api_servers = $glance_api_servers
  }

  $sql_connection    = $nova_db
  $glance_connection = $real_glance_api_servers

  # Install / configure rabbitmq
  if $cluster_rabbit {
    # configure rabbit clustering
    class { 'nova::rabbitmq':
      userid             => $rabbit_user,
      password           => $rabbit_password,
      cluster            => true,
      cluster_disk_nodes => $cluster_disk_nodes,
      virtual_host       => $rabbit_virtual_host,
      enabled            => $enabled,
    }
    # install and configure rabbitmq mirrored queues nova patch
    class { 'openstack-ha::patch::nova-rabbitmq':
      rabbit_hosts => $rabbit_hosts
    }
  } else {
    class { 'nova::rabbitmq':
      userid             => $rabbit_user,
      password           => $rabbit_password,
      virtual_host       => $rabbit_virtual_host,
      enabled            => $enabled,
    }
  }

  # Configure Nova
  class { 'nova':
    sql_connection       => $sql_connection,
    rabbit_userid        => $rabbit_user,
    rabbit_password      => $rabbit_password,
    rabbit_virtual_host  => $rabbit_virtual_host,
    image_service        => 'nova.image.glance.GlanceImageService',
    glance_api_servers   => $glance_connection,
    verbose              => $verbose,
    rabbit_host          => $rabbit_host,
  }

  if ($cinder) and ! ($nova_volume) {
    # Configure nova-api
    class { 'nova::api':
      enabled           => $enabled,
      api_bind_address  => $api_bind_address,
      volume_api_class  => 'nova.volume.cinder.API',
      enabled_apis      => 'ec2,osapi_compute,metadata',
      admin_password    => $nova_user_password,
      auth_host         => $keystone_host,
    }
  } elsif ($nova_volume) and ! ($cinder) {
    class { 'nova::api':
      enabled           => $enabled,
      api_bind_address  => $api_bind_address,
      volume_api_class  => 'nova.volume.api.API',
      enabled_apis      => 'ec2,osapi_compute,osapi_volume,metadata',
      admin_password    => $nova_user_password,
      auth_host         => $keystone_host,
    }
  } elsif ($nova_volume) and ($cinder) {
    fail('Both nova-volume and Cinder can not be enabled.')
  } else {
  # no cinder or nova-volume
 }

  if $enabled {
    $really_create_networks = $create_networks
  } else {
    $really_create_networks = false
  }

  if $quantum == false {
    # Configure nova-network
    if $multi_host {
      nova_config { 'multi_host': value => 'True' }
      $enable_network_service = false
    } else {
      if $enabled {
        $enable_network_service = true
      } else {
        $enable_network_service = false
      }
    }

    if $auto_assign_floating_ip {
      nova_config { 'auto_assign_floating_ip': value => 'True' }
    }

    class { 'nova::network':
      private_interface => $private_interface,
      public_interface  => $public_interface,
      fixed_range       => $fixed_range,
      floating_range    => $floating_range,
      network_manager   => $network_manager,
      config_overrides  => $network_config,
      create_networks   => $really_create_networks,
      num_networks      => $num_networks,
      enabled           => $enable_network_service,
      install_service   => $enable_network_service,
    }
  } else {
    # Configure Nova for Quantum networking
    class { 'nova::network::quantum':
      quantum_admin_password    => $quantum_user_password,
      quantum_auth_strategy     => 'keystone',
      quantum_url               => "http://${keystone_host}:9696",
      quantum_admin_tenant_name => 'services',
      quantum_admin_auth_url    => "http://${keystone_host}:35357/v2.0",
    }
  }

  # Nova services that require no configuration
  class { [
    'nova::scheduler',
    'nova::consoleauth'
  ]:
    enabled => $enabled,
  }

  class { 'openstack-ha::patch::nova-consoleauth':
    memcached_servers => $memcached_servers
  }

  if $vnc_enabled {
    class { 'nova::vncproxy':
      host    => $public_address,
      enabled => $enabled,
    }
  }

}
