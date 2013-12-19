# This document serves as an example of how to deploy
# a multi-node openstack environment with high-availability.
# This deployment model uses nova-network for networking
# and nova-volume for block storage.

########### Proxy Configuration ##########
# If you use an HTTP/HTTPS proxy, uncomment this setting and specify the correct proxy URL.
# If you do not use an HTTP/HTTPS proxy, leave this setting commented out.
#$proxy             = "http://proxy-server:port-number"

# If you are behind a proxy you may choose not to use our ftp distribution, and
# instead try our http distribution location. Note the http location is not
# a permanent location and may change at any time.
$location          = "ftp://ftpeng.cisco.com/openstack/cisco"

# Alternate, uncomment this one, and coment out the one above
#$location           = "http://192.168.26.163/openstack/cisco"

########### NTP Configuration ############
# Change this to the location of a time server in your organization accessible to the build server
# The build server will synchronize with this time server, and will in turn function as the time
# server for your OpenStack nodes
$ntp_server = "ntp.example.com"

########### Build Node Cobbler Variables ############
# Change these parameters to define the IP address and other network settings of your build node
# The cobbler node *must* have this IP configured and it *must* be on the same network as
# the hosts to install
$cobbler_node_ip    = '192.168.220.254'
$mgt_subnet         = '192.168.220.0'
$mgt_netmask        = '255.255.255.0'

# This gateway is optional - if there's a gateway providing a default route, put it here
# If not, comment it out
$mgt_gateway       = '192.168.220.1'

# This domain name will be the name your build and compute nodes use for the local DNS
# It doesn't have to be the name of your corporate DNS - a local DNS server on the build
# node will serve addresses in this domain - but if it is, you can also add entries for
# the nodes in your corporate DNS iand they will be usable *if* the above addresses 
# are routeable from elsewhere in your network.
$domain_name        = 'example.com'

# This setting likely does not need to be changed
# To speed installation of your OpenStack nodes, it configures your build node to function
# as a caching proxy storing the Ubuntu install files used to deploy the OpenStack nodes
$cobbler_proxy          = "http://${cobbler_node_ip}:3142/"

####### Preseed File Configuration #######
# This will build a preseed file called 'cisco-preseed' in /etc/cobbler/preseeds/
# The preseed file automates the installation of Ubuntu onto the OpenStack nodes
#
# The following variables may be changed by the system admin:
# 1) admin_user
# 2) password_crypted
# Default user is: localadmin 
# Default MD5 crypted password is "ubuntu": $6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1
$admin_user             = 'localadmin'
$password_crypted       = '$6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1'

# Select the drive on which Ubuntu and OpenStack will be installed in each node. Current assumption is
# that all nodes will be installed on the same device name
$install_drive           = '/dev/sdc'

########### OpenStack Variables ############
# These values define parameters which will be used to deploy and configure OpenStack
# once Ubuntu is installed on your nodes

# [$controller_cluster_vip] The virtual IP address used for your Controller Cluster.
$controller_cluster_vip        = '192.168.220.40'

# The Virtual Hostname of the Controller Cluster
$controller_vip_hostname       = 'control'

# The actual address and hostname of the primary controller
$controller01_mgt_ip           = '192.168.220.41'
$controller01_hostname         = 'control01'

# The actual address and hostname of the secondary controller
$controller02_mgt_ip           = '192.168.220.42'
$controller02_hostname         = 'control02'

# The actual address and hostname of the tertiary controller
$controller03_mgt_ip           = '192.168.220.43'
$controller03_hostname         = 'control03'

# The Virtual Swift Proxy Hostname and IP address
$swiftproxy_vip_hostname       = 'swiftproxy'
$swiftproxy_cluster_vip        = '192.168.220.60'

# The actual address and hostname of the primary swift proxy
$swiftproxy01_ip               = '192.168.220.61'
$swiftproxy01_hostname         = 'swiftproxy01'

# The actual address and hostname of the secondary swift proxy
$swiftproxy02_ip               = '192.168.220.62'
$swiftproxy02_hostname         = 'swiftproxy02'

# RabbitMQ Cluster Configuration. It is not necessary to change this information.
$cluster_rabbit       	       = true
$cluster_disk_nodes            = [$controller01_hostname, $controller02_hostname, $controller03_hostname]

# Memcached Settings used for Nova Consoleauth. It is not necessary to change this information.
$memcached_servers             = [$controller01_mgt_ip, $controller02_mgt_ip, $controller03_mgt_ip]

