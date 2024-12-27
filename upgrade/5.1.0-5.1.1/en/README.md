# Upgrade instructions from version 5.1.0 to version 5.1.1 Commercio Network Chain Mainnet

## Prerequisites


1. Have a working node in **mainnet** with software version v5.1.0.
2. Have all the tools on the server to compile the application as mentioned in the first paragraph at [Installing the software requirements](https://docs.commercio.network/nodes/full-node-installation.html#_1-installing-the-software-requirements)

## WARNING

This is a fix version of the previous one. The upgrade is **MANDATORY**. The nodes that will not upgrade will can't resume the operations.

## Recommendations

To perform the update quickly and make it easy, use `cosmovisor` tools


## Upgrade info

This upgrade will be performed without a proposal. Any node operator can upgrade their node to the new version at any time.

## Upgrade procedure

All commands must be executed as a user who can use `sudo` commands or as `root` user. **Each operator must adapt the commands to their environment.**

1. Stop the service of the node
   ```bash
   sudo systemctl stop commercionetworkd.service
   ```
2. Check the version of golan installed. If you have 1.23.x perform a downgrade. If you have snap installed use the command below
   ```bash
   sudo snap remove go --purge
   sudo snap install go --channel=1.22/stable --classic
   ```
   Check the version of go installed
   ```bash
   go version
   ```
3. Download the repo from GitHub **if you have not already done so**. If you already have the local copy of repository don't try to clone it.
   ```bash
   git clone https://github.com/commercionetwork/commercionetwork.git $HOME/commercionetwork
   ```
4. Go into the folder and checkout to the new version
   ```bash
   cd $HOME/commercionetwork
   git fetch --tags && git checkout v5.1.1
   ```
5. Perform the build of the new version
   ```bash
   make build
   ```
6. Checkout the version of the make build
   ```bash
   ./build/commercionetworkd version
   ```
   It should return version `5.1.1`
7. Clear the cache of wasm
   ```bash
   rm -rf $HOME/.commercionetwork/data/wasm/cache
   ```
8.  Copy the new binary into the folder
   ```bash
   cp $HOME/commercionetwork/build/commercionetworkd $HOME/.commercionetwork/cosmovisor/current/bin/.
   ```
9. Check the version of the binary
   ```bash
   $HOME/.commercionetwork/cosmovisor/current/bin/commercionetworkd version
   ```
   It should return version `5.1.1`
10. Restart the service 
   ```bash
   sudo systemctl start commercionetworkd.service
   ```
11. Check if the service is working
   ```bash
   journalctl -u commercionetworkd.service -f
   ```

**NOTE**: At the beginning of the log the chain seems to be stuck, but after the upgrade of a sufficient number of peers, the chain will start to work correctly.




### ON UPGRADE ERROR 

If you run into an error you can ask help on the [Discord Channel](https://discord.com/channels/973149882032468029/973163682030833685)



