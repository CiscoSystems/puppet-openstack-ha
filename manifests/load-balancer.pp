# Introduction
# Class used to manage server load-balancers in a
# high-availability OpenStack deployment.
#
# Module Dependencies
#  puppet-sysctl
#  puppet-keepalived
#  puppet-haproxy
#
# Example Usage
# node 'slb01' {
#   class {'openstack-ha::load-balancer':
#     controller_virtual_ip   => '10.10.10.10',
#     swift_proxy_virtual_ip  => '11.11.11.11',
#     keepalived_interface    => 'eth0',
#     controller_state        => 'MASTER',
#     swift_proxy_state       => 'BACKUP',
#     controller_names        => ['control01, control02, control03'],
#     controller_ipaddresses  => ['1.1.1.1, 2.2.2.2, 3.3.3.3'],
#     swift_proxy_names       => ['swift01, swift02'],
#     swift_proxy_ipaddresses => ['4.4.4.4, 5.5.5.5'],
#   }
# }
#
class openstack-ha::load-balancer(
  $controller_virtual_ip,
  $swift_proxy_virtual_ip,
  $controller_state,
  $swift_proxy_state,
  $controller_names,
  $controller_ipaddresses,
  $swift_proxy_names,
  $swift_proxy_ipaddresses,
  $keepalived_interface     = 'eth0',
  $track_script             = 'haproxy'
) {

  include keepalived
#  include haproxy

  if ($controller_state == 'MASTER') {
    $controller_priority = '101'
  } else {
    $controller_priority = '100'
  }

  if ($swift_proxy_state == 'MASTER') {
    $swift_proxy_priority = '101'
  } else {
    $swift_proxy_priority = '100'
  }

  sysctl::value { "net.ipv4.ip_nonlocal_bind": value => "1" }

  keepalived::instance { '50':
    interface    => $keepalived_interface,
    virtual_ips  => "${controller_virtual_ip} dev ${keepalived_interface}",
    state        => $controller_state,
    priority     => $controller_priority,
    track_script => [$track_script],
  }

  keepalived::instance { '51':
    interface    => $keepalived_interface,
    virtual_ips  => "${swift_proxy_virtual_ip} dev ${keepalived_interface}",
    state        => $swift_proxy_state,
    priority     => $swift_proxy_priority,
    track_script => [$track_script],
  }

  keepalived::vrrp_script { 'haproxy':
    name_is_process   => true,
  }

  class { 'haproxy':
    defaults_options => {
      'log'     => 'global',
      'option'  => 'redispatch',
      'retries' => '3',
      'timeout' => [
        'http-request 10s',
        'queue 1m',
        'connect 10s',
        'client 1m',
        'server 1m',
        'check 10s',
      ],
      'maxconn' => '8000'
    }
  }

  haproxy::listen { 'galera_cluster':
    ipaddress => $controller_virtual_ip,
    ports     => '3306',
    options   => {
      'option'  => ['httpchk'],
      'mode'    => 'tcp',
#      'balance' => 'roundrobin'
#      'balance' => 'leastconn'
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'galera':
    listening_service => 'galera_cluster',
    ports             => '3306',
    server_names      => $controller_names,
    ipaddresses       => $controller_ipaddresses,
    # Note: Checking port 9200 due to health_check script.
    options           => 'check port 9200 inter 2000 rise 2 fall 5',
  }

#  haproxy::listen { 'rabbit_cluster':
#    ipaddress => $controller_virtual_ip,
#    ports     => '5672',
#    options   => {
#      'option'  => ['tcpka', 'tcplog'],
#      'mode'    => 'tcp',
#      'balance' => 'roundrobin'
#    }
#  }

#  haproxy::balancermember { 'rabbit;':
#    listening_service => 'rabbit_cluster',
#    ports             => '5672',
#    server_names      => $controller_names,
#    ipaddresses       => $controller_ipaddresses,
#    options           => 'check inter 2000 rise 2 fall 5',
#  }

  haproxy::listen { 'keystone_public_internal_cluster':
    ipaddress => $controller_virtual_ip,
    ports     => '5000',
    options   => {
#      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'option'  => ['httpchk'],
      'mode'    => 'http',
#      'mode'    => 'tcp',
      'cookie'  => 'SERVERID rewrite',
      'balance' => 'roundrobin'
#      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'keystone_public_internal':
    listening_service => 'keystone_public_internal_cluster',
    ports             => '5000',
    server_names      => $controller_names,
    ipaddresses       => $controller_ipaddresses,
    options           => 'check inter 2000 rise 2 fall 5',
    define_cookies    => true
  }

  haproxy::listen { 'keystone_admin_cluster':
    ipaddress => $controller_virtual_ip,
    ports     => '35357',
    options   => {
#      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'option'  => ['httpchk'],
      'mode'    => 'http',
#      'mode'    => 'tcp',
      'cookie'  => 'SERVERID rewrite',
      'balance' => 'roundrobin'
#      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'keystone_admin':
    listening_service => 'keystone_admin_cluster',
    ports             => '35357',
    server_names      => $controller_names,
    ipaddresses       => $controller_ipaddresses,
    options           => 'check inter 2000 rise 2 fall 5',
    define_cookies    => true
  }

  haproxy::listen { 'nova_ec2_api_cluster':
    ipaddress => $controller_virtual_ip,
    ports     => '8773',
    options   => {
#      'option'  => ['tcpka', 'httpchk GET /services/Cloud', 'tcplog'],
      'option'  => ['forwardfor'],
      'mode'    => 'http',
      'cookie'  => 'SERVERID rewrite',
      'balance' => 'roundrobin'
    }
  }

  haproxy::balancermember { 'nova_ec2':
    listening_service => 'nova_ec2_api_cluster',
    ports             => '8773',
    server_names      => $controller_names,
    ipaddresses       => $controller_ipaddresses,
    options           => 'check inter 2000 rise 2 fall 5',
    define_cookies    => true
  }

  haproxy::listen { 'nova_osapi_cluster':
    ipaddress => $controller_virtual_ip,
    ports     => '8774',
    options   => {
#      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'option'  => ['forwardfor'],
      'mode'    => 'http',
      'cookie'  => 'SERVERID rewrite',
      'balance' => 'roundrobin'
    }
  }

  haproxy::balancermember { 'nova_osapi':
    listening_service => 'nova_osapi_cluster',
    ports             => '8774',
    server_names      => $controller_names,
    ipaddresses       => $controller_ipaddresses,
    options           => 'check inter 2000 rise 2 fall 5',
    define_cookies    => true
  }

  haproxy::listen { 'nova_metadata_api_cluster':
    ipaddress => $controller_virtual_ip,
    ports     => '8775',
    options   => {
#      'option'  => ['tcpka', 'tcplog'],
      'option'  => ['forwardfor'],
#      'mode'    => 'tcp',
      'mode'    => 'http',
      'cookie'  => 'SERVERID rewrite',
      'balance' => 'roundrobin'
    }
  }

  haproxy::balancermember { 'nova_metadata':
    listening_service => 'nova_metadata_api_cluster',
    ports             => '8775',
    server_names      => $controller_names,
    ipaddresses       => $controller_ipaddresses,
    options           => 'check inter 2000 rise 2 fall 5',
    define_cookies    => true
  }

  haproxy::listen { 'quantum_api_cluster':
    ipaddress => $controller_virtual_ip,
    ports     => '9696',
    options   => {
#      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'option'  => ['forwardfor', 'httpchk',],
      'mode'    => 'http',
      'cookie'  => 'SERVERID rewrite',
      'balance' => 'roundrobin'
    }
  }

  haproxy::balancermember { 'quantum_api':
    listening_service => 'quantum_api_cluster',
    ports             => '9696',
    server_names      => $controller_names,
    ipaddresses       => $controller_ipaddresses,
    options           => 'check inter 2000 rise 2 fall 5',
    define_cookies    => true
  }

  haproxy::listen { 'cinder_api_cluster':
    ipaddress => $controller_virtual_ip,
    ports     => '8776',
    options   => {
#      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'option'  => ['forwardfor', 'httpchk'],
      'mode'    => 'http',
      'cookie'  => 'SERVERID rewrite',
      'balance' => 'roundrobin'
    }
  }

  haproxy::balancermember { 'cinder_api':
    listening_service => 'cinder_api_cluster',
    ports             => '8776',
    server_names      => $controller_names,
    ipaddresses       => $controller_ipaddresses,
    options           => 'check inter 2000 rise 2 fall 5',
    define_cookies    => true
  }

  haproxy::listen { 'glance_registry_cluster':
    ipaddress => $controller_virtual_ip,
    ports     => '9191',
    options   => {
      'mode'    => 'http',
      'cookie'  => 'SERVERID rewrite',
      'balance' => 'roundrobin'
    }
  }

  haproxy::balancermember { 'glance_registry':
    listening_service => 'glance_registry_cluster',
    ports             => '9191',
    server_names      => $controller_names,
    ipaddresses       => $controller_ipaddresses,
    options           => 'check inter 2000 rise 2 fall 5',
    define_cookies    => true
  }

  haproxy::listen { 'glance_api_cluster':
    ipaddress => $controller_virtual_ip,
    ports     => '9292',
    options   => {
      'option'  => ['tcpka', 'httpchk', 'tcplog'],
#      'option'  => ['httpchk'],
#      'mode'    => 'http',
      'mode'    => 'tcp',
#      'cookie'  => 'SERVERID rewrite',
#      'balance' => 'roundrobin'
      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'glance_api':
    listening_service => 'glance_api_cluster',
    ports             => '9292',
    server_names      => $controller_names,
    ipaddresses       => $controller_ipaddresses,
    options           => 'check inter 2000 rise 2 fall 5',
#    define_cookies    => true
  }

  # Note: Failures were experienced when the balance-member was named Horizon.
  haproxy::listen { 'dashboard_cluster':
    ipaddress => $controller_virtual_ip,
    ports     => '80',
    options   => {
#      'option'  => ['tcpka', 'httpchk', 'tcplog'],
      'option'  => ['forwardfor', 'httpchk', 'httpclose'],
      'mode'    => 'http',
      'cookie'  => 'SERVERID insert indirect nocache',
      'capture' => 'cookie vgnvisitor= len 32',
      'balance' => 'roundrobin',
      'rspidel' => '^Set-cookie:\ IP='
    }
  }

  # Note: Failures were experienced when the balance-member was named Horizon.
  haproxy::balancermember { 'dashboard':
    listening_service => 'dashboard_cluster',
    ports             => '80',
    server_names      => $controller_names,
    ipaddresses       => $controller_ipaddresses,
    options           => 'check inter 2000 rise 2 fall 5',
    define_cookies    => true
  }

  # Uncomment if using NoVNC
  haproxy::listen { 'novnc_cluster':
    ipaddress => $controller_virtual_ip,
    ports     => '6080',
    options   => {
      'option'  => ['tcpka', 'tcplog'],
      'mode'    => 'tcp',
      'balance' => 'roundrobin'
    }
  }

  # Uncomment if using NoVNC
  haproxy::balancermember { 'novnc':
    listening_service => 'novnc_cluster',
    ports             => '6080',
    server_names      => $controller_names,
    ipaddresses       => $controller_ipaddresses,
    options           => 'check inter 2000 rise 2 fall 5',
  }

  # Uncomment if using Spice
#  haproxy::listen { 'spice_cluster':
#    ipaddress => $controller_virtual_ip,
#    ports     => '6082',
#    options   => {
#      'option'  => ['tcpka', 'tcplog'],
#      'balance' => 'source'
#    }
#  }

  # Uncomment if using Spice
#  haproxy::balancermember { 'spice':
#    listening_service => 'spice_cluster',
#    ports             => '6082',
#    server_names      => $controller_names,
#    ipaddresses       => $controller_ipaddresses,
#    options           => 'check inter 2000 rise 2 fall 5',
#  }

  haproxy::listen { 'nova_memcached_cluster':
    ipaddress => $controller_virtual_ip,
    ports     => '11211',
    options   => {
      'option'  => ['tcpka', 'tcplog'],
      'mode'    => 'tcp',
      'balance' => 'roundrobin'
    }
  }

  haproxy::balancermember { 'nova_memcached':
    listening_service => 'nova_memcached_cluster',
    ports             => '11211',
    server_names      => $controller_names,
    ipaddresses       => $controller_ipaddresses,
    options           => 'check inter 2000 rise 2 fall 5',
  }

  haproxy::listen { 'swift_proxy_cluster':
    ipaddress => $swift_proxy_virtual_ip,
    ports     => '8080',
    options   => {
      'option'  => ['httpchk GET /healthcheck'],
      'mode'    => 'http',
#      'mode'    => 'tcp',
      'cookie'  => 'SERVERID rewrite',
      'balance' => 'roundrobin'
#      'balance' => 'source'
    }
  }

  haproxy::balancermember { 'swift_proxy':
    listening_service => 'swift_proxy_cluster',
    ports             => '8080',
    server_names      => $swift_proxy_names,
    ipaddresses       => $swift_proxy_ipaddresses,
    options           => 'check inter 2000 rise 2 fall 5',
    define_cookies    => true
  }

  haproxy::listen { 'swift_memcached_cluster':
    ipaddress => $swift_proxy_virtual_ip,
    ports     => '11211',
    options   => {
      'option'  => ['tcpka', 'tcplog'],
      'mode'    => 'tcp',
      'balance' => 'roundrobin'
    }
  }

  haproxy::balancermember { 'swift_memcached':
    listening_service => 'swift_memcached_cluster',
    ports             => '11211',
    server_names      => $swift_proxy_names,
    ipaddresses       => $swift_proxy_ipaddresses,
    options           => 'check inter 2000 rise 2 fall 5',
  }
}
