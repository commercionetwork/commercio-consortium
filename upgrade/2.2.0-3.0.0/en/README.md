# Upgrade instructions from 2.2.0 to 3.0.0 Commercio Network Chain 

# `THE FINAL VERSION 3.0.0 IS PUBLISHED`

The update date has been set for `23 Febbraio 2022 alle 14.30 UTC= 15.30 CET`. The posted height should stop the chain shortly after 14.30 UTC = 15.30 CET. The deviation could be a few minutes.




  - [Summary](#summary)
  - [Migration](#migration)
  - [Preliminary operations](preliminary-operations)
  - [Risks](#risks)
  - [Validator update procedure](#update-procedure)
  - [Full-node upgrade procedures](#full-node-guide)
  - [Restore](#restore)
  - [Note](#note)
 
# Summary

The chain update is scheduled for February 23, 2022 at 2.30 pm UTC (3.30 pm Central European Time).

These are briefly the steps to take in the update


1. Stop the Commerce Network node with core v2.2.0
1. Export the chain status
1. Perform a chain status migration with the new Commerce Network core producing the new genesis
1. Install the new Commerce Network core and the new genesis and perform a chain reset
1. Start the new core daemon and wait for the consensus to be reached


The details of the upgrade are in the [Upgrade Procedure section](#update-procedure).     

For full-nodes (sentry) specific instructions have been created on [Full-node upgrade procedures](#full-node-guide).


The coordination of the nodes will be managed within the Telegram channel for the validating nodes.

**Important** The update may have the following results:
1. `Successful upgrade`: the validators succeed in the migration and in the update and the new chain will be started. The period for issuing the first block and reaching consensus may take a long time.
2. `Starting new chain failed`: if problems are found during the start of the new chain and it is not possible to reach consensus. In this case the nodes will be stopped and the backup will be recovered and the chain will restart with the previous version. The update will be rescheduled by checking the problems found and running the related fixes.  
3. `Procedure cannot be completed`: if problems are found at the export or migration level that do not allow the update to proceed (e.g. the checksum of the new genesis does not match between the validating nodes) it will be aborted and the backup of the chain will be recovered and restarted the previous version.

# Migration

Migration involves substantial changes in some modules and other minor changes in others. The most notable changes are listed below

1. `Id` -> `Did`
1. `Documents`
2. `CommercioKyc`
3. `CommercioMint`
4. `VBR`
5. `Ante`
6. `Government`

More details are given in [docs.commercio.network](https://docs.commercio.network). In that documentation, the versions `2.1.2`, `2.2.0` and `3.0.0` are highlighted at the top-right


---
## Preliminary operations

There are a few things to consider before upgrading
1. Make sure you have enough disk space: currently the pruned database of the chain occupies 80 / 90Gb, so the servers disk must have enough space to contain the database for it, that will act as a backup plus at least another 50Gb for export and migration operations and for the start of the new chain. So you need 90gb + 50gb = 140gb in total in your disk. **NB** In the future you need enlarge your disk when the chain grows.
2. **Ram**: 8GB minimum required. 16Gb recommended. Ram requirements may be increased in the future.
3. It is advisable, as soon as the final release is published, to **compile on the node**: compiling the binaries during the upgrade could slow down the operations. **The final version will be with the tag `v3.0.0`**
4. Prepare the file configurations `config.toml` and `app.toml` first so that you have them ready at the time of the upgrade. Read this [guide](./prepare_config.md) to prepare your configurations.
5. Suspend transactions where possible: the transactions when the chain will be stopped will be rejected and therefore their sending will depend on how the sending client handles these errors.
6. For those who make use of `tmkms` immediately update the tmkms at least to version 0.10.0. For those who use the yubiHSM with a single key, read the procedure in [Updating tmkms](./update-tmkms.md). Those who use the yubiHSM with multiple keys, on the other hand, read the [tmkms update with multiple keys guide](./update-tmkms-multiple-keys.md)

---
## Risks

One of the biggest risks for validators is to incur in double signing. It is absolutely necessary to check your software version and genesis. Furthermore, it is necessary to move the state file, both on the validator, if you are using file private key, and on the tmkms if you use the latter. 

<img src="../img/attetion.png" width="30"> **Do not delete the status file**

If any errors are made during the update, for example using an incorrect version of the software or an incorrect genesis, it is better to wait for the chain to restart and join later.

**READ THE [RESTORE SECTION](#restore) CAREFULLY**

---
## Update procedure

__Note__: It is assumed that the node on which you are going to operate has the `v2.2.0` version of the core of the chain.      
__Note 2__: The instructions must be adapted to your environment, so variables and paths must be changed according to the installations.


The version/hash commit of commercio network is v2.2.0: `3e02d5e761eab3729ccf6f874d3c929342e4230c`

1. Check the current version (v2.2.0) of _cnd_:

   ```bash
    cnd version --long
   ```  
   It should report the following result
   ``` 
   name: commercionetwork
   server_name: cnd
   client_name: cndcli
   version: 2.2.0
   commit: 3e02d5e761eab3729ccf6f874d3c929342e4230c
   build_tags: netgo,ledger
   go: go version go1.17.5 linux/amd64
   build_deps:
    ...
   ```

   Install the appropriate tools if not present

   ```bash
   apt install jq -y
   ```

   Check the version of `go` it at least `1.16+`


2. Verify that the exact stop block is set: `2233550` (A check will still be made on the morning of 23/02/2022 to verify the progress of the blocks)

   
   ```bash
   sed 's/^halt-height =.*/halt-height = 2233550/g' ~/.cnd/config/app.toml > ~/.cnd/config/app.toml.tmp
   mv ~/.cnd/config/app.toml.tmp  ~/.cnd/config/app.toml
   ```
   And apply the configuration using the command
   ```bash
   systemctl restart cnd
   ```
   The node should stop at the height `2233550`. Check with

   ```bash
   journalctl -u cnd -f
   ```

3. After the chain has stopped, stop the node and export the status:
   ```bash
   systemctl stop cnd
   systemctl stop cncli
   pkill cnd
   pkill cncli
   systemctl disable cnd
   systemctl disable cncli
   ```
   **Warning**: the command `systemctl stop cncli` could give an error, since the service `cncli` is only for the rest api and is not set up everywhere.

   Export the chain
   ```bash
   cnd export  > ~/commercio-2_2_genesis_export.json
   ```
   **NB**: this operation is only necessary on the validator nodes. The produced genesis can then be installed on sentry nodes. 
   The process may take some time and depends on the resources available on the node.

   Some statistics with mainnet
    * Export height: **2210048**
    * Server used
      * 4 Cpu
      * 8Gb ram
      * SSD disk
    * Export duration: **12minutes**
    * Export weight: **81Mbyte**
    * Shasum calculation duration: **7seconds**
    * Binary compile: **2minutes**
    * Migrate duration: **30seconds**
    * New genesis weight: **85Mbyte**
    * Shasum calculation duration: **7seconds**
    * Startup: **N.A.**
    * Total update duration: **15minutes**
    * Total space required: **200Mbyte**
  

4. Keep safe your `.cnd` directory folder
    The new version will create the database and config folder under other directory. Leave the `.cnd` folder in your server and keep it safe as backup.

    **NB**: The backup is essential in case the procedure fails and all nodes are invited to perform it. The backup will be used in the eventuality as indicated in the See [Restore](#restore) section.

5. Checsum check of the exported gensis file:

   Through chat communication, all validator nodes will have to post the export checksum result

   ```bash
   $ jq -S -c -M '' ~/commercio-2_2_genesis_export.json | shasum -a 256
   ```

   <img src="../img/attetion.png" width="30">The result should be like
   ```
   [SHA256_VALUE]  -
   ```
   Copy and paste the value on the Telegram group `[SHA256_VALUE]` and compare it with all the other validators


6. Compile the new binary **if you haven't done it before**

    
   ```bash
    rm -rf commercionetwork # Delete repo folder if exists
    git clone https://github.com/commercionetwork/commercionetwork.git && cd commercionetwork
    git checkout tags/v3.0.0
    make install
   ```

   **Follow these steps only if compiled the binary locally (not on your node)**
   - Transfer the binary to your node:
   ```bash
   scp commercionetworkd <username>@<node-ip-address>:/home/commercionetwork/go/bin
   ```
   
   - Transfer the `libwasm.so` library to your node:
   ```bash
   cd $HOME/go/pkg/mod/github.com && cd '!cosm!wasm'
   scp wasmvm@v1.0.0-beta/api/libwasmvm.so <username>@<node-ip-address>:/home/commercionetwork/go/bin
   ```

   - Set `LD_LIBRARY_PATH` enviroment variable in your validator node with the user that will run the `commercionetworkd` application:
   ```bash
   cat <<EOF >> ~/.bashrc
   LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$GOPATH/bin
   EOF
   ```

7. Verify that the applications are the right version:

   ```bash
    commercionetworkd version
   ```
    Values ​​should be 
   ```
   name: blog
   server_name: <appd>
   version: 3.0.0
   commit: 3be71db0569fd394d23cf799ef96d5b4c6d8f24b
   build_tags: ""
   go: go version go1.17.5 darwin/amd64
    ...er
   ```
   The hash version of the new software should be v3.0.0: `3be71db0569fd394d23cf799ef96d5b4c6d8f24b`
   P.S: Sorry for `name` and other missed filed. In v3.0.1 will fix it.

8. At this point, the genesis file must be migrated to make the new state compliant for the new core.
   The last validated height for the chain must be acquired

   ```bash
   LAST_220_BLOCK=$(cat .cnd/data/priv_validator_state.json  | jq -r '.height')
   LAST_220_BLOCK=$(($LAST_220_BLOCK+1))
   echo $LAST_220_BLOCK
   ```
   <img src="../img/attetion.png" width="30"> **If you use kms read this value from your kms.**

   <img src="../img/attetion.png" width="30">Compare the value of `$LAST_220_BLOCK` with all other validators.      
   If the value is the same then go haed with migration. If the value is different, the one with the minor common value will be selected.

   ```bash
   commercionetworkd migrate v3.0.0 \
    ~/commercio-2_2_genesis_export.json \
    --chain-id=commercio-3 \
    --initial-height=$LAST_220_BLOCK > ~/genesis.json
   ```

9. Check the checksum of the produced genesis:
   ```bash
    jq -S -c -M '' ~/genesis.json | shasum -a 256
   ```
   The result should be like
   ```
    [SHA256_VALUE]  -
   ```
   <img src="../img/attetion.png" width="30">Copy and paste the value on the Telegram group `[SHA256_VALUE]` and compare it with all the other validators

10. Initialization of folders in the chain:
   ```bash
    commercionetworkd unsafe-reset-all
   ```
   A folder should appear on your home `.commmercionetwork`

11. Install the new genesis of the new chain
   ```bash
    cp ~/genesis.json ~/.commmercionetwork/config/
   ```
   <img src="../img/attetion.png" width="30"> **ATTENTION** at this stage the sentries must be updated first. Check the [full node upgrade procedure](#full-node-guide)

12. Check the file configurations `config.toml`, `app.toml` and copy your crypto material
    Install the `config.toml` and `app.toml` files in `.commmercionetwork/config` folder as you prepare before. If you use `priv_validator_key.json` copy it from previus folder
    ```bash
      cp ~/.cnd/config/priv_validator_key.json ~/.commmercionetwork/config/.
    ```
    Copy your `node_key.json` file. It not strictly necessary, but if you use sentries or if you are a persistent peers for someone you need to copy it
    ```bash
      cp ~/.cnd/config/node_key.json ~/.commmercionetwork/config/.
    ```    
    
13. Creation of the new service
   ```bash
      tee /etc/systemd/system/commercionetworkd.service > /dev/null <<EOF  
      [Unit]
      Description=Commercio Node
      After=network-online.target

      [Service]
      User=root
      ExecStart=/root/go/bin/commercionetworkd start
      Restart=always
      RestartSec=3
      LimitNOFILE=4096

      [Install]
      WantedBy=multi-user.target
      EOF
   ```

14. Starting the new chain
   ```bash
   systemctl start commercionetworkd
   ```
15. Check the status of the node
   ```bash
   journalctl -u commercionetworkd -f
   ```
   The nodes may take some time to arrive at consensus.
   You can check the consensus using
   ```bash
   curl -s http://127.0.0.1:26657/dump_consensus_state | jq '.result.round_state.height_vote_set[0].prevotes_bit_array'
   ```
   A message like this
   ```
   "BA{71:_xxxxx__x__x___x__xx__x___x__xx__x__x__xx__x__} 34908030/169756481 = 0.21"
   ```
   should be returned. The number at the and of the line is the percentage of validator that returned on-line. 0.21 = 21%
# Full Node Guide

1. Verify that the exact stop block is set: `2233550`

   
   ```bash
   sed 's/^halt-height =.*/halt-height = 2233550/g' ~/.cnd/config/app.toml > ~/.cnd/config/app.toml.tmp
   mv ~/.cnd/config/app.toml.tmp  ~/.cnd/config/app.toml
   ```
   And apply the configuration using the command 
   ```bash
   systemctl restart cnd
   ```
   The knot should stop at the height `2233550`. Check with

   ```bash
   journalctl -u cnd -f
   ```
   **NB** The sentry nodes in any case should stop as the validator nodes will stop

2. After the chain has stopped, stop the node and export the status:
   ```bash
   systemctl stop cnd
   systemctl stop cncli
   pkill cnd
   pkill cncli
   systemctl disable cnd
   systemctl disable cncli
   ```
   **Warning**: the command `systemctl stop cncli` could give an error, since the service `cncli` is only for the rest api and is not set up everywhere.


3. Compile the new binary

   ```bash
    git clone https://github.com/commercionetwork/commercionetwork.git && cd commercionetwork
    git checkout tags/v3.0.0
    make install
   ```

4. Verify that the applications are the right version:

   ```bash
    cnd version
    ```
    Values ​​should be 
    ```
    name: commercionetworkd
    server_name: commercionetworkd
    version: v3.0.0
    commit: ??????
    build_tags: netgo,ledger
    ...
   ```
    The hash version of the new software should be v3.0.0: `????`

5. Chain status reset:

   ```bash
   commercionetworkd unsafe-reset-all
   ```
6. Install the new geneis of the new chain
   
   From a validator node or from the repo of the chains (this however will be ready only after the completion of the procedure) copy the genesis.
   **From your computer, therefore outside the servers, assuming you are using ssh for access and that the procedure on the validator is in point 11**
   ```bash
   scp <VALIDATOR USER>@<VALIDATOR IP>:.commercionetwork/config/genesis.json .
   scp genesis.json <FULL NODE USER>@<FULL NODE IP>:.commercionetwork/config/.
   ```
7. Creation of the new service
   ```bash
      tee /etc/systemd/system/commercionetworkd.service > /dev/null <<EOF  
      [Unit]
      Description=Commercio Node
      After=network-online.target

      [Service]
      User=root
      ExecStart=/root/go/bin/commercionetworkd start
      Restart=always
      RestartSec=3
      LimitNOFILE=4096

      [Install]
      WantedBy=multi-user.target
      EOF
   ```

8. Starting the new chain

   ```bash
   systemctl start commercionetworkd
   systemctl enable commercionetworkd
   ```

## Restore

Before updating all validators are required to keep the folder `.cnd` as a backup of the chain state. The backup must be kept both on the validator nodes and on the sentries and in general on any full node in the chain.     
It is also essential to save the file `.cnd/data/priv_validator_state.json`, or in the case of using the `tmkms` status file reported in the configuration `state_file`. This file, especially, will need to be restored in case the update fails.   

It is also necessary to make a backup of the configurations, both on the validator nodes, sentry and tmkms, always to have the possibility to perform a clean restore in case of problems.    

From the [update procedure](#update-procedure) these are the steps for the recovery procedure

1. Stop any services
   ```bash
   systemctl stop commercionetworkd
   pkill commercionetworkd
   ```

2. Correctly restore the file `app.toml`
   ```bash
   sed 's/^halt-height =.*/halt-height = 0/g' ~/.cnd/config/app.toml > ~/.cnd/config/app.toml.tmp
   mv ~/.cnd/config/app.toml.tmp  ~/.cnd/config/app.toml
   ```  


3. Starting the previous chain

   ```bash
   systemctl start cnd
   systemctl enable cnd
   ```
4. Check the status of the node
   ```bash
   journalctl -u cnd -f
   ```
   The nodes may take some time to arrive at consensus.
   

# Note

## Guide explanations
The guide tries to give a general explanation of what to do during the update. The difficulty in writing this guide is that everyone has their own environment, so it is difficult to build a complete system. 
Maintaining some kind of software that fits all systems and environments would be very costly. 
Basically the whole procedure, limited to the nodes, is reduced to

* stop services
* change the programs (binaries) with the new version
* change a couple of config files
* clean up the database
* restarting the services.
Including the procedure, the process is substantially not particularly complicated. Everyone can extract their own automated procedure from the indications.

### Common mistakes or doubts

1. The service returns me a permissions error     
   In the guide it is supposed to act as `root` for the whole process. If the services have been configured with another user, parameter `User=<CHAIN USER>` in `/etc/systemctl/system/cnd.service`, then the folders of the `cnd` may no longer be accessible with that user because they have been changed by `root`.    
   Before starting the services it should be sufficient to run the command
   ```bash
   sudo chown -R <CHAIN USER> ~/.cnd
   ```
   In general, if the procedure will be performed with a user other than `root` stopping the services and restarting them, always use sudo `sudo`. For example 

   ```
   sudo systemctl start cnd
   ```
   
2. The node does not get the sign     
   Check that there are no network problems between the kms and the validator, eg. Vpn off. A simple one pingshould suffice to check reachability.    
   If you have possibly restarted the server and the service that manages the vpn starts after the service starts, cndthen the service may not be able to reach the kms. Stop the service cnd, check the communication between kms and validator, and start the service cndAlso check if the configuration in config.tomlthe validator file has changed because for example the value ofpriv_validator_laddr

 
3. If I don't introduce myself, what happens   
   Essentially you have about 17/18 hours to reactivate the validator. The procedure, apart from the hash checks, are still valid. In this case, however, it is advisable to download the genesis from the chains repo.

3. I have hashes of genesis different from all the others    
   In this case the same procedure applies as in the previous point.
