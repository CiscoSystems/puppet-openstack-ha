#
# == Class: openstack-ha::quantum::controller
#
# Class to define quantum components used on an OpenStack Controller Node.
#
# === Parameters
#
# See params.pp
#
# === Examples
#
# class { 'openstack-ha::quantum::controller':
#   enable_l3_dhcp_agents => true,
#   db_host               => '127.0.0.1',
#   rabbit_password       => 'changeme',
#   bridge_interface      => 'eth0',
# }
#

class openstack-ha::quantum::controller (
  # Database Required
  $db_host,
  # Networking Required
  $internal_address,
  # Rabbit Required
  $rabbit_password        = 'quantum_pass',
  # enable or disable quantum
  $enabled                = true,
  # Set DHCP/L3 Agents on Primary Controller
  $enable_l3_dhcp_agents  = undef,
  # networking and Interface Information
  $bridge_interface       = undef,
  $external_bridge_name   = 'br-ex',
  # Quantum Database Information
  $quantum_db_dbname      = 'quantum',
  $quantum_db_user        = 'quantum',
  $quantum_db_password    = 'quantum_pass',
  # Quantum Authentication Information
  $quantum_l3_auth_url    = 'http://localhost:35357/v2.0',
  $quantum_user_password  = 'quantum_pass',
  # Rabbit Information
  $cluster_rabbit	  = true,
  $rabbit_hosts           = [],
  $rabbit_user            = 'quantum',
  $rabbit_host		  = false,
  $rabbit_virtual_host    = '/',
  # Database. Currently mysql is the only option.
  $db_type                = 'mysql',
  # Nova Information
  $nova_metadata_ip       = '169.254.169.254',
  # General
  $bind_address		  = '0.0.0.0',
  $keystone_host          = '127.0.0.1',
  $verbose                = 'False',
  $enabled                = true
) {

  ####### DATABASE SETUP ######
  # set up mysql server
  if ($db_type == 'mysql') {
      $quantum_db = "mysql://${quantum_db_user}:${quantum_db_password}@${db_host}/${quantum_db_dbname}?charset=utf8"
    if ($enabled) {
      # Ensure things are run in order
      Class['quantum::db::mysql'] -> Class['quantum::plugins::ovs']
      Class['quantum::db::mysql'] -> Class['quantum::agents::ovs']
    }
  }

  $sql_connection         = $quantum_db

  if $cluster_rabbit {
    class { 'openstack-ha::patch::quantum-rabbitmq':
      rabbit_hosts => $rabbit_hosts
    }
  }

  class { 'quantum':
    enabled             => $enabled,
    bind_host           => $bind_address,
    rabbit_host         => $rabbit_host,
    rabbit_virtual_host => $rabbit_virtual_host,
    rabbit_user         => $rabbit_user,
    rabbit_password     => $rabbit_password,
    verbose             => $verbose,
    debug               => $verbose,
  }

  class { 'quantum::server':
    auth_host	  => $keystone_host,
    auth_password => $quantum_user_password,
  }

  class { 'quantum::plugins::ovs':
    sql_connection      => $sql_connection,
    tenant_network_type => 'gre',
  }

  class { 'quantum::agents::ovs':
    bridge_uplinks   => ["${external_bridge_name}:${bridge_interface}"],
    bridge_mappings  => ["default:${external_bridge_name}"],
    enable_tunneling => true,
    local_ip         => $internal_address,
  }

  if $enable_l3_dhcp_agents {
    class { 'quantum::agents::dhcp':
      use_namespaces => True,
    }
    class {"quantum::agents::l3":
      interface_driver => $l3_interface_driver,
      use_namespaces   => 'true',
      metadata_ip      => $nova_metadata_ip,
      auth_tenant      => 'services',
      auth_url	       => $quantum_l3_auth_url,
      auth_password    => $quantum_user_password,
    }
  }

}
