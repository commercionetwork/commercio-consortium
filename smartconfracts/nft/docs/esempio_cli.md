# Esmpio trattamento NFT con CLI in DEVNET

## Compilazione

```bash
cd
git clone https://github.com/CosmWasm/cw-nfts.git
cd $HOME/cw-nfts/contracts/cw721-base/
RUSTFLAGS="-C link-arg=-s" cargo build --release --target=wasm32-unknown-unknown --locked
```

Se si vuole i metadata in chain si può compilare il contratto relativo

```bash
cd
cd $HOME/cw-nfts/contracts/cw721-metadata-onchain/
RUSTFLAGS="-C link-arg=-s" cargo build --release --target=wasm32-unknown-unknown --locked
```

## Upload

:warning: : **Solo il wallet di governo può eseguire l'upload del codice del contratto**

```bash
WASM_CONTRACT="$HOME/cw-nfts/target/wasm32-unknown-unknown/release/cw721_base.wasm"
CHAINID="commercio-devnet09"
WALLET_CREATOR="did:com:19fe4e45jakkwcf7ysajf3zqekd982a66zl4a6u"
HOME_CHAIN="$HOME/.commercionetwork"
KEYRING_BACKEND="file"

commercionetworkd tx wasm store \
  $WASM_CONTRACT \
  --from $WALLET_CREATOR \
  --keyring-backend $KEYRING_BACKEND \
  --home $HOME_CHAIN \
  --fees 100000000ucommercio \
  --chain-id $CHAINID \
  --gas 50000000 -y

WASM_CONTRACT="$HOME/cw-nfts/target/wasm32-unknown-unknown/release/cw721_metadata_onchain.wasm"

commercionetworkd tx wasm store \
  $WASM_CONTRACT \
  --from $WALLET_CREATOR \
  --keyring-backend $KEYRING_BACKEND \
  --home $HOME_CHAIN \
  --fees 100000000ucommercio \
  --chain-id $CHAINID \
  --gas 50000000 -y
```

Recupere il code id. L'id del codice in devnet per i contratti nft base è `8`, mentre per i metadata in chain è `9`.


## Istanziazione

Schema di inizializzazione contratto

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "InstantiateMsg",
  "type": "object",
  "required": [
    "minter",
    "name",
    "symbol"
  ],
  "properties": {
    "minter": {
      "description": "The minter is the only one who can create new NFTs. This is designed for a base NFT that is controlled by an external program or contract. You will likely replace this with custom logic in custom NFTs",
      "type": "string"
    },
    "name": {
      "description": "Name of the NFT contract",
      "type": "string"
    },
    "symbol": {
      "description": "Symbol of the NFT contract",
      "type": "string"
    }
  }
}
```

Il messaggio da inviare

```bash
NFT_CONTRACT_ID=8 # Cambiare in 9 se si voglioni i metadati in chain
MINTER="did:com:1cjnpack2jqngdhj9cap23h4n3dmxcvqswgyrlc" # Cambiare con un wallet proprietario
INIT_MSG='{"minter": "'$MINTER'", "name": "First NFT XYZ", "symbol": "FNX"}'
WALLET_CREATOR_NFT=$WALLET_CREATOR # Cambiare con un altro wallet di proprietà

commercionetworkd tx wasm instantiate \
  $NFT_CONTRACT_ID "$INIT_MSG" \
  --label "FirstNFTxyz" \
  --admin "$MINTER" \
  --from "$WALLET_CREATOR_NFT" \
  --fees 10000ucommercio \
  --keyring-backend $KEYRING_BACKEND \
  --home $HOME_CHAIN \
  --chain-id $CHAINID \
  -o json -b block \
  --gas 50000000 -y > init_nft_xyz_contract.json

NFT_CONTRACT_ADDRESS=$(jq -r '.logs[0].events[0].attributes[0].value' init_nft_xyz_contract.json)

