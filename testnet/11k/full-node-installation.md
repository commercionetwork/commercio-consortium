# Install a testnet node (WIP)

## Hardware requirements:

| Characteristic | Specification |
| ----- | ----- |
| Operative System | Ubuntu 20.04 |
| Number of CPUs | 2 |
| RAM | 4GB |
| SSD | 40GB |

## Install full node

Update the OS:

```bash
apt update && apt upgrade -y
apt install -y git gcc make unzip
snap install --classic go
```

Create a user for the blockchain:
```bash
adduser --disabled-password commercionetwork
su - commercionetwork
```

Set enviroment variables for the node:
```bash
echo 'export GOPATH="$HOME/go"' >> ~/.bashrc
echo 'export PATH="$GOPATH/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="$PATH:/snap/bin"' >> ~/.bashrc

source ~/.bashrc
```

Before installing the node, please select which chain you would like to connect to:
```bash
rm -rf commercio-chains
mkdir commercio-chains && cd commercio-chains
git clone https://github.com/commercionetwork/chains.git .
git checkout commercio-testnet11k # <- checkout the correct branch! This is for testnet11k
cd commercio-testnet11k # <- same for the folder!
```

Compile binaries:
```bash
pkill commercionetworkd
git init . 
git remote add origin https://github.com/commercionetwork/commercionetwork.git
git pull
git checkout tags/$(cat .data | grep -oP 'Release\s+\K\S+')
go mod verify
make install
```

Test if you have the correct binaries version:
```bash
commercionetworkd version
# Should output the same version written inside the .data file
```
---
**Follow the three steps below only if compiled the binary locally (not on your node) otherwise skip this part**
1. Transfer the binary to your node:
```bash
scp commercionetworkd <username>@<node-ip-address>:/home/commercionetwork/go/bin
```
2. Transfer the `libwasm.so` library to your node:
```bash
cd $HOME/go/pkg/mod/github.com && cd '!cosm!wasm'
scp wasmvm@v1.0.0-beta/api/libwasmvm.so <username>@<node-ip-address>:/home/commercionetwork/go/bin
```
3. Set `LD_LIBRARY_PATH` enviroment variable:
```bash
cat <<EOF >> ~/.bashrc
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$GOPATH/bin
EOF
```

---

Setup the validator node name. We will use the same name for node as well as the wallet key:
```bash
export NODENAME="<your-moniker>"
export CHAINID=commercio-$(cat .data | grep -oP 'Name\s+\K\S+')
cat <<EOF >> ~/.bashrc
export NODENAME="$NODENAME"
export CHAINID="$CHAINID"
EOF
```

Init the `.commercionetwork` folder with the basic configuration:
```bash
commercionetworkd unsafe-reset-all
commercionetworkd init $NODENAME
```

Install `genesis.json` file:
```bash
rm -rf ~/.commercionetwork/config/genesis.json
cp genesis.json ~/.commercionetwork/config
```

Change the persistent peers inside `config.toml` file:
```bash
sed -e "s|persistent_peers = \".*\"|persistent_peers = \"$(cat .data | grep -oP 'Persistent peers\s+\K\S+')\"|g" ~/.commercionetwork/config/config.toml > ~/.commercionetwork/config/config.toml.tmp
mv ~/.commercionetwork/config/config.toml.tmp  ~/.commercionetwork/config/config.toml
```

Change the seeds inside `config.toml` file:
```bash
sed -e "s|seeds = \".*\"|seeds = \"$(cat .data | grep -oP 'Seeds\s+\K\S+')\"|g" ~/.commercionetwork/config/config.toml > ~/.commercionetwork/config/config.toml.tmp
mv ~/.commercionetwork/config/config.toml.tmp  ~/.commercionetwork/config/config.toml
```

Change `external_address` value to contact your node using public ip of your node:
```bash
PUB_IP=`curl -s -4 icanhazip.com`
sed -e "s|external_address = \".*\"|external_address = \"$PUB_IP:26656\"|g" ~/.commercionetwork/config/config.toml > ~/.commercionetwork/config/config.toml.tmp
mv ~/.commercionetwork/config/config.toml.tmp  ~/.commercionetwork/config/config.toml
```

