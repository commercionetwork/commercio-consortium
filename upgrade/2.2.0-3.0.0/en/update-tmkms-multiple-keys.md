# KMS

This section shows how to update yubihsm and tmkms based kms with multiple keys. 
**It should be noted that these are guidelines, and it is essential to understand the process summarized here**


Everything can be prepared in advance: already prepare the files with the updated configurations so that at the moment of the chain upgrade the only thing to do is to stop the services and replace the configurations. The previous configurations can then be saved in order to be able to recover them quickly in case of problems.

## Update configurations

**The kms configurations can be updated even before the chain upgrade procedure.** 
This section explains the setup to perform even before updating the chain.      
We assume that you run `tmkms` version **0.10**

1. Create new configurations. The new configuration must be created for compatibility with the new software version. In this phase you can directly prepared configuration compatible with the core version `v3.0.0` of Commercio.Network chain.
   On this guide we will directly prepare the configuration for the version `v3.0.0` on which the service always prepared for the version will draw `v3.0.0`.


   In the multi key configuration you will have a series of configurations. Given that the configurations are contained in the folder `/data_tmkms/tmkms/kms/commercio` (each manager will have its own path), inside this folder I will have a series of configurations such as

    ```
    /data_tmkms/tmkms/kms/commercio/tmkms.01.toml
    /data_tmkms/tmkms/kms/commercio/tmkms.02.toml
    /data_tmkms/tmkms/kms/commercio/tmkms.03.toml
    ...
    ```

  

   The typical configuration `/data_tmkms/tmkms/kms/commercio/tmkms.01.toml` should look like this

   ```toml
    [[chain]]
    id = "commercio-2_2"
    key_format = { type = "bech32", account_key_prefix = "did:com:", consensus_key_prefix = "did:com:valconspub" }
    state_file = "/data_tmkms/tmkms/kms/commercio/commercio_priv_validator_state01.json"

    [[validator]]
    addr = "tcp://10.1.1.1:26658"
    chain_id = "commercio-2_2"
    reconnect = true
    secret_key = "/data_tmkms/tmkms/kms/commercio/secret_connection01.key"
    protocol_version = "v0.33"

    [[providers.yubihsm]]
    adapter = { type = "http", addr = "tcp://127.0.0.1:12345" }
    auth = { key = 1, password_file = "/data_tmkms/tmkms/kms/password" }
    keys = [{ chain_ids = ["commercio-2_2"], key = 1 }] 
    serial_number = "9876543210"
    ```

     Note the following configuration specific parameters to consider for the upgrade

    `[[chain]]` `state_file`: is the status file and will need to be changed. Preserve the previous file.
    `[[chain]]` `id`: It will change from `commercio-2_2` to `commercio-3`
    `[[validator]]` `chain_id`: chain id. It will change from `commercio-2_2` to `commercio-3`
    `[[providers.yubihsm]]` `keys chain_ids`: It will change from `commercio-2_2` to `commercio-3`
    `[[validator]]` `protocol_version`: must be configured with the value `v0.34`
    `[[providers.yubihsm]]` `keys` `key`: is the index of the validator key. Like other parameters in the configuration it changes according to the validator to which the service is connected.

    Create the new configurations dedicated to the new chain for each validator.
    
    `/data_tmkms/tmkms/kms/commercio/tmkms.01.v3.toml`

    ```toml
    [[chain]]
    id = "commercio-3"
    key_format = { type = "bech32", account_key_prefix = "did:com:", consensus_key_prefix = "did:com:valconspub" }
    state_file = "/data_tmkms/tmkms/kms/commercio/commercio_priv_validator_state01.v3.json"

    [[validator]]
    addr = "tcp://10.1.1.1:26658"
    chain_id = "commercio-3"
    reconnect = true
    secret_key = "/data_tmkms/tmkms/kms/commercio/secret_connection01.key"
    protocol_version = "v0.34"

    [[providers.yubihsm]]
    adapter = { type = "http", addr = "tcp://127.0.0.1:12345" }
    auth = { key = 1, password_file = "/data_tmkms/tmkms/kms/password" }
    keys = [{ chain_ids = ["commercio-3"], key = 1 }] 
    serial_number = "9876543210"
    ```

    Carry out the procedure for <N>configurations. Eventually you will have the new configurations
    ```
    /data_tmkms/tmkms/kms/commercio/2.2.0/tmkms.01.v3.toml
    /data_tmkms/tmkms/kms/commercio/2.2.0/tmkms.02.v3.toml
    /data_tmkms/tmkms/kms/commercio/2.2.0/tmkms.03.v3.toml
    ...
    ```
