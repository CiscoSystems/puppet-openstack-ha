#
# == Class: openstack-ha::compute
#
# Manifest to install/configure nova-compute
#
# === Parameters
#
# See params.pp
#
# === Examples
#
# class { 'openstack-ha::nova::compute':
#   internal_address   => '192.168.2.2',
#   vncproxy_host      => '192.168.1.1',
#   rabbit_password    => 'openstack_rabbit_password',
#   nova_user_password => 'changeme',
# }

class openstack-ha::compute (
  # Required Network
  $internal_address,
  # Required Nova
  $nova_user_password,
  # Required Rabbit
  $rabbit_password,
  # Database
  $db_type                       = 'mysql',
  $db_host                       = '127.0.0.1',
  # Nova Database
  $nova_db_user		         = 'nova',
  $nova_db_password	  	 = 'nova_pass',
  $nova_db_dbname		 = 'nova',
  # Quantum Database
  $quantum_db_dbname      	 = 'quantum',
  $quantum_db_user        	 = 'quantum',
  $quantum_db_password    	 = 'quantum_pass',
  # Network
  $quantum_bind_address		 = '0.0.0.0',
  $public_interface              = undef,
  $private_interface             = undef,
  $fixed_range                   = undef,
  $network_manager               = 'nova.network.manager.FlatDHCPManager',
  $network_config                = {},
  $multi_host                    = false,
  # Quantum
  $quantum                       = false,
  $quantum_user_password         = 'quantum_pass',
  $keystone_host                 = '127.0.0.1',
  $bridge_interface		 = $public_interface,
  # Nova
  $metadata_address              = '169.254.169.254', 
  $api_bind_address		 = '0.0.0.0',
  $purge_nova_config             = false,
  $libvirt_vif_driver	 	 = 'nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver',
  # Rabbit
  $cluster_rabbit                = true,
  $rabbit_hosts                  = [],
  $rabbit_user                   = 'openstack',
  $rabbit_host			 = '127.0.0.1',
  $rabbit_virtual_host           = '/',
  # Glance
  $glance_api_servers            = false,
  # Virtualization
  $libvirt_type                  = 'kvm',
  # VNC
  $vnc_enabled                   = true,
  $vncproxy_host                 = undef,
  $vncserver_listen              = false,
  # cinder / volumes
  $cinder                        = false,
  $cinder_db_user		 = 'cinder',
  $cinder_db_password		 = 'cinder_pass',
  $cinder_db_dbname		 = 'cinder',
  $manage_volumes                = true,
  # Temp until Cinder Testing
  $cinder_volume                 = 'cinder-volumes',
  $nova_volume_enable		 = true,
  $nova_volume                   = 'nova-volumes',
  # General
  $migration_support             = false,
  $verbose                       = 'False',
  $enabled                       = true
) {

  # Configure the db string
  case $db_type {
    'mysql': {

      # Patch mysql
      class { 'openstack-ha::patch::nova-mysql': }

      $nova_sql_connection = "mysql://${nova_db_user}:${nova_db_password}@${db_host}/${nova_db_dbname}"
      $cinder_sql_connection = "mysql://${cinder_db_user}:${cinder_db_password}@${db_host}/${cinder_db_dbname}"
      $quantum_sql_connection = "mysql://${quantum_db_user}:${quantum_db_password}@${db_host}/${quantum_db_dbname}?charset=utf8"
    }
  }

  # Patch Kombu client libraries to support RabbitMQ 
  # mirrored queues for Nova and Quantum.
  if $cluster_rabbit {
    if ($quantum) {
      class { 'openstack-ha::patch::quantum-rabbitmq':
        rabbit_hosts => $rabbit_hosts
      }
    }
    class { 'openstack-ha::patch::nova-rabbitmq':
      rabbit_hosts => $rabbit_hosts
    }

   $rabbit_host_real = false
  } else {
   $rabbit_host_real = $rabbit_host
  }

  class { 'nova':
    sql_connection      => $nova_sql_connection,
    rabbit_host         => $rabbit_host_real,
    rabbit_userid       => $rabbit_user,
    rabbit_password     => $rabbit_password,
    image_service       => 'nova.image.glance.GlanceImageService',
    glance_api_servers  => $glance_api_servers,
    verbose             => $verbose,
    rabbit_virtual_host => $rabbit_virtual_host,
  }

  if $vncserver_listen {
    $vncserver_listen_real = $vncserver_listen
  } else {
    $vncserver_listen_real = $internal_address
  }


  # Indicates that all nova config entries that we did
  # not specify in Puppet should be purged from file
  if ! defined( Resources[nova_config] ) {
    if ($purge_nova_config) {
      resources { 'nova_config':
        purge => true,
      }
    }
  }

  # Install / configure nova-compute
  class { '::nova::compute':
    enabled                       => $enabled,
    vnc_enabled                   => $vnc_enabled,
    vncserver_proxyclient_address => $internal_address,
    vncproxy_host                 => $vncproxy_host,
  }

  # Configure libvirt for nova-compute
  class { 'nova::compute::libvirt':
    libvirt_type      => $libvirt_type,
    vncserver_listen  => $vncserver_listen_real,
    migration_support => $migration_support,
  }

  # if the compute node should be configured as a multi-host
  # compute installation
  if ! $quantum {

    if ! $fixed_range {
      fail("Must specify the fixed range when using nova-networks")
    }

    if $multi_host {
      include keystone::python
      nova_config {
        'multi_host':      value => 'True';
        'send_arp_for_ha': value => 'True';
      }
      if ! $public_interface {
        fail('public_interface must be defined for multi host compute nodes')
      }
      $enable_network_service = true
      if ($cinder) {
        $volume_api_class_real = 'nova.volume.cinder.API'
        $enabled_apis_real     = 'ec2,osapi_compute,metadata'
      } else {
        $volume_api_class_real = 'nova.volume.api.API'
        $enabled_apis_real     = 'ec2,osapi_compute,osapi_volume,metadata'
      }
      class { 'nova::api':
        enabled           => $enabled,
        admin_tenant_name => 'services',
        admin_user        => 'nova',
        admin_password    => $nova_user_password,
        api_bind_address  => $api_bind_address,
        enabled_apis	  => $enabled_apis_real,
        volume_api_class  => $volume_api_class_real,
      }
    } else {
      $enable_network_service = false
      nova_config {
        'multi_host':      value => 'False';
        'send_arp_for_ha': value => 'False';
      }
    }

    class { 'nova::network':
      private_interface => $private_interface,
      public_interface  => $public_interface,
      fixed_range       => $fixed_range,
      floating_range    => false,
      network_manager   => $network_manager,
      config_overrides  => $network_config,
      create_networks   => false,
      enabled           => $enable_network_service,
      install_service   => $enable_network_service,
    }
  } else {

    if ! $quantum_sql_connection {
      fail('quantum sql connection must be specified when quantum is installed on compute instances')
    }
    if ! $quantum_user_password {
      fail('quantum user password must be set when quantum is configured')
    }
    if ! $keystone_host {
      fail('keystone host must be configured when quantum is installed')
    }

    # Install and configure Quantum networking.
    class { 'quantum':
      enabled             => $enabled,
      bind_host           => $quantum_bind_address,
      rabbit_user         => $rabbit_user,
      rabbit_password     => $rabbit_password,
      verbose             => $verbose,
      debug               => $verbose,
    }

    class { 'quantum::plugins::ovs':
      sql_connection      => $quantum_sql_connection,
      tenant_network_type => 'gre',
    }

    class { 'quantum::agents::ovs':
      bridge_uplinks   => false,
      enable_tunneling => true,
      local_ip         => $internal_address,
    }

    class { 'nova::compute::quantum': 
      libvirt_vif_driver => $libvirt_vif_driver,
    }

    nova_config {
      'metadata_host': value => $metadata_address;
    }

    # Configures nova.conf entries applicable to Quantum.
    class { 'nova::network::quantum':
      quantum_admin_password    => $quantum_user_password,
      quantum_auth_strategy     => 'keystone',
      quantum_url               => "http://${keystone_host}:9696",
      quantum_admin_tenant_name => 'services',
      quantum_admin_auth_url    => "http://${keystone_host}:35357/v2.0",
    }

    nova_config {
      'linuxnet_interface_driver':       value => 'nova.network.linux_net.LinuxOVSInterfaceDriver';
      'linuxnet_ovs_integration_bridge': value => 'br-int';
    }
  }

  if ($cinder) {
    class { 'cinder::base':
      rabbit_password => $rabbit_password,
      rabbit_host     => $rabbit_host,
      sql_connection  => $cinder_sql_connection,
      verbose         => $verbose,
    }
    class { 'cinder::volume': }
    class { 'cinder::volume::iscsi':
      iscsi_ip_address => $internal_address,
      volume_group     => $cinder_volume,
    }
  } 
  if ($nova_volume_enable) {
    # Set up nova-volume
    class { 'nova::volume':
      enabled => $enabled, 
    }
    class { 'nova::volume::iscsi':
      volume_group     => $nova_volume,
      iscsi_ip_address => $internal_address,
    } 
  }

}