Change the `chain-id` inside `config.toml` file:
```bash
sed -e "s|chain-id = \".*\"|chain-id = \"$CHAINID\"|g" ~/.commercionetwork/config/config.toml > ~/.commercionetwork/config/config.toml.tmp
mv ~/.commercionetwork/config/config.toml.tmp  ~/.commercionetwork/config/config.toml
```

Choose 1 of these 3 ways to syncronize your node to the blockchain:
- [Install a testnet node (WIP)](#install-a-testnet-node-wip)
  - [Hardware requirements:](#hardware-requirements)
  - [Install full node](#install-full-node)
    - [From the start](#from-the-start)
    - [Using the state sync future](#using-the-state-sync-future)
    - [Using the quicksync dump](#using-the-quicksync-dump)
  - [Cosmovisor configuration](#cosmovisor-configuration)
### From the start

If you intend to syncronize eveything from the start you can skip this part and continue with the configuration.

### Using the state sync future

Under the state sync section in `/home/commercionetwork/.commercionetwork/config/config.toml` you will find multiple settings that need to be configured in order for your node to use state sync.
You need get information from chain about trusted block using

```bash
curl -s "http://157.230.110.18:26657/block" | jq -r '.result.block.header.height + "\n" + .result.block_id.hash'
```

The command should be return block height and hash of block:
```
5075021EB1032C6DFC9F2708B16DF8163CAB2258B0F1E1452AEF031CA3F32004F54C9D1
```

Edit these settings accordingly:

```
[statesync]

enable = true

rpc_servers = "157.230.110.18:26657,46.101.146.48:26657"
trust_height = 5075021
trust_hash = "EB1032C6DFC9F2708B16DF8163CAB2258B0F1E1452AEF031CA3F32004F54C9D1"
```

### Using the quicksync dump

Run these commands to quickly sync your node:

```bash
wget "https://quicksync.commercio.network/$CHAINID.latest.tgz" -P ~/.commercionetwork/
# Check if the checksum matches the one present inside https://quicksync.commercio.network
cd ~/.commercionetwork/
tar -zxf $(echo $CHAINID).latest.tgz
```

## Cosmovisor configuration

Download and compile cosmovisor:
```bash
cd $HOME
git clone https://github.com/cosmos/cosmos-sdk.git
cd cosmos-sdk
git checkout cosmovisor/v0.1.0
cd cosmovisor
make
cp cosmovisor $HOME/go/bin
```

Make cosmovisor folder structure:
```bash
mkdir -p $HOME/.commercionetwork/cosmovisor/genesis/bin
mkdir -p $HOME/.commercionetwork/cosmovisor/upgrades
```

Copy `commercionetwork` to cosmovisor folder
```bash
cp $HOME/go/bin/commercionetworkd $HOME/.commercionetwork/cosmovisor/genesis/bin
``` 

Configure the service:
```bash
exit # <- Login back to root at this point!

tee /etc/systemd/system/commercionetworkd.service > /dev/null <<EOF  
[Unit]
Description=Commercio Network Node
After=network.target

[Service]
User=commercionetwork
LimitNOFILE=4096

Restart=always
RestartSec=3

Environment="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/home/commercionetwork/bin/go" # <-- set this only if you compiled "commercionetworkd" locally
Environment="DAEMON_NAME=commercionetworkd"
Environment="DAEMON_HOME=/home/commercionetwork/.commercionetwork"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"
Environment="DAEMON_LOG_BUFFER_SIZE=512"

ExecStart=/home/commercionetwork/go/bin/cosmovisor start --home="/home/commercionetwork/.commercionetwork" 

[Install]
WantedBy=multi-user.target
EOF
```

Now you can start your full node. Enable the newly created server and try to start it using:
```bash
systemctl enable commercionetworkd  
systemctl start commercionetworkd
```

Control if the sync was started. Use `Ctrl + C` to interrupt the `journalctl` command:
```bash
journalctl -u commercionetworkd -f
```