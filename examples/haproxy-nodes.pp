#
# This file is to serve as an example for deploying 
# two dedicated HAproxy nodes for load-balancing 
# three OpenStack Controllers and two Swift Proxies
# This example file should then be imported into your Site.pp manifest
# Change slb01 and slb02 node names to the hostnames of your HAProxy nodes.

node /slb01/ inherits base {

  # Required for supporting a virtual IP address not directly associated to the node.
  sysctl::value { "net.ipv4.ip_nonlocal_bind": value => "1" }

  # Keepalived is used to provide high-availability between HAProxy Nodes.
  # Two instances are created, one for the Controller Cluster VIP and the other for the Swift Proxy VIP.
  # Take note that this node is active for the Controller VIP.
  class { keepalived: }
  
  keepalived::instance { '50':
    interface         => 'eth0',
    virtual_ips       => "${controller_cluster_vip} dev eth0",
    state             => 'MASTER',
    priority          => '101',
    track_script      => ['haproxy'],
  }

  keepalived::vrrp_script { 'haproxy':
    name_is_process   => true,
  }

  # Take note that this node is the backup for the Swift Proxy VIP.
  keepalived::instance { '51':
    interface         => 'eth0',
    virtual_ips       => "${swiftproxy_cluster_vip} dev eth0",
    state             => 'BACKUP',
    priority          => '100',
  }

  # This class configures all global, default, and server cluster parameters.
  # Note that all haproxy::config definition use the Controller VIP except the swift_proxy_cluster.
  class { 'haproxy': }

  haproxy::listen { 'galera_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '3306',
    options   => {
      'option'  => ['httpchk'],
      'mode'    => 'tcp',
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'galera': 
    listening_service => 'galera_cluster',
    ports             => '3306',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    # Note: Checking port 9200 due to health_check script.
    options           => 'check port 9200 inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'keystone_public_internal_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '5000',
    options   => {
      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'keystone_public_internal':
    listening_service => 'keystone_public_internal_cluster',
    ports             => '5000',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'keystone_admin_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '35357',
    options   => {
      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'keystone_admin':
    listening_service => 'keystone_admin_cluster',
    ports             => '35357',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'nova_compute_api1_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '8773',
    # Note: httpchk removed
    options   => {
      'option'  => ['tcpka', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'nova_compute01':
    listening_service => 'nova_compute_api1_cluster',
    ports             => '8773',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'nova_compute_api2_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '8774',
    options   => {
      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'nova_compute02':
    listening_service => 'nova_compute_api2_cluster',
    ports             => '8774',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'nova_compute_api3_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '8775',
    # Note: httpchk removed
    options   => {
      'option'  => ['tcpka', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'nova_compute03':
    listening_service => 'nova_compute_api3_cluster',
    ports             => '8775',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'nova_volume_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '8776',
    options   => {
      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'nova_volume':
    listening_service => 'nova_volume_cluster',
    ports             => '8776',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'glance_registry_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '9191',
    options   => {
      'option'  => ['tcpka', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'glance_registry':
    listening_service => 'glance_registry_cluster',
    ports             => '9191',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'glance_api_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '9292',
    options   => {
      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'glance_api':
    listening_service => 'glance_api_cluster',
    ports             => '9292',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  # Note: Failures were experienced when the balance-member was named Horizon.
  haproxy::listen { 'dashboard_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '80',
    options   => {
      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'balance' => 'source'
    }
  }

  # Note: Failures were experienced when the balance-member was named Horizon.
  haproxy::balancermember { 'dashboard':
    listening_service => 'dashboard_cluster',
    ports             => '80',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'novnc_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '6080',
    options   => {
      'option'  => ['tcpka', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'novnc':
    listening_service => 'novnc_cluster',
    ports             => '6080',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'memcached_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '11211',
    options   => {
      'option'  => ['tcpka', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'memcached':
    listening_service => 'memcached_cluster',
    ports             => '11211',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'neutron_api_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '9696',
    options   => {
      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'neutron_api':
    listening_service => 'neutron_api_cluster',
    ports             => '9696',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'swift_proxy_cluster':
    ipaddress => $swiftproxy_cluster_vip,
    ports     => '8080',
    options   => {
      'option'  => ['tcplog','tcpka'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'swift_proxy':
    listening_service => 'swift_proxy_cluster',
    ports             => '8080',
    server_names      => [$::swiftproxy01_hostname, $::swiftproxy02_hostname],
    ipaddresses       => [$::swiftproxy01_ip, $::swiftproxy02_ip],  
    options           => 'check inter 2000 rise 2 fall 5',
  }
}

node /slb02/ inherits base {

  # Required for supporting a virtual IP address not directly associated to the node.
  sysctl::value { "net.ipv4.ip_nonlocal_bind": value => "1" }

  # Keepalived is used to provide high-availability between HAProxy Nodes.
  # Two instances are created, one for the Controller Cluster VIP and the other for the Swift Proxy VIP.
  # Take note that this node is active for the Swift Proxy VIP.
  class { keepalived: }
  
  keepalived::instance { '50':
    interface         => 'eth0',
    virtual_ips       => "${controller_cluster_vip} dev eth0",
    state             => 'BACKUP',
    priority          => '100',
  }

  # Take note that this node is the backup for the Controller Cluster VIP.
  keepalived::instance { '51':
    interface         => 'eth0',
    virtual_ips       => "${swiftproxy_cluster_vip} dev eth0",
    state             => 'MASTER',
    priority          => '101',
    track_script      => ['haproxy'],
  }

  keepalived::vrrp_script { 'haproxy':
    name_is_process   => true,
  }

  # This class configures all global, default, and server cluster parameters.
  # Note that all haproxy::config definition use the Controller VIP except the swift_proxy_cluster.
  class { 'haproxy': }

  haproxy::listen { 'galera_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '3306',
    options   => {
      'option'  => ['httpchk'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'galera':
    listening_service => 'galera_cluster',
    ports             => '3306',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    # Note: Checking port 9200 due to health_check script.
    options           => 'check port 9200 inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'keystone_public_internal_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '5000',
    options   => {
      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'keystone_public_internal;':
    listening_service => 'keystone_public_internal_cluster',
    ports             => '5000',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'keystone_admin_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '35357',
    options   => {
      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'keystone_admin':
    listening_service => 'keystone_admin_cluster',
    ports             => '35357',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'nova_compute_api1_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '8773',
    # Note: httpchk removed
    options   => {
      'option'  => ['tcpka', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'nova_compute01':
    listening_service => 'nova_compute_api1_cluster',
    ports             => '8773',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'nova_compute_api2_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '8774',
    options   => {
      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'nova_compute02':
    listening_service => 'nova_compute_api2_cluster',
    ports             => '8774',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'nova_compute_api3_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '8775',
    # Note: httpchk removed
    options   => {
      'option'  => ['tcpka', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'nova_compute03':
    listening_service => 'nova_compute_api3_cluster',
    ports             => '8775',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'nova_volume_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '8776',
    options   => {
      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'nova_volume':
    listening_service => 'nova_volume_cluster',
    ports             => '8776',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'glance_registry_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '9191',
    options   => {
      'option'  => ['tcpka', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'glance_registry':
    listening_service => 'glance_registry_cluster',
    ports             => '9191',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'glance_api_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '9292',
    options   => {
      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'glance_api':
    listening_service => 'glance_api_cluster',
    ports             => '9292',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'novnc_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '6080',
    options   => {
      'option'  => ['tcpka', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'novnc':
    listening_service => 'novnc_cluster',
    ports             => '6080',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'memcached_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '11211',
    options   => {
      'option'  => ['tcpka', 'tcplog'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'memcached':
    listening_service => 'memcached_cluster',
    ports             => '11211',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'neutron_api_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '9696',
    options   => {
      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'balance' => 'source'
    } 
  }

  haproxy::balancermember { 'neutron_api':
    listening_service => 'neutron_api_cluster',
    ports             => '9696',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  # Note: Failures were experienced when the balance-member was named Horizon.
  haproxy::listen { 'dashboard_cluster':
    ipaddress => $controller_cluster_vip,
    ports     => '80',
    options   => {
      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'balance' => 'source'
    }
  }

  # Note: Failures were experienced when the balance-member was named Horizon.
  haproxy::balancermember { 'dashboard':
    listening_service => 'dashboard_cluster',
    ports             => '80',
    server_names      => [$::controller01_hostname, $::controller02_hostname, $::controller03_hostname],
    ipaddresses       => [$::controller01_mgt_ip, $::controller02_mgt_ip, $::controller03_mgt_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'swift_proxy_cluster':
    ipaddress => $swiftproxy_cluster_vip,
    ports     => '8080',
    options   => {
      'option'  => ['tcplog','tcpka'],
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'swift_proxy':
    listening_service => 'swift_proxy_cluster',
    ports             => '8080',
    server_names      => [$::swiftproxy01_hostname, $::swiftproxy02_hostname],
    ipaddresses       => [$::swiftproxy01_ip, $::swiftproxy02_ip],
    options           => 'check inter 2000 rise 2 fall 5',
  }

}
