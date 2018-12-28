# Multi host deployment

There are two approaches for creating virtual machines which are to be used as Nodes:
- utilizing docker-machine functionality for quick creation of virtual machines with docker support from one terminal.
- manual creation of virtual machines independently of each other.

Then we can [Deploy Blockchain network](#blockchain)

See also options for providing name-resolution of DNS names for Hyperledger Fabric components (peers, orderer, CAs) located on different servers:
- configuring extra-hosts parameter which is added by docker-composer to each container's /etc/hosts file
- configuring DNS service specific for particular blockchain network (either central or DNS-cluster)
- using Docker Swarm engine to have all components in one virtual sub-net (there are security issues with this approach
so it's recommended only for test\dev purposes)



## Prepare multi host deployment with Docker Machine

Docker Machine utility provides convenient command-line tool for managing multiple virtual machines (such as Virtualbox or VMs in clouds)
from one terminal and with automatic docker support. This facilitates

### Install docker-machine

Install [docker-machine](https://docs.docker.com/machine/get-started/).
For local deployment also install [VirtualBox](https://www.virtualbox.org/wiki/Downloads).

### Create necessary amount of Virtual Machines
Using docker machine we can quickly create Virtual Machines either local with VirtualBox or remote in any cloud infrastructure (Azure, AWS, etc).
It's very convenient taht the VMs created by the docker-machine automatically already have the docker engine installed on it.

We then need create one VM for each orderer's and organization's node.

Create a local VM for `orderer` and `org1`:
```bash
docker-machine create --driver virtualbox orderer
docker-machine create --driver virtualbox org1
```

Create VM in Azure:
```bash
docker-machine create --driver azure --azure-subscription-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
--azure-location westeurope \
--azure-size Standard_F4s_v2  \
--azure-open-port 80 --azure-open-port 7050  \
--azure-ssh-user ubuntu \
orderer

docker-machine create --driver azure --azure-subscription-id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \
--azure-location westeurope \
--azure-size Standard_F4s_v2  \
--azure-open-port 80 --azure-open-port 7051 --azure-open-port 7054 \
--azure-ssh-user ubuntu \
org1
```

We can see the ip address of the created VMs:
```bash
docker-machine ls
```
Returns:
```
NAME      ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
orderer   *        virtualbox   Running   tcp://192.168.99.100:2376           v18.06.1-ce
org1      *        virtualbox   Running   tcp://192.168.99.101:2376           v18.06.1-ce
```


### Copy templates and chaincode files to remote VM
Copy local template files to all VMs to `orderer` home directory (`/home/docker` on VirtualBox or `/home/ubuntu` on AWS EC2).
```bash
docker-machine scp -r templates orderer:
docker-machine scp -r chaincode orderer:
docker-machine scp -r templates org1:
docker-machine scp -r chaincode org1:
```


### Set multihost-related environment variables
```bash
export MULTIHOST=1
export WORK_DIR=`docker-machine ssh orderer pwd`
```


After all necessary VMs have been created *docker-machine* allows to switch between them just by applying corresponded environment.
Connect to `orderer` machine by setting env variables:
```bash
eval "$(docker-machine env orderer)"
```


When the terminal is "connected" any `docker` commands will actually be executed on the remote VM and not in the local host.
So the administrator can perform necessary operations on each node in order to deploy the network.


## Prepare multi host environment for manual deployment

Manual deployment means that the administrator have to allocate hardware or virtual machine, install Operating System,
install docker and docker-compose utilities and connect to the machines by SSH.

This time you don't need to export MULTIHOST and WORK_DIR environment variables.


The further steps for deploying blockchain components generally don't depend on how are you connected to remote machine (by docker-machine or by SSH)
and just have to be performed in corresponded machine.



<a name="blockchain"></a>
# Deployment of Blockchain network

## Deploy orderer

Connect to `orderer` machine
Now template files are on the `orderer` host and we can run `./generate-orderer.sh` but with a flag
`COMPOSE_FLAGS` which adds an extra docker-compose file `orderer-multihost.yaml` on top of the base
`docker-compose-orderer.yaml`. This file redefines volume mappings from `${PWD}` local to your host machine to
directory on remote host specified by `WORK_DIR` (defaulted to VirtualBox's home `/home/docker`;
for AWS EC2 do `export WORK_DIR=/home/ubuntu`).




















## Prepare multi host environment for manual deployment

On each node including orderer clone *fabric-starter* project and export multi-host related flag and
WORK_DIR variable specifying absolute path to fabric-starter folder:

```bash
export MULTIHOST=1
export WORK_DIR=/home/ubuntu/fabric-starter
```

Start Swarm manager and join nodes as described in [swarm.md](swarm.md)
If it's undesirable to use Swarm because of security reasons, configure DNS service(s) as described in [dns.md](dns.md)

Deploy multi-host network in multihost environment as described below.


## Preparing multi host deployment with docker-machine

Install [docker-machine](https://docs.docker.com/machine/get-started/).
For local deployment install [VirtualBox](https://www.virtualbox.org/wiki/Downloads).


### Create orderer machine

Create and start `orderer` docker host as a virtual machine.
For AWS EC2 use `--driver amazonec2` and `export WORK_DIR=/home/ubuntu`.
```bash
docker-machine create --driver virtualbox orderer
```

See the ip address of the created VM.
```bash
docker-machine ls
```
Returns
```
NAME      ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
orderer   *        virtualbox   Running   tcp://192.168.99.100:2376           v18.06.1-ce
```

Connect to `orderer` machine by setting env variables.
```bash
eval "$(docker-machine env orderer)"
```

Start docker swarm on `orderer` machine. Replace ip address `192.168.99.100` with the actual ip of the remote host interface.
```bash
docker swarm init --advertise-addr 192.168.99.100
```
will output a command to join the swarm by other hosts;

The other hosts will be join to the swarm by the following command (this is an example, use the actual token and ip):
```bash
docker swarm join --token SWMTKN-1-4fbasgnyfz5uqhybbesr9gbhg0lqlcj5luotclhij87owzd4ve-4k16civlmj3hfz1q715csr8lf 192.168.99.100:2377
```

Copy local template files to `orderer` home directory (`/home/docker` on VirtualBox or `/home/ubuntu` on AWS EC2).
```bash
docker-machine scp -r templates orderer:templates
```

Now template files are on the `orderer` host and we can run `./generate-orderer.sh` but with a flag
`COMPOSE_FLAGS` which adds an extra docker-compose file `orderer-multihost.yaml` on top of the base
`docker-compose-orderer.yaml`. This file redefines volume mappings from `${PWD}` local to your host machine to
directory on remote host specified by `WORK_DIR` (defaulted to VirtualBox's home `/home/docker`;
for AWS EC2 do `export WORK_DIR=/home/ubuntu`).

Later docker-machine allows to "connect" to created machines by invoking `docker-machine env` command for specified machine name (org1):
```bash
eval "$(docker-machine env org1)"
```

After that docker commands running in local console will actually be executed in the (remote) machine.


# Deploy network on multiple nodes

Connect to orderer machine (with *ssh* for manual or *docker-machine env* command for docker machine):
```bash
./generate-orderer.sh
```

Start *Orderer* containers on `orderer` machine.
```bash
docker-compose -f docker-compose-orderer.yaml -f orderer-multihost.yaml up -d
```

### Create org1 machine

For docker-machine deployment create and start `org1` docker host as a virtual machine with VirtualBox.
```bash
docker-machine create --driver virtualbox org1
```

and connect to `org1` machine by setting env variables.
```bash
eval "$(docker-machine env org1)"
```

Or connect to `org1` machine by ssh for manual mode.

Join swarm; this is an example, use the actual command output by `orderer`. In orderer console get the command:
```bash
docker swarm join-token worker
```
Execute the output command in `org1` console.
```bash
docker swarm join --token SWMTKN-1-4rzq6pyg3z2kw7eqhqdnc86isjpwo6t69t1q0ooy84csioieyc-ajcb0rdg3l15ronhytmldc59s 192.168.99.100:2377
```

Need to run a dummy container on this new host `org1` to force join overlay network `fabric-overlay`
created by docker-compose on `orderer` host.
```bash
docker run -dit --name alpine --network fabric-overlay alpine
```

Copy local template and chaincode files to `org1` machine.
```bash
docker-machine scp -r templates org1:templates

docker-machine scp -r chaincode org1:chaincode

docker-machine scp -r webapp org1:webapp
```

Generate crypto material for member organization *org1*.

```bash
./generate-peer.sh
```

Start *org1* containers on `org1` machine.
```bash
docker-compose -f docker-compose.yaml -f multihost.yaml up -d
```

### Add org1 to the consortium as Orderer

Now `org1` machine is up and running a web container serving root certificates of *org1*. The orderer can access it
via an overlay network, download certs and add *org1*.

Connect to `orderer` machine by setting env variables or by SSH.
```bash
eval "$(docker-machine env orderer)"
```

Run local script to add to the consortium.
```
./consortium-add-org.sh org1
```

### Create a channel and deploy chaincode as org1

Connect to `org1` machine by setting env variables.
```bash
eval "$(docker-machine env org1)"
```

Run local scripts to create and join channels.
```
./channel-create.sh common

./channel-join.sh common

./chaincode-install.sh reference

./chaincode-instantiate.sh common reference
```

### Create org2 machine

```bash
export ORG=org2
export ORGS='{"org1":"peer0.org1.example.com:7051","org2":"peer0.org2.example.com:7051"}' CAS='{"org2":"ca.org2.example.com:7054"}'
docker-machine create --driver virtualbox org2
eval "$(docker-machine env org2)"
docker swarm join --token SWMTKN-1-4fbasgnyfz5uqhybbesr9gbhg0lqlcj5luotclhij87owzd4ve-4k16civlmj3hfz1q715csr8lf 192.168.99.102:2377
docker run -dit --name alpine --network fabric-overlay alpine
docker-machine scp -r templates org2:templates
docker-machine scp -r chaincode org2:chaincode
./generate-peer.sh
docker-compose -f docker-compose.yaml -f multihost.yaml up
```

Return to `org1` machine to add *org2* to the channel.
```bash
eval "$(docker-machine env org1)"
./channel-add-org.sh common org2
```

Back to `org2` machine to join channel.
```bash
export ORG=org2
eval "$(docker-machine env org2)"
./channel-join.sh common
```

Install chaincode (no need to instantiate) and query.
```bash
./chaincode-install.sh reference
./chaincode-query.sh common reference '["list","account"]'
```

### Create machines for other organizations

The above steps are collected into a single script that creates a machine, generates crypto material and starts
containers on a remote or virtual host for a new org. This example is for *org3*; replace swarm token and manager ip
with your own from `docker swarm join-token worker`.
```bash
./machine-create-peer.sh SWMTKN-1-4fbasgnyfz5uqhybbesr9gbhg0lqlcj5luotclhij87owzd4ve-4k16civlmj3hfz1q715csr8lf 192.168.99.102 org3
```