# These next three parameters specify the networking hardware used in each node
# Current assumption is that all nodes have the same network interfaces and are
# cabled identically
#
# Specify which interface is used as the public interface. 
# This interface is used by nova-network for the public network.  
# This interface is used by OpenStack for API endpoints and for node management.
$public_interface        = 'eth0'

# Define the interface used for vm networking connectivity when nova-network is being used.
$private_interface       = 'eth0.221'

# Specify the interface used between Swift Proxy and Storage Nodes.
$storage_interface       = 'eth0.222'

# Nova networking parameters.  The floating_ip_range should 
# correspond to your $public_interface definition.
$fixed_network_range     = '10.0.0.0/24'
$floating_ip_range       = '192.168.220.96/27'
$auto_assign_floating_ip = true

####### shared variables ##################
# This section is used to specify global variables that will
# be used across OpenStack nodes.

# IP Address of the Keystone Authentication service
$keystone_host		 = $controller_cluster_vip
# credentials
$admin_email             = 'root@localhost'
$admin_password          = 'keystone_admin'
$galera_monitor_password = 'galera_pass'
$wsrep_sst_password	 = 'wsrep_password'
$keystone_db_password    = 'keystone_db_pass'
$keystone_admin_token    = 'keystone_admin_token'
$nova_db_password        = 'nova_pass'
$nova_user_password      = 'nova_pass'
$glance_db_password      = 'glance_pass'
$glance_user_password    = 'glance_pass'
$neutron_user_password   = 'neutron_pass'
$neutron_db_password     = 'neutron_pass'
$rabbit_password         = 'openstack_rabbit_password'
$rabbit_user             = 'openstack_rabbit_user'
$horizon_secret_key      = 'horizon_secret_key'
# switch the following value to true to have all service log at verbose
$verbose                 = false
#### end shared variables #################

# This describes the hardware of the nodes to the extent required to network-install their
# OS.
define cobbler_node($node_type, $mac, $ip, $power_address, $power_id = undef, $preseed) {
  cobbler::node { $name:
    mac            => $mac,
    ip             => $ip,
    ### UCS CIMC Details ###
    # Change these parameters to match the management console settings for your server
    power_address  => $power_address,
    power_user     => "admin",
    power_password => "password",
    power_type     => "ipmitool",
    #power_id       => $power_id,
    ### Advanced Users Configuration ###
    # These parameters typically should not be changed
    profile        => "precise-x86_64-auto",
    domain         => $::domain_name,
    node_type      => $node_type,
    preseed        => $preseed,
  }
}

# Change build-os to the hostname of your build node.
node build-os inherits build-node {

# This block defines the nodes that Cobbler will manage. Replace the name definitions, i.e."control01" 
# with the host name of your OpenStack nodes. Change the mac to the MAC address of the boot interface of your
# OpenStack node. The power_address corresponds to the interface used for server administration.  
# For Cisco UCS, this is the CIMC interface. Change the ip to the IP address of your OpenStack node.

  cobbler_node { "control01":
    node_type      => "control",
    mac            => "A4:4C:11:13:8B:D2",
    ip             => $controller01_mgt_ip,
    power_address  => "192.168.220.2",
    preseed        => "cisco-preseed",
  }

  cobbler_node { "control02":
    node_type      => "control",
    mac            => "A4:4C:11:13:8B:1A",
    ip             => $controller02_mgt_ip,
    power_address  => "192.168.220.3",
    preseed        => "cisco-preseed",
  }

  cobbler_node { "control03":
    node_type      => "control",
    mac            => "A4:4C:11:13:5E:5",
    ip             => $controller03_mgt_ip,
    power_address  => "192.168.220.13",
    preseed        => "cisco-preseed",
  }

# Begin Compute Nodes
  cobbler_node { "compute01":
    node_type      => "compute",
    mac            => "A4:4C:11:13:52:80",
    ip             => "192.168.220.51",
    power_address  => "192.168.220.4",
    preseed        => "cisco-preseed",
  }

# Begin Load-Balancer Nodes
  cobbler_node { "slb01":
    node_type      => "load-balancer",
    mac            => "A4:4C:11:13:A7:F1",
    ip             => "192.168.220.52",
    power_address  => "192.168.220.5",
    preseed        => "cisco-preseed",
  }

  cobbler_node { "slb02":
    node_type      => "load-balancer",
    mac            => "A4:4C:11:13:43:DB",
    ip             => "192.168.220.53",
    power_address  => "192.168.220.6",
    preseed        => "cisco-preseed",
  }

# Begin Swift Proxy Nodes
  cobbler_node { "swiftproxy01":
    node_type      => "swift-proxy",
    mac            => "A4:4C:11:13:3D:07",
    ip             => "192.168.220.61",
    power_address  => "192.168.220.7",
    preseed        => "cisco-preseed",
  }

  cobbler_node { "swiftproxy02":
    node_type      => "swift-proxy",
    mac            => "A4:4C:11:13:44:93",
    ip             => "192.168.220.62",
    power_address  => "192.168.220.8",
    preseed        => "cisco-preseed",
  }

# Begin Swift Storage Nodes
  cobbler_node { "swift01":
    node_type      => "swift-storage",
    mac            => "A4:4C:11:13:BA:1",
    ip             => "192.168.220.71",
    power_address  => "192.168.220.10",
    preseed        => "cisco-preseed",
  }

  cobbler_node { "swift02":
    node_type      => "swift-storage",
    mac            => "A4:4C:11:13:BC:56",
    ip             => "192.168.220.72",
    power_address  => "192.168.220.11",
    preseed        => "cisco-preseed",
  }

  cobbler_node { "swift03":
    node_type      => "swift-storage",
    mac            => "A4:4C:11:13:B9:8D",
    ip             => "192.168.220.73",
    power_address  => "192.168.220.12",
    preseed        => "cisco-preseed",
  }
}

