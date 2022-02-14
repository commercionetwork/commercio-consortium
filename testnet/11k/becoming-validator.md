# Becoming a validator (WIP)
Once you've properly set up a [full node](full-node-installation.md), your node is ready to become a validator. 

Before you start, we recommend you to run this command 

```bash
commercionetworkd config chain-id $CHAINID
```

In this way you can omit the flag `--chain-id="$CHAINID"` in every line of the **commercionetworkd**

## Requirements
The requirements are:

1. Be a full node.  
   If you are not, please follow the [full node installation guide](full-node-installation.md).
   
2. Own enough tokens.  
   To become a validator you need a wallet with at least 2 tokens (COM) to create the validator.

:::tip  
If you have any problem with the procedure try to read the section **[Common errors](#_common-errors)**.   
:::

## 1. Add wallet key
Inside the testnet you can use the **Ledger**, but you can also use the wallet software with the `commercionetworkd`.     
However, if you wish to use **Ledger**, please add the `--ledger` option to every command.

:::warning  
Please remember to copy the 24 words seed phrase in a secure place.  
They are your mnemonic and if you loose them you lose all your tokens and the whole access to your validator.  
:::

Create the first wallet with the following command
```bash
commercionetworkd keys add $NODENAME
# Enter a password you can remember
```
The output of the command will provide the 24 words. Those words are your mnemonic.    

If you are using the **Ledger** device you must first connect it to your computer, start the cosmos application and run the command 
```bash
commercionetworkd keys add $NODENAME --ledger
# Enter a password you can remember
```
In this case the 24 words are not provided because they have already been configured in the **Ledger** initialization

Copy your public address. It should have the format `did:com:<data>`.
 
**ATTENTION**: from now on we will refer to the value of your public address of the first wallet as `<your pub addr creator val>` notation.   

## 2. Make sure you have tokens

To make sure you have enough tokens (just 2 COM are required), query your account running this command:
```bash
commercionetworkd query account <your pub addr creator val> --chain-id $CHAINID
```

The output should look like this:
```
- denom: ucommercio
  amount: "2000000"
```

:::warning 
If you don't have enough tokens you have to request them.
:::

Read [Add wallet key](#1-add-wallet-key) to create your own `<your pub addr creator val>`.

## 3. Create a validator
Once you have the tokens, you can create a validator. If you want, while doing so you can also specify the following parameters
* `--moniker`: the name you want to assign to your validator. Spaces and special characters are accepted
* `--details`: a brief description about your node or your company
* `--identity`: your [Keybase](https://keybase.io) identity
* `--website`: a public website of your node or your company

Set your validator public key:
```bash
export VALIDATOR_PUBKEY=$(commercionetworkd tendermint show-validator)
```

Create your validator
```bash
commercionetworkd tx staking create-validator \
  --amount=10000ucommercio \
  --pubkey=$VALIDATOR_PUBKEY \
  --moniker="$NODENAME" \
  --chain-id="$CHAINID" \
  --identity="" \
  --website="" \
  --details="" \
  --commission-rate="0.10" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1" \
  --from=<your pub addr creator val> \
  --fees=10000ucommercio \
  -y
##Twice input password required
```

The output should look like this:
```
height: 0
txhash: C41B87615308550F867D42BB404B64343CB62D453A69F11302A68B02FAFB557C
codespace: ""
code: 0
data: ""
rawlog: '[]'
logs: []
info: ""
gaswanted: 0
gasused: 0
tx: null
timestamp: ""
```

## 4. Delegate tokens to the validator


### Confirm your validator is active
Please confirm that your validator is active by running the following command:

```bash
commercionetworkd query staking validators --chain-id $CHAINID | fgrep -B 1 $VALIDATOR_PUBKEY
```

The output should look like this:

```
  operatoraddress: did:com:valoper1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  conspubkey: did:com:valconspub1zcjduepq592mn5xucyqvfrvjegruhnx15rruffkrfq0rryu809fzkgwg684qmetxxs
```

Copy the value of `operatoraddress`.

You can also verify that the validator is active by browsing 

[Commercio.network explorer Testnet](https://testnet.commercio.network/it/validators).       


If you see your validator in the list click on its name.     
The validator tab should have the value **Operator**. That value is your `operatoraddress`       

Register the value of `operatoraddress`.

```bash
export OPERATOR_ADDRESS="did:com:valoper1zcjx15rruffkrfq0rryu809fzkgwg684qmetxxs"
```

### Delegate tokens

If you want to stake tokens from another wallet you can register it using the following command:

```bash
commercionetworkd keys add <name of second wallet> --recover
```
where `<name of second wallet>` is an arbitrary name.   
When requested, the 24 keywords must be entered


If you are using the **Ledger** device you must first connect it to your computer, start the cosmos application and run the command 
```bash
commercionetworkd keys add <name of second wallet> --ledger
# Enter a password that you can remember
```
In this case the 24 words are not provided because they have already been configured in the **Ledger** initialization

When you're ready you can delegate your token to the validator using this command:

```bash
commercionetworkd tx staking delegate \
  $OPERATOR_ADDRESS \
  <amount of tokens>ucommercio \
  --from <your pub addr delegator> \
  --chain-id="$CHAINID" \
  --fees=10000ucommercio \
  -y
```

The output should look like this:
```
height: 0
txhash: 027B85834DA5486085BC56FFD2759443EFD3101BD1023FA9A681262E5C85A845
codespace: ""
code: 0
data: ""
rawlog: '[]'
logs: []
info: ""
gaswanted: 0
gasused: 0
tx: null
timestamp: ""
```

**Testnet** You should now see your validator with your token staked tokens inside the [Commercio.network explorer testnet](https://testnet.commercio.network)

## Note 

If you want to make transactions with the **Nano Ledger** from another machine a full node must be created locally or a full node must be configured to accept remote connections.   
Edit the `.commercionetworkd/config/config.toml` file by changing from 

```
laddr = "tcp://127.0.0.1:26657"
```
to
```
laddr = "tcp://0.0.0.0:26657"
```

and restart your node
```bash
systemctl restart commercionetworkd
```

and use the transaction this way

```bash
commercionetworkd tx staking delegate \
  $OPERATOR_ADDRESS \
  <amount of tokens>ucommercio \
  --from <your pub addr delegator> \
  --chain-id="$CHAINID" \
  --fees=10000ucommercio \
  -y
```

## Common errors

### Account does not exists

#### Problem
If I try to search for my address with the command 

```bash
commercionetworkd query account <my account> --chain-id $CHAINID
```

returns the message
```
ERROR: unknown address: account <my account> does not exist
```
#### Solution

Check if your node has completed the sync.
On https://testnet.commercio.network you can view the height of the chain at the current state

Use the command 
```bash
journalctl -u commercionetworkd -f | fgrep "committed state"
```
to check the height your node has reached.

### Failed validator creation

#### Problem

I executed the validator [creation transaction](#_3-create-a-validator) but I don't appear in validators explorer page.

#### Solution

It may be that by failing one or more transactions the tokens are not sufficient to execute the transaction.

Send more funds to your `<your pub addr creator val>` and repeat the validator creation transaction

### DB errors

#### Problem

Trying to start the rest server or query the chain I get this error
```
panic: Error initializing DB: resource temporarily unavailable
```

#### Solution

Maybe `commercionetworkd` service has been left active.
Use the following commands 

```bash
systemctl stop commercionetworkd
pkill -9 commercionetworkd
```

and repeat the procedure.