2. Create the new services. Assuming you have a number of such services
    ```
    /etc/systemd/system/tmkms-01.service
    /etc/systemd/system/tmkms-02.service
    /etc/systemd/system/tmkms-03.service
    ...
    ```
    The service `/etc/systemd/system/tmkms-01.service` will be of this type

    ```ini
    [Unit]
    Description=Commercio tmkms
    After=network.target

    [Service]
    User=tmkms
    WorkingDirectory=/data_tmkms/tmkms/.cargo/bin
    ExecStart=/data_tmkms/tmkms/.cargo/bin/tmkms start -c /data_tmkms/tmkms/kms/commercio/tmkms.01.toml
    Restart=always
    SyslogIdentifier=tmkms
    RestartSec=3
    LimitNOFILE=4096

    [Install]
    WantedBy=multi-user.target
    ```

    Note the following configuration specific parameters to consider for the upgrade

    * `ExecStart`: will have to change to `/data_tmkms/tmkms/.cargo/bin/tmkms start -c /data_tmkms/tmkms/kms/commercio/tmkms.01.v3.toml`


    Create the new service `/etc/systemd/system/tmkms-01.v3.service`

    ```ini
    [Unit]
    Description=Commercio tmkms
    After=network.target

    [Service]
    User=tmkms
    WorkingDirectory=/data_tmkms/tmkms/.cargo/bin
    ExecStart=/data_tmkms/tmkms/.cargo/bin/tmkms start -c /data_tmkms/tmkms/kms/commercio/tmkms.01.v3.toml
    Restart=always
    SyslogIdentifier=tmkms
    RestartSec=3
    LimitNOFILE=4096

    [Install]
    WantedBy=multi-user.target
    ```

    The procedure must be repeated for all services, obtaining the list of new services

    ```
    /etc/systemd/system/tmkms-01.v3.service
    /etc/systemd/system/tmkms-02.v3.service
    /etc/systemd/system/tmkms-03.v3.service
    ...
    ```


## Chain update

This section discusses the procedure to be followed when the core of the chain is updated on the validator node.

1. Make sure the validator nodes are turned off The validator nodes connected to the kms must be stopped. If necessary, execute the command on the validator nodes
    ```bash
    sudo systemctl stop cnd # Old service
    ```
2. Stop all services tmkms Stop and disable all services in the kms
    ```bash
    sudo systemctl stop tmkms-01.service
    sudo systemctl disable tmkms-01.service
    sudo systemctl stop tmkms-02.service
    sudo systemctl disable tmkms-02.service
    sudo systemctl stop tmkms-03.service
    sudo systemctl disable tmkms-03.service
    ...
    ```
3. Get height of chain
    ```bash
    cat /data_tmkms/tmkms/kms/commercio/commercio_priv_validator_state01.json  | jq -r '.height'
    cat /data_tmkms/tmkms/kms/commercio/commercio_priv_validator_state02.json  | jq -r '.height'
    cat /data_tmkms/tmkms/kms/commercio/commercio_priv_validator_state03.json  | jq -r '.height'
    ...
    ```
    Use these values to compare with all other validators.
    **NB**: you need `jq` program insalled in your kms. Use `sudo apt install jq` to install it
    

4. Starting in new services This phase can be launched regardless of the validator node activity. 
    When the validator nodes will return to work, kms will immediately start providing the signing service.
    ```bash
    sudo systemctl enable tmkms-01.v3.service
    sudo systemctl start tmkms-01.v3.service
    sudo systemctl enable tmkms-02.v3.service
    sudo systemctl start tmkms-02.v3.service
    sudo systemctl enable tmkms-03.v3.service
    sudo systemctl start tmkms-03.v3.service
    ...
    ```
    Analyzing the logs with the command journalctlit should be possible to see that the tmkms cannot reach the validator node because it is switched off.
    ```
    journalctl -u tmkms-01.v3 -f
    journalctl -u tmkms-02.v3 -f
    journalctl -u tmkms-03.v3 -f
    ...
    ```
    When the node is reactivated, the signing should restart regularly

## Recovery in case of update problems

If the chain update fails, follow this procedure

1. Stop all services tmkms Stop and disable all services in the kms
    ```bash
    sudo systemctl stop tmkms-01.v3.service
    sudo systemctl disable tmkms-01.v3.service
    sudo systemctl stop tmkms-02.v3.service
    sudo systemctl disable tmkms-02.v3.service
    sudo systemctl stop tmkms-03.v3.service
    sudo systemctl disable tmkms-03.v3.service
    ...
    ```
2. Starting in new services When the validator nodes will return to work the kms will immediately start providing the signing service.
    ```bash
    sudo systemctl enable tmkms-01.service
    sudo systemctl start tmkms-01.service
    sudo systemctl enable tmkms-02.service
    sudo systemctl start tmkms-02.service
    sudo systemctl enable tmkms-03.service
    sudo systemctl start tmkms-03.service
    ...
    ```

## Note

### Guide explanations

Other upgrade strategies may be chosen, but a specific path has been chosen in this guide. Anyone can adopt this guide or a personal procedure. 
Furthermore, the whole procedure was developed on the basis of a standard installation, with well-defined paths. 
It is believed that the kms managers are able to use the most suitable tools to carry out the updating activity.

### Common mistakes or doubts

1. The service returns a permissions error to me 
    The service is configured with the user tmkms, so any folder to which the service needs access for reading, but especially for writing, must be configured appropriately. 
    For example, if you act on the kms server as root all the time, you have to run the commands before starting the services

    ```bash
    sudo chown -R tmkms:tmks /data_tmkms/tmkms
    ```
    this command should fix any file access problems.
2. The `tmkms` tells me that it cannot reach the validator 
    Check that there are no network problems between the kms and the validator, eg. Vpn off, firewall or something like that. A simple ping should sufficient to check reachability. 
    Also check if the configuration in `config.toml` of the validator has changed by removing the value of `priv_validator_laddr`

3. Is it necessary to change the service `yubihsm-connector`? 
    It is **not** necessary to update the yubi service. 
    If you want you can try new software updates from the yubi website

    https://developers.yubico.com/YubiHSM2/Releases/

4. Is it necessary to update `tmkms` software?
    The newest version `0.10.1` adds only documentation and leaves immutate the software.     
    Versions `0.11.x` are in prerelease.