# Change control01 to the hostname of your 1st Control Node in the Controller Cluster
node control01 inherits os_base { 

  class { 'controller':
    # Addressing and interface information
    public_address          => $controller01_mgt_ip,
    internal_address        => $controller01_mgt_ip,
    admin_address           => $controller01_mgt_ip,
    # ***VERY IMPORTANT*** galera_master_ip should be set to false 
    # when the node is the 1st to join the Galera cluster.
    # When the Galera cluster is functioning, change from false to 
    # the IP of Controller2 or Controller3.
    galera_master_ip        => false,
    #galera_master_ip        => $controller02_mgt_ip,
  }

   # Create Swift auth in Keystone.  Only needed on 1 Controller in HA deployment.
  class { 'swift::keystone::auth':
    tenant    => $swift_auth_tenant,
    auth_name => $swift_auth_user,
    password  => $swift_auth_password,
    address   => $swiftproxy_cluster_vip,
  }
}

# Change control02 to the hostname of your 2nd Control Node in the Controller Cluster
node control02 inherits os_base { 

  class { 'controller':
    # Addressing and interface information
    public_address          => $controller02_mgt_ip,
    internal_address        => $controller02_mgt_ip,
    admin_address           => $controller02_mgt_ip,
    # galera_master_ip should be set to false when node is the 1st to join the Galera cluster.
    # Since this Controller 2 is the 2nd Controller Node, we will set the master to the IP of Controller 1.
    galera_master_ip        => $controller01_mgt_ip,
  }
}

# Change control03 to the hostname of your 3rd Control Node in the Controller Cluster
node control03 inherits os_base { 

  class { 'controller':
    # Addressing and interface information
    public_address          => $controller03_mgt_ip,
    internal_address        => $controller03_mgt_ip,
    admin_address           => $controller03_mgt_ip,
    # galera_master_ip should be set to false when node is the 1st to join the Galera cluster.
    # Since this Controller 3 is the 3rd Controller Node, we will set the master to the IP of Controller 2.
    galera_master_ip        => $controller02_mgt_ip,
  }
}

# Begin Compute Node definitions.  Repeat the compute node block 
# for additional Compute Nodes. Remember the node name should match
# the cobbler_node section definitions.
node compute01 inherits os_base {

  class { 'compute':}
}

########################################################################
### All parameters below this point likely do not need to be changed ###
########################################################################

### Advanced Users Configuration ###
# These four settings typically do not need to be changed
# In the default deployment, the build node functions as the DNS and static DHCP server for
# the OpenStack nodes. These settings can be used if alternate configurations are needed
$build_node_name = $::hostname
$node_dns        = "${cobbler_node_ip}"
$ip              = "${cobbler_node_ip}"
$dns_service     = "dnsmasq"
$dhcp_service    = "dnsmasq"

### Puppet Parameters ###
# These settings load other puppet components. They should not be changed
import 'cobbler-node'
import 'core'
import 'swift-nodes'
import 'haproxy-nodes'

## Define the default node, to capture any un-defined nodes that register
## Simplifies debug when necessary.

node default {
  notify{"Default Node: Perhaps add a node definition to site.pp": }
}
