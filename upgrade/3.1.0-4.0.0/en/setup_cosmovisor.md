## Setup cosmovisor

### What is cosmovisor?

`cosmovisor` is a small process manager for Cosmos SDK application binaries that monitors the governance module for incoming chain upgrade proposals. 
If it sees a proposal that gets approved, cosmovisor can automatically download the new binary, stop the current binary, switch from the old binary to the new one, and finally restart the node with the new binary.
### Installation

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


## Next step
Now that you are a Commercio.network full node, if you want you can become a validator.
If you wish to do so, please read the [*Becoming a validator* guide](validator-node-installation.md).
