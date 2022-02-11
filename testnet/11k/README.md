# Install a testnet node with statesync method (WIP)

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
```
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

Change the seeds inside the `config.toml` file:
```bash
sed -e "s|seeds = \".*\"|seeds = \"$(cat .data | grep -oP 'Seeds\s+\K\S+')\"|g" ~/.commercionetwork/config/config.toml > ~/.commercionetwork/config/config.toml.tmp
mv ~/.commercionetwork/config/config.toml.tmp  ~/.commercionetwork/config/config.toml
```

Chenge `external_address` value to contact your node using public ip of your node:
```bash
PUB_IP=`curl -s -4 icanhazip.com`
sed -e "s|external_address = \".*\"|external_address = \"$PUB_IP:26656\"|g" ~/.commercionetwork/config/config.toml > ~/.commercionetwork/config/config.toml.tmp
mv ~/.commercionetwork/config/config.toml.tmp  ~/.commercionetwork/config/config.toml
```

Under the state sync section in `/home/commercionetwork/.commercionetwork/config/config.toml` you will find multiple settings that need to be configured in order for your node to use state sync. 
You need get information from chain about trusted block using

```bash
curl -s "http://157.230.110.18:26657/block" |   jq -r '.result.block.header.height + "\n" + .result.block_id.hash'
```

The command should be return block height and hash of block

```
5075021
EB1032C6DFC9F2708B16DF8163CAB2258B0F1E1452AEF031CA3F32004F54C9D1
```

Edit these settings accordingly:

```
[statesync]

enable = true

rpc_servers = "157.230.110.18:26657,46.101.146.48:26657"
trust_height = 5075021
trust_hash = "EB1032C6DFC9F2708B16DF8163CAB2258B0F1E1452AEF031CA3F32004F54C9D1"
```


Configure the service:
```bash
exit # <- Login back to root at this point!

tee /etc/systemd/system/commercionetwork.service > /dev/null <<EOF  
[Unit]
Description=Commercio Node
After=network-online.target

[Service]
User=commercionetwork
ExecStart=/home/commercionetwork/go/bin/commercionetworkd start
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF
```

Now you can start your full node. Enable the newly created server and try starting it using:
```bash
systemctl enable commercionetwork  
systemctl start commercionetwork
```

Control if the sync was started. Use `Ctrl + C` to interrupt the `journalctl` command:
```bash
journalctl -u commercionetwork -f
```