```

## Minting

A questo punto è possibile fare il minting. Esempio di messaggio

```json
{
  "token_id": "00001",
  "owner": "did:com:1cjnpack2jqngdhj9cap23h4n3dmxcvqswgyrlc",
  "extension": {
    "name": "Monaliza bgr",
    "image": "https://i.ibb.co/4KPVGB1/monaliza-bgr.png",
    "image_data": null,
    "attributes": [
        {
          "trait_type": "shasum256", 
          "value": "1d5cbc9b95504aec6249470cedb5731cc0ff171fea1bc83df36669ca3f7baf0e"
        },
        {
          "trait_type": "base", 
          "value": "Monalisa" 
        },
        {
          "trait_type": "background", 
          "value": "black"
        },
        {
          "trait_type": "dress", 
          "value": "green"
        },
        {
          "trait_type": "eyes", 
          "value": "red"
        }
    ],
    "external_url": null,
    "description":null,
    "background_color": null,
    "animation_url": null,
    "youtube_url": null
  }
}
```

I campi obbligatori sono 

- token_id: è l'identificatore unico dell'nft. Ogni NFT all'interno della collezione istanziata deve avere un id unico. Tipo string
- owner: indica il proprietario dell'NFT. Tipo string

Campi facoltativi

- extension: è uno schema conforme allo standard dei metadati per l'ERC721. Se si usa l'nft contratto base i dati non verranno registrati
- token_uri: Identificatore di risorsa universale per questo NFT Deve puntare a un file JSON che dovrebbe essere conforme allo schema JSON dei metadati ERC721. Eventualmente potrebbe anche essere uno schema libero.


```bash
MINT_NFT='{"mint":{"token_id":"00001","owner":"did:com:1cjnpack2jqngdhj9cap23h4n3dmxcvqswgyrlc","extension":{"name":"Monaliza bgr","image":"https://i.ibb.co/4KPVGB1/monaliza-bgr.png","image_data":null,"attributes":[{"trait_type":"shasum256","value":"1d5cbc9b95504aec6249470cedb5731cc0ff171fea1bc83df36669ca3f7baf0e"},{"trait_type":"base","value":"Monalisa"},{"trait_type":"background","value":"black"},{"trait_type":"dress","value":"green"},{"trait_type":"eyes","value":"red"}],"external_url":null,"description":null,"background_color":null,"animation_url":null,"youtube_url":null},"token_uri":""}}'

commercionetworkd tx wasm execute $NFT_CONTRACT_ADDRESS "$MINT_NFT" \
  --from $MINTER \
  --fees 10000ucommercio \
  --keyring-backend $KEYRING_BACKEND \
  --home $HOME_CHAIN \
  --chain-id $CHAINID \
  -o json -b block \
  --gas 300000 -y
```

La transazione restiuisce

```json
{
  "height": "6067682",
  "txhash": "FC32477ACC137CE6FF51398FB1019DED3D0386585C184F3B0614AB9394980A68",
  "codespace": "",
  "code": 0,
  "data": "0A260A242F636F736D7761736D2E7761736D2E76312E4D736745786563757465436F6E7472616374",
  ....
}
```
[Risposta completa](./mint_response.json)



Un secondo nft con stesso ID 

```bash

MINT_NFT='{"mint":{"token_id":"00001","owner":"did:com:1cjnpack2jqngdhj9cap23h4n3dmxcvqswgyrlc","extension":{"name":"Monaliza bgr","image":"https://i.ibb.co/4KPVGB1/monaliza-xxx.png","image_data":null,"attributes":[{"trait_type":"shasum256","value":"xxxx"},{"trait_type":"base","value":"Monalisa"},{"trait_type":"background","value":"black"},{"trait_type":"dress","value":"green"},{"trait_type":"eyes","value":"red"}],"external_url":null,"description":null,"background_color":null,"animation_url":null,"youtube_url":null},"token_uri":""}}'

commercionetworkd tx wasm execute $NFT_CONTRACT_ADDRESS "$MINT_NFT" \
  --from $MINTER \
  --fees 10000ucommercio \
  --keyring-backend $KEYRING_BACKEND \
  --home $HOME_CHAIN \
  --chain-id $CHAINID \
  -o json -b block \
  --gas 300000 -y

```

Restituisce errore `failed to execute message; message index: 0: token_id already claimed: execute wasm contract failed`

Eseguo il mint con un utente differente dal minter

```bash

MINT_NFT='{"mint":{"token_id": "00002", "owner": "did:com:1cjnpack2jqngdhj9cap23h4n3dmxcvqswgyrlc", "extension":{"name":"Monaliza bgr","image":"https://i.ibb.co/4KPVGB1/monaliza-xxx.png","image_data":null,"attributes":[{"trait_type":"shasum256","value":"xxxx"},{"trait_type":"base","value":"Monalisa"},{"trait_type":"background","value":"black"},{"trait_type":"dress","value":"green"},{"trait_type":"eyes","value":"red"}],"external_url":null,"description":null,"background_color":null,"animation_url":null,"youtube_url":null},"token_uri":""}}'

commercionetworkd tx wasm execute $NFT_CONTRACT_ADDRESS "$MINT_NFT" \
  --from $WALLET_CREATOR \
  --fees 10000ucommercio \
  --keyring-backend $KEYRING_BACKEND \
  --home $HOME_CHAIN \
  --chain-id $CHAINID \
  -o json -b block \
  --gas 300000 -y

```

Restituisce errore `failed to execute message; message index: 0: Unauthorized: execute wasm contract failed`


Attribuisco il proprietario a un altro wallet

```bash

MINT_NFT='{"mint":{"token_id": "00020", "owner": "'$WALLET_CREATOR'", 
"extension":{"name":"Monaliza bbb","image":"https://i.ibb.co/G9z2M6L/monaliza-bbb.png","image_data":null,"attributes":[{"trait_type":"shasum256","value":"bb0c57fb8414cfe5fb03fcdf7167501291b52fec8729ae4132f660c2eb2c306b"},{"trait_type":"base","value":"Monalisa"},{"trait_type":"background","value":"black"},{"trait_type":"dress","value":"blue"},{"trait_type":"eyes","value":"brown"}],"external_url":null,"description":null,"background_color":null,"animation_url":null,"youtube_url":null},"token_uri":""}}'

commercionetworkd tx wasm execute $NFT_CONTRACT_ADDRESS "$MINT_NFT" \
  --from $MINTER \
  --fees 10000ucommercio \
  --keyring-backend $KEYRING_BACKEND \
  --home $HOME_CHAIN \
  --chain-id $CHAINID \
  -o json -b block \
  --gas 300000 -y
```

La transazione restituisce

```json
{
  "height": "6067749",
  "txhash": "0D708719B37AF70D1EAAA2C1CCBF67DFC37FAB799174F09C4F35672EA312C760",
  "codespace": "",
  "code": 0,
  "data": "0A260A242F636F736D7761736D2E7761736D2E76312E4D736745786563757465436F6E7472616374",
  ...
}
```
[Risposta completa](./mint_response2.json)

## Trasferimento di proprietà

```bash
TRANSFER_NFT='{"transfer_nft":{"recipient":"did:com:1cjnpack2jqngdhj9cap23h4n3dmxcvqswgyrlc","token_id": "00020"}}'

commercionetworkd tx wasm execute $NFT_CONTRACT_ADDRESS "$TRANSFER_NFT" \
  --from $WALLET_CREATOR \
  --fees 10000ucommercio \
  --keyring-backend $KEYRING_BACKEND \
  --home $HOME_CHAIN \
  --chain-id $CHAINID \
  -o json -b block \
  --gas 300000 -y

```

Ritorna

```json
{
  "height": "6067991",
  "txhash": "995C7A525FDFC3267B06271DD070065E4083313799BA44964CC02F91D6C8D14B",
  "codespace": "",
  "code": 0,
  "data": "0A260A242F636F736D7761736D2E7761736D2E76312E4D736745786563757465436F6E7472616374",
...
```
[Risposta completa](./transfer_response.json)


## Recupero informazioni sull'NFT

### Informazione sul token

```bash
commercionetworkd query wasm contract-state smart $NFT_CONTRACT_ADDRESS '{"nft_info":{"token_id":"00002"}}' -o json
```

Esempio risposta

```json
{
  "data": {
    "token_uri": "",
    "extension": {
      "image": "https://i.ibb.co/G9z2M6L/monaliza-bbb.png",
      "image_data": null,
      "external_url": null,
      "description": null,
      "name": "Monaliza bbb",
      "attributes": [
        {
          "display_type": null,
          "trait_type": "shasum256",
          "value": "bb0c57fb8414cfe5fb03fcdf7167501291b52fec8729ae4132f660c2eb2c306b"
        },
        { "display_type": null, "trait_type": "base", "value": "Monalisa" },
        { "display_type": null, "trait_type": "background", "value": "black" },
        { "display_type": null, "trait_type": "dress", "value": "blue" },
        { "display_type": null, "trait_type": "eyes", "value": "brown" }
      ],
      "background_color": null,
      "animation_url": null,
      "youtube_url": null
    }
  }
}

```

## Informazione Proprietario dell'NFT
```bash
commercionetworkd query wasm contract-state smart $NFT_CONTRACT_ADDRESS '{"owner_of":{"token_id":"00020"}}' -o json
```
Risposta
```json
{"data":{"owner":"did:com:19fe4e45jakkwcf7ysajf3zqekd982a66zl4a6u","approvals":[]}}
```

## Lista degli nft per un certo contratto

```bash
commercionetworkd query wasm contract-state smart $NFT_CONTRACT_ADDRESS '{"all_tokens":{}}' -o json
```
Risposta
```json
{"data":{"tokens":["00001","00010","00020"]}}
```