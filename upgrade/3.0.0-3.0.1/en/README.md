# Upgrade instructions from 3.0.0 to 3.0.1 Commercio Network Chain 

## Prerequisites

1. Have a working node with software version v3.0.0
2. Have all the tools on the server to compile the application as mentioned in the first paragraph at https://docs.commercio.network/nodes/full-node-installation.html

**Please note**: this upgrade is optional. The cli of version 3.0.1 is still compatible with the chain.

## Upgrade procedure

Download the repo from GitHub if you not already done

```bash
git clone https://github.com/commercionetwork/commercionetwork.git
```

Go to the repo folder and checkout to the v3.0.1 tag

```bash
cd commercionetwork
git pull
git checkout v3.0.1
```

Build the Application

```bash
make build
```

Check that the application is the right version

```bash
./build/commercionetworkd version --long
```

The result should be

```
name: commercionetwork
server_name: commercionetword
version: 3.0.1
commit: a350e03980c3ad144ba108063212609e10d71551
build_tags: netgo,ledger
go: go version go1.18 linux/amd64
build_deps:
```

Stop the service, replace the program and restart the service. **Warning**: the path where the executable is installed depends on your environment. In the following it is indicated with $GOPATH.

```bash
systemctl stop commercionetworkd.service
cp ./build/commercionetworkd $GOPATH/bin/.
systemctl start commercionetworkd.service
```

Check if the service is working

```
journalctl -u commercionetworkd.service -f
```


