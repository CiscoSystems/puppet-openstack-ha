# The OpenStack High Availability Module:

## Introduction

This software is provided as-is with no warranty.  Please use at your own discretion.

The Openstack High Availability (HA) Puppet Modules are a flexible Puppet implementation capable of
configuring [OpenStack](http://docs.openstack.org/) and additional services for
providing high-availability mechanisms. A ['Puppet Module'](http://docs.puppetlabs.com/learning/modules1.html#modules)
is a collection of related content that can be used to model the configuration of a discrete service.

The OpenStack HA solution provides active/active redundancy for Controller Nodes, Compute Nodes, 
Swift Proxy Nodes and Load-Balancer Nodes. Compute Nodes employ 
the well-known [multi-host](http://docs.openstack.org/trunk/openstack-compute/admin/content/existing-ha-networking-options.html#d6e7351) HA networking option to eliminate a nova-network single point of failure.  

The module currently supports the OpenStack Folsom release:

  * [Nova](http://nova.openstack.org/)     (Compute Service)
  * [Glance](http://glance.openstack.org/)   (Image Service)
  * [Swift](http://swift.openstack.org/)    (Object Storage Service)
  * [Keystone](http://keystone.openstack.org/) (Authentication Service)
  * [Horizon](http://horizon.openstack.org/)  (OpenStack Dashboard Web User Interface)

These modules are based on the administrative guides for OpenStack
[Compute](http://docs.openstack.org/folsom/openstack-compute/admin/content/) and
[Object Store](http://docs.openstack.org/folsom/openstack-object-storage/admin/content/)

## Dependencies:

### Puppet:

  * [Puppet](http://docs.puppetlabs.com/puppet/) 2.7.11 or greater
  * [Facter](http://www.puppetlabs.com/puppet/related-projects/facter/) 1.6.5 or
    greater (versions that support the osfamily fact)

### Operating System Platforms:

  These modules have been fully tested on Ubuntu 12.04 LTS (Precise).

### Networking:

  Each of the servers running OpenStack services should have a minimum of 2
  networks, and preferably 3 networks.  The networks can be physically or virtually (VLAN) separated.
  In addition to the 2 OpenStack networks, it is recommended to have an ILO/CIMC network to fully leverage
  the remote management capabilities of the [Cobbler Module](https://github.com/CiscoSystems/puppet-cobbler).
  Additionally, [puppet-networking](https://github.com/CiscoSystems/puppet-network) models OpenStack network configurations.  
  
  The following provides a brief explanation of the OpenStack Module networking requirements.

  * OpenStack Management Network
      - This network is used to perform management functions against the node, Puppet Master <> Agent is an example.
      - An IP address for each node is required for this network.
      - This network typically employs private (RFC 1918) IP addressing.
  * Nova Public/API Network
      - This network is used for assigning Floating IP addresses to instances, 
        for communicating outside of the OpenStack cloud, etc..
      - An IP address for the node is required for this network.
      - (Optional) This network can be collapsed with the OpenStack Management Network.
      - This network typically employs publicly routable IP addressing.
  * Instance Network
      - This network is used for providing connectivity to OpenStack Instances using either the Flat or VLAN Nova Networking Manager.
      - An IP address for the node is not necessary, as Nova automatically creates a bridge interface with an IP address.
      - This network typically employs private (RFC 1918) IP addressing.

### Storage Volumes:

  Every Compute Node is configured to host the nova-volume service to provide persistent storage to instances through iSCSI.  
  The volume-group name is 'nova-volumes' and should not be changed.

### Node Types:

  The OpenStack HA solution consists of 5 Nodes Types:

  * Load Balancer Node
       - Quantity- 2
       - Runs HAProxy and Keeplived. 
       - Provides monitoring and fail-over for API endpoints and between load-balancer nodes.  
  * Controller Node
       - Quantity- 3
       - Runs MySQL Galera, Keystone, Glance, Nova, Horizon, and RabbitMQ.
       - Provides control plane functionality for managing the OpenStack Nova environment.  
  * Compute Node
       - Quantity- 1 (recommend having 2 for demonstrating nova-scheduler across multiple nodes)
       - Runs the following Nova services: api, compute, network, and volume.
       - Provides necessary infrastructure services to Nova Instances.  
  * Swift Proxy Node
       - Quantity- 2
       - Runs swift-proxy, memcached, and keystone-client.
       - Authenticates users against Keystone and acts as a translation layer between clients and storage.  
  * Swift Storage Node
       - Quantity- 3
       - Runs Swift account/container/object services.  XFS is used as the filesystem.
       - Controls storage of the account databases, container databases, and the stored objects.

## Installation

### Installation Order

  The OpenStack Nodes are required to be deployed in a very specific order. 
  The following is the order in which the nodes should be deployed.
  Preface commands with **sudo** if you are not the root user:
	
 * **HAproxy Nodes**: Make sure the haproxy/keepalived services are running.
	
 * **Swift Storage Nodes**: The drives should be zero'ed out if you are rebuilding 
	  the swift storage nodes. Use clean-disk.pp from the Cisco repo or
	  use the following command:

          for i in  b c d e f <add/subtract drive letters as needed>
          do
          dd bs=1M count=1000 if=/dev/zero of=/dev/sd$i
          done
	
 * **Swift Proxy Node #1**: Make sure the ring is functional before adding the 2nd Proxy.

 * **Swift Proxy Node 2**: Make sure the ring is functional before proceeding.
	
 * **Controller Nodes 1-3**: You must ensure that the HAproxy Virtual IP address 
   for the Controller cluster is working or your puppet deployment will fail.
	
 * **Compute Nodes**: Start off with just 1 or 2 nodes before deploying a large number.
	
 * Test to make sure environment is functional.

### Install the Build Node

  A Build Node (Puppet Master, Cobbler, etc.) is required for deploying the OpenStack HA environment. Follow the 
  [Cisco Build Node Deployment Guide](http://www.cisco.com/go/openstack) for step-by-step instructions of this process.

  * In addition to the steps identified in the Cisco Build Node Deployment Guide,
    Rake and Git should also be installed on the Puppet Master:

      `apt-get install rake git`

### Install the Openstack HA Modules

  The Openstack HA modules should be installed into the module path of your Build Node.

  Modulepath:

  - Cisco Edition - /etc/puppet/modules

  * Install the latest version of the modules from git:

        cd <module_path>
        git clone -b folsom_ha git://github.com/CiscoSystems/puppet-openstack-ha.git openstack-ha
        cd openstack-ha
        rake modules:clone

  * Copy the example OpenStack HA manifests to your manifests directory:

    	cp <module_path>/openstack-ha/examples/site.pp /etc/puppet/manifests/site.pp
        cp <module_path>/openstack-ha/examples/core.pp /etc/puppet/manifests/core.pp
    	cp <module_path>/openstack-ha/examples/haproxy-nodes.pp /etc/puppet/manifests/haproxy-nodes.pp
    	cp <module_path>/openstack-ha/examples/cobbler-node.pp /etc/puppet/manifests/cobbler-node.pp
    	cp <module_path>/openstack-ha/examples/swift-nodes.pp /etc/puppet/manifests/swift-nodes.pp

  * Edit the manifests according to your deployment needs. At a minimum, the following should be changed:

	 - IP addressing
	 - Node name definitions
	 - DNS naming
	 - user/password information
	 - (Optional) interface definitions
	 - (Optional) additional Compute Node and Swift Storage Node definitions
	 - (Optional) additional Swift Storage Node hard drive definitions  

  * The proceeding sections will detail the example manifests and configuration options.

## Overview of Key Modules

###[puppet-openstack-ha module](https://github.com/CiscoSystems/puppet-openstack-ha)

 The 'puppet-openstack-ha' module was written for users interested in deploying
 and managing a production-grade, highly-available OpenStack deployment.
 It provides a simple and flexible means of deploying OpenStack, and is based on
 best practices shaped by companies that contributed to the design of these modules.

###[puppet-openstack module](https://github.com/CiscoSystems/puppet-openstack)

 The 'puppet-openstack' module was written as a wrapper for individual OpenStack
 modules. 

###[puppet-cobbler module](https://github.com/CiscoSystems/puppet-cobbler)

 The 'puppet-cobbler' module is used to provide several key tasks such as, 
 bare-metal OS provisioning, ILO management of servers, etc..

###[puppet-swift module](https://github.com/CiscoSystems/puppet-swift)

 The 'puppet-swift' module manages all configuration aspects of Swift Proxy
 and Swift Storage Nodes.  The module relies on underlying technologies/modules
 to deliver object storage functionality to your OpenStack environment.

###[puppet-haproxy module](https://github.com/CiscoSystems/puppet-haproxy)

 The 'puppet-haproxy' module provides load-balancing services for API endpoints.

## Overview of Example Manifests

###[cobbler-node manifest](https://github.com/CiscoSystems/puppet-openstack-ha/tree/folsom_ha/examples/cobbler-node.pp)

  For more information on the parameters, check out the inline documentation in the manifest:

    module_path/cobbler/manifests/init.pp

###[site manifest](https://github.com/CiscoSystems/puppet-openstack-ha/tree/folsom_ha/examples/site.pp)

  The site manifest provides the top-level configuration interface
  to the OpenStack HA environment.  I will outline the example manifest 
  so users can customize it as needed.  
  
  For more information on the parameters, check out the inline documentation in
  the manifest:

###[core manifest](https://github.com/CiscoSystems/puppet-openstack-ha/tree/folsom_ha/examples/core.pp)

  The core manifest provides parameters that can be hidden from users.  It extracts common configuration
  paramsters from the site manifest.

###[swift-nodes manifest](https://github.com/CiscoSystems/puppet-openstack-ha/tree/folsom_ha/examples/swift-nodes.pp)

  The site manifest provides the configuration interface for Swift nodes.  The configuration is seperated
  to provide users flexability in deploying Nova without Swift.

###[haproxy-nodes manifest](https://github.com/CiscoSystems/puppet-openstack-ha/tree/folsom_ha/examples/haproxy-nodes.pp)

  The site manifest provides the top-level configuration interface for HAproxy nodes that load-balance
  API requests and SQL DB calls to Controllers and Swift Proxies.


###Customizing Manifests

So far, classes have been discussed as configuration interfaces used to deploy
the OpenStack roles. This section explains how to apply these roles to actual
nodes using a puppet site manifest.

The default file name for the site manifest is site.pp. This file should be
contained in the puppetmaster's (aka Build Node) manifest directory:

* Cisco Edition- /etc/puppet/manifests/site.pp

Node blocks are used to map a node's certificate name to the classes
that should be assigned to it.

[Node blocks](http://docs.puppetlabs.com/guides/language_guide.html#nodes)
can match specific hosts:

        node my_explicit_host {...}

Or they can use regular expression to match sets of hosts

        node /my_similar_hosts/ {...}

Inside the site.pp file, Puppet resources declared within node blocks are
applied to those specified nodes. Resources specified at top-scope are applied
to all nodes.

## Configuring HAProxy Load-Balancers

The servers that act as your load-balancers should be managed by Cobbler.  
Make sure you your site manifest is properly configured and you have added
node definitions for your two load-balancers nodes. Edit the node definitions 
in /etc/puppet/manifests/haproxy-nodes.pp and /etc/puppet/manifests/site.pp. 

## Deploying Swift

The servers that act as your Swift Proxies and Storage Nodes should be managed by Cobbler.  
Make sure you your site manifest is properly configured and you have added
node definitions for your Swift Nodes.  Edit the node definitions and network settings 
in /etc/puppet/manifests/swift-nodes.pp.  Replace existing node definitions 
with the hostname/certname of your Swift Storage and Proxy Nodes.

**Note:** Do not define the 2nd Swift Proxy until the storage Nodes and first proxy 
are deployed and the ring is established.  Also, add additional Storage Node definitions as needed.
		
**Note:** You must use at least 3 Storage Nodes to create a Swift ring.  

To fully configure a Swift environment, the nodes must be configured in the
following order:

* First the storage nodes need to be configured. This creates the storage
  services (object, container, account) and exports all of the storage endpoints
  for the ring builder into storeconfigs. (The replicator service fails to start
  in this initial configuration)
* Next, the ringbuild and Swift Proxy 1 must be configured. The ringbuilder needs
  to collect the storage endpoints and create the ring database before the proxy
  can be installed. It also sets up an rsync server which is used to host the
  ring database.  Resources are exported that are used to rsync the ring
  database from this server.
* Next, the storage nodes should be run again so that they can rsync the ring
  databases.
* Next, [verify Swift](http://docs.openstack.org/folsom/openstack-compute/install/apt/content/verify-swift-installation.html) is operating properly.
* Lastly, add the 2nd Proxy Node.

The [example configuration](https://github.com/CiscoSystems/puppet-openstack-ha/blob/folsom_ha/examples/swift-nodes.pp)
creates five storage devices on every node.  Make sure to increase/decrease the following swift-nodes.pp definitions 
based on the number of hard disks in your Storage Nodes:

          swift::storage::disk
          @@ring_object_device
          @@ring_container_device
          @@ring_account_device
	
Better examples of this will be provided in a future version of the module.

### Deploying an Openstack HA Environment

The servers that act as your Nova Controllers and Compute Nodes should be managed by Cobbler.  
Make sure you your cobbler-node manifest is properly configured and you have added
node definitions for your Controller and Compute Nodes. Edit the node definitions and 
network settings in /etc/puppet/manifests/site.pp. Replace control01, control02, control03, 
and compute01 with the hostname/certname of your Controller/Compute Nodes.

Note: Add additional Compute Node definitions as needed.

Keep in mind that the deployment ***MUST*** be performed in a very specific order (outlined above).
You can either make all the necessary changes to your site manifests and keep particular nodes powered-off.  
Or, you can for building out an OpenStack HA deployment scenario is to choose the IP addresses of the controller node.

After all the nodes have been configured, run puppet apply on your PuppetMaster.  IF the puppet run succeeeds,
start the deployment of the nodes in the specific order outlined above.  You can use the clean-node script or
cobbler system poweron commands from the PuppetMaster for this purpose.

## Verifying an OpenStack deployment

Once you have installed openstack using Puppet (and assuming you experience no
errors), the next step is to verify the installation:

### openstack::auth_file

The optionstack::auth_file class creates the file:

        /root/openrc

which stores environment variables that can be used for authentication of
openstack command line utilities.

* Usage Example:

        class { 'openstack::auth_file':
          admin_password       => 'my_admin_password',
          controller_node      => 'my_controller_node',
          keystone_admin_token => 'my_admin_token',
        }


### Verification Process

1. Verify your authentication information. Note: This assumes that the class openstack::auth_file 
   had been applied to the node you are on.
     
        cat /root/openrc
  
2. Ensure that your authentication information is in the user's environment.

        source /root/openrc

3. Verify Keystone is operational:

      	service keystone status

4. Ensure the Keystone Service Endpoints have been properly configured:

      	keystone endpoint-list

5. Verify glance is operational:

       	service glance-api status
      	service glance-registry status

6. Verify that all of the Nova services on all Nodes are operational:

         nova-manage service list
         Binary           Host          Zone   Status     State Updated_At
         nova-volume      <your_host>   nova   enabled    :-)   2012-06-06 22:30:05
         nova-consoleauth <your_host>   nova   enabled    :-)   2012-06-06 22:30:04
         nova-scheduler   <your_host>   nova   enabled    :-)   2012-06-06 22:30:05
         nova-compute     <your_host>   nova   enabled    :-)   2012-06-06 22:30:02
         nova-network     <your_host>   nova   enabled    :-)   2012-06-06 22:30:07
         nova-cert        <your_host>   nova   enabled    :-)   2012-06-06 22:30:04

7. Run the nova_test script from the Controller that has the openstack::test_file class (Control1 by default):

        . /tmp/test_nova.sh

8. Connect to the Horizon Virtual IP address (OpenStack Dashboard) through a web browser:

  - create a keypair
  - edit the default security group to allow icmp -1 -1 and tcp 22 22 for testing purposes.
  - fire up a VM.
  - create a volume.
  - attach the volume to the VM.
  - allocate a floating IP address to a VM instance.
  - verify that volume is actually attached to the VM and that
    it is reachable by its floating ip address.

## Participating

Need a feature? Found a bug? Let me know!

We are extremely interested in growing a community of OpenStack experts and
users around these modules so they can serve as an example of consolidated best
practices of production-quality OpenStack deployments.

The best way to get help with this set of modules is through email:

  danehans@cisco.com

Issues should be reported here:

  danehans@cisco.com

The process for contributing code is as follows:

* fork the projects in github
* submit pull requests to the projects containing code contributions

## Future Features:

  Efforts are underway to implement the following additional features:

  * Support OpenStack Grizzly release with Quantum and Cinder.
  * Integrate with PuppetDB to allow service auto-discovery to simplify the
    configuration of service association
