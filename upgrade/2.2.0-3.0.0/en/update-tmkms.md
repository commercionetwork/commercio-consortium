# KMS

This section shows how to update yubihsm and tmkms based kms with single key. 
**It should be noted that these are guidelines, and it is essential to understand the process summarized here**

Everything can be prepared in advance: already prepare the files with the updated configurations so that at the moment of the chain upgrade the only thing to do is to stop the services and replace the configurations. The previous configurations can then be saved in order to be able to recover them quickly in case of problems.
Some details on the different configurations can be found on **this page**


## Update configurations

**The kms configurations can be updated even before the chain upgrade procedure.** 
This section explains the setup to perform even before updating the chain.      
We assume that you run `tmkms` version **0.10**

1. Create new configurations. The new configuration must be created for compatibility with the new software version. In this phase you can directly prepared configuration compatible with the core version `v3.0.0` of Commercio.Network chain.
   On this guide we will directly prepare the configuration for the version `v3.0.0` on which the service always prepared for the version will draw `v3.0.0`.

   In the single key configuration you will have a single configuration. Assuming that the configuration is contained in the folder `/data_tmkms/tmkms/kms/commercio` (each manager will have its own path).

   The configuration `/data_tmkms/tmkms/kms/commercio/tmkms.toml` should look like this

   ```toml
    [[chain]]
    id = "commercio-2_2"
    key_format = { type = "bech32", account_key_prefix = "did:com:", consensus_key_prefix = "did:com:valconspub" }
    state_file = "/data_tmkms/tmkms/kms/commercio/commercio_priv_validator_state.json"

    [[validator]]
    addr = "tcp://10.1.1.1:26658"
    chain_id = "commercio-2_2"
    reconnect = true
    secret_key = "/data_tmkms/tmkms/kms/commercio/secret_connection.key"
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

    **ATTENTION**

    ```toml
    [[ providers . yubihsm ]]
    adapter = { type = " http " , addr = " tcp: //127.0.0.1: 12345 " }
    ```

    It could be instead

    ```toml
    [[ providers . yubihsm ]]
    adapter = { type = " usb " }
    ```

    Make changes accordingly

    Create the new configuration dedicated to the new chain `/data_tmkms/tmkms/kms/commercio/tmkms.v3.toml`

    ```toml
    [[chain]]
    id = "commercio-3"
    key_format = { type = "bech32", account_key_prefix = "did:com:", consensus_key_prefix = "did:com:valconspub" }
    state_file = "/data_tmkms/tmkms/kms/commercio/commercio_priv_validator_state.v3.json"

    [[validator]]
    addr = "tcp://10.1.1.1:26658"
    chain_id = "commercio-3"
    reconnect = true
    secret_key = "/data_tmkms/tmkms/kms/commercio/secret_connection.key"
    protocol_version = "v0.34"

    [[providers.yubihsm]]
    adapter = { type = "http", addr = "tcp://127.0.0.1:12345" }
    auth = { key = 1, password_file = "/data_tmkms/tmkms/kms/password" }
    keys = [{ chain_ids = ["commercio-3"], key = 1 }] 
    serial_number = "9876543210"
    ```

2. Create the new service. Assuming you have the service
    ```
    /etc/systemd/system/tmkms.service
    ...
    ```
    with these configurations

    ```ini
    [Unit]
    Description=Commercio tmkms
    After=network.target

    [Service]
    User=tmkms
    WorkingDirectory=/data_tmkms/tmkms/.cargo/bin
    ExecStart=/data_tmkms/tmkms/.cargo/bin/tmkms start -c /data_tmkms/tmkms/kms/commercio/tmkms.toml
    Restart=always
    SyslogIdentifier=tmkms
    RestartSec=3
    LimitNOFILE=4096

    [Install]
    WantedBy=multi-user.target
    ```


    ```
    /etc/systemd/system/tmkms.v3.service
    ...
    ```
    with these configurations

    ```ini
    [Unit]
    Description=Commercio tmkms
    After=network.target

    [Service]
    User=tmkms
    WorkingDirectory=/data_tmkms/tmkms/.cargo/bin
    ExecStart=/data_tmkms/tmkms/.cargo/bin/tmkms start -c /data_tmkms/tmkms/kms/commercio/tmkms.v3.toml
    Restart=always
    SyslogIdentifier=tmkms
    RestartSec=3
    LimitNOFILE=4096

    [Install]
    WantedBy=multi-user.target
    ```

## Chain update


This section discusses the procedure to be followed when the core of the chain is updated on the validator node.

1. Make sure the validator node is turned off. The validator connected to the kms must be stopped. If necessary, execute the command on the validator node
   ```bash
   sudo systemctl stop cnd # Old service
   sudo systemctl stop commercionetworkd # New service: should be already stopped
   ```
2. Stop the tmkms service Stop and disable the service in the kms
    ```bash
    sudo systemctl stop tmkms.service
    sudo systemctl disable tmkms.service
    ```
3. Get height of chain
    ```bash
    cat /data_tmkms/tmkms/kms/commercio/commercio_priv_validator_state.json  | jq -r '.height'
    ```
    Use this value to compare with all other validators.
    **NB**: you need `jq` program insalled in your kms. Use `sudo apt install jq` to install it


4. Starting the new service This phase can be launched regardless of the validator node activity. 
    As soon as the validator node starts working again, kms will immediately start providing the signing service.
    ```bash
    sudo systemctl enable tmkms.v3.service
    sudo systemctl start tmkms,v3.service
    ```
    Analyzing the logs with the command journalctlit should be possible to see that the tmkms cannot reach the validator node because it is switched off.
    ```bash
    sudo journalctl -u tmkms.v3 -f
    ```
    When the node is reactivated with
    ```bash
    sudo systemctl start commercionetworkd # New service: should be stopped
    ``` 
    the signing should restart regularly

## Restore in case of update problems

If the chain update fails, follow this procedure

1. Stop the service `tmkms.v3` Stop and disable the service in the kms
   ```bash
    sudo systemctl stop tmkms.v3.service
    sudo systemctl disable tmkms.v3.service
    ```
2. Starting the previous service. When the validator node is back to work the kms will immediately start providing the signing service.
    ```bash
    sudo systemctl enable tmkms.service
    sudo systemctl start tmkms.service
    ```

## Note

### Guide explanations

Other upgrade strategies may be chosen, but a specific path has been chosen in this guide. 
Anyone can adopt this guide or a personal procedure. 
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
