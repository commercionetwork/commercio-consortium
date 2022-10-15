# Upgrade instructions from version 4.0.0 to version 4.1.0 Commercio Network Chain [Dragonberry Vulnerability](https://forum.cosmos.network/t/ibc-security-advisory-dragonberry/7702)


This is non consensus breaking with respect to v4.0.0. Validators can update without needing a co-ordinated chain upgrade via governance.

## Prerequisites

On your node you should already have the clone of the repository https://github.com/commercionetwork/commercionetwork.

If you do not have it use the command 
```bash
git clone https://github.com/commercionetwork/commercionetwork.git
```

Also on the node you should have all the build tools and paths set up as indicated in the documentation https://docs.commercio.network

## Cosmovisor

**WARNING**

Setup `DAEMON_HOME` variabile with your cosmovisor daemon path if you not already done. In the most case it should be `$HOME/.commercionetwork`
```bash
export DAEMON_HOME=$HOME/.commercionetwork
```


```bash
cd commercionetwork
git fetch --tags && git checkout v4.1.0
make build && make install
# this will return commit 57301949e97160164f732c3d00b4c5a051d379b6 and version 4.1.0
commercionetworkd version --long

# stop service
systemctl stop commercionetworkd

cp $HOME/go/bin/commercionetworkd $DAEMON_HOME/cosmovisor/current/bin
# this will return v4.1.0
$DAEMON_HOME/cosmovisor/current/bin/commercionetworkd version

# start service
systemctl start commercionetworkd
```

Check if the node works with
```bash
journalctl -u commercionetworkd -f
```

Check validator signing in https://mainnet.commercio.network/home


## Other type installation

```bash
cd commercionetwork
git fetch --tags && git checkout v4.1.0
make build
# this will return commit 57301949e97160164f732c3d00b4c5a051d379b6 and version 4.1.0
./build/commercionetworkd version --long
```

Stop the service
```bash
systemctl stop commercionetworkd
```

Copy the compiled binary to your service path.
Use your env path intead `$HOME/go/bin`
```bash
cp $HOME/commercionetwork/build/commercionetworkd $HOME/go/bin
```

Start the service
```bash
systemctl start commercionetworkd
```

Check if the node works with
```bash
journalctl -u commercionetworkd -f
```

Check validator signing in https://mainnet.commercio.network/home
