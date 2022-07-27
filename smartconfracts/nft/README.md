# commercioNFT


## Descrizione iniziale

Esistono vari tipi di nft nei contratti standard di cosmwasm. In generale vengono tenuti in considerazioni i seguenti

- Nft base con metadati su url esterno, `cw721-base`     
   L'nft si aspetta di avere i metadati registrati su un url esterno, ipfs, ar, s3 ecc., attraverso il parametro `token_uri`
- Nft con metadati in chain, `cw721-metadata-onchain`    
   L'nft si aspetta di avere i metadati registrati direttamente in chain, nel campo `extension`, senza escludere la possibilità di aggiungere metadati con il parametro `token_uri` esternamente. I metadati in chain seguno uno standard https://docs.opensea.io/docs/metadata-standards che riportiamo qui di seguito    
   | campo | descrizione |
   | --- | --- |
   | image | This is the URL to the image of the item. Can be just about any type of image (including SVGs, which will be cached into PNGs by OpenSea), and can be IPFS URLs or paths. We recommend using a 350 x 350 image. |
   | image_data | Raw SVG image data, if you want to generate images on the fly (not recommended). Only use this if you're not including the image parameter. |
   | external_url | This is the URL that will appear below the asset's image on OpenSea and will allow users to leave OpenSea and view the item on your site. |
   | description | A human readable description of the item. Markdown is supported. |
   | name | Name of the item. |
   | attributes | These are the attributes for the item, which will show up on the OpenSea page for the item. (see below) |
   | background_color | Background color of the item on OpenSea. Must be a six-character hexadecimal without a pre-pended #. |
   | animation_url | A URL to a multi-media attachment for the item. The file extensions GLTF, GLB, WEBM, MP4, M4V, OGV, and OGG are supported, along with the audio-only extensions MP3, WAV, and OGA. Animation_url also supports HTML pages, allowing you to build rich experiences and interactive NFTs using JavaScript canvas, WebGL, and more. Scripts and relative paths within the HTML page are now supported. However, access to browser extensions is not supported. |
   | youtube_url | A URL to a YouTube video. |

## Inserimento in devnet

In [questa pagina](docs/esempio_cli.md) è presente un percorso completo di queste fase

1. Compilazione contratto
2. Caricamento in chain
3. Instanziazione contratto
4. Mint nft
5. Trasferimento proprietario
6. Interrogazione delle informazioni dell'nft
7. Interrogazione del proprietario dell'nft
8. Lista degli nft per un certo contratto


## Invio messaggi alla chain

Si demanda alla documentazione generale https://scw-gitlab.zotsell.com/Commercio.network/smart-contracts/general i tipi di messaggio del modulo wasm e di come costruirli.

Per i metodi generali di firma e invio transazioni di demanda alla documentazione generale [REST e gRPC](https://docs.cosmos.network/v0.46/run-node/txs.html#using-rest)

Si citano per semplicità in breve i metodi

- `CLI`: Attraverso command line interface `commercionetworkd`
- `Rest`: Attraverso la costruzione del messaggio, e l'icapsulamento dello stesso all'interno di una transazione firmata. La transazione viene inviata all'uncio enpoint rest `/cosmos/tx/v1beta1/txs`
   Es.
   ```bash
   curl -X POST \
     -H "Content-Type: application/json" \
     -d'{"tx_bytes":"{{txBytes}}","mode":"BROADCAST_MODE_SYNC"}' \
     localhost:1317/cosmos/tx/v1beta1/txs
   ```

- `gRpc`: Attraverso la costruzione del messaggio, e l'icapsulamento dello stesso all'interno di una transazione firmata. La transazione viene inviata all'uncio enpoint `cosmos.tx.v1beta1.Service/BroadcastTx`
   Es.
   ```bash
   grpcurl -plaintext \
     -d '{"tx_bytes":"{{txBytes}}","mode":"BROADCAST_MODE_SYNC"}' \
     localhost:9090 \
     cosmos.tx.v1beta1.Service/BroadcastTx
   ```

## Metodo istantiate

Riferirsi alla documentazione generale del modulo `wasm` per l'invio di messaggi.     

Il messaggio viene utilizzato per istanziare una tipologia di NFT.      
**Json Schema definition**
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
**Campi**

- `minter`: L'unico che potrà creare gli nft. In fase di mint potrà assegnare il proprietario dell'nft
- `name`: Nome del contratto NFT
- `symbol`: Simbolo del contratto NFT

**Esempio messaggio**
```json
{
    "minter": "did:com:1cjnpack2jqngdhj9cap23h4n3dmxcvqswgyrlc",
    "name": "First NFT XYZ",
    "symbol": "FNX"
}
```


## Metodi execute di interazione con il contratto


### Mint

**Descrizione**

Esegue il mint di un nft

**Json Schema definition**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ExecuteMsg",
  "description": "This is like Cw721ExecuteMsg but we add a Mint command for an owner to make this stand-alone. You will likely want to remove mint and use other control logic in any contract that inherits this.",
  "oneOf": [
    ...
    {
      "description": "Mint a new NFT, can only be called by the contract minter",
      "type": "object",
      "required": [
        "mint"
      ],
      "properties": {
        "mint": {
          "$ref": "#/definitions/MintMsg_for_Nullable_Empty"
        }
      },
      "additionalProperties": false
    },
    ...
  ],
    ...
    "MintMsg_for_Nullable_Empty": {
      "type": "object",
      "required": [
        "owner",
        "token_id"
      ],
      "properties": {
        "extension": {
          "description": "Any custom extension used by this contract",
          "anyOf": [
            {
              "$ref": "#/definitions/Empty"
            },
            {
              "type": "null"
            }
          ]
        },
        "owner": {
          "description": "The owner of the newly minter NFT",
          "type": "string"
        },
        "token_id": {
          "description": "Unique ID of the NFT",
          "type": "string"
        },
        "token_uri": {
          "description": "Universal resource identifier for this NFT Should point to a JSON file that conforms to the ERC721 Metadata JSON Schema",
          "type": [
            "string",
            "null"
          ]
        }
      }
    },
    ...
  }
}
```

**Campi**

- `token_id`: è l'identificatore unico dell'nft. Ogni NFT all'interno della collezione istanziata deve avere un id unico. Tipo string
- `owner`: indica il proprietario dell'NFT. Tipo string
- `extension`: è uno schema conforme allo standard dei metadati per l'ERC721. Se si usa l'nft contratto base i dati non verranno registrati. Vedi documentazione iniziale sullo schema dei metadata.
- `token_uri`: Identificatore di risorsa universale per questo NFT Deve puntare a un file JSON conforme al JSON dei metadati ERC721. 




**Esempio di messaggio**

```json
{
    "mint": {
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
}
```



### Transfer

**Descrizione**

Trasferisce la proprietà di un NFT da un account ad un altro

**Json Schema definition**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ExecuteMsg",
  "description": "This is like Cw721ExecuteMsg but we add a Mint command for an owner to make this stand-alone. You will likely want to remove mint and use other control logic in any contract that inherits this.",
  "oneOf": [
    ...
    {
      "description": "Transfer is a base message to move a token to another account without triggering actions",
      "type": "object",
      "required": [
        "transfer_nft"
      ],
      "properties": {
        "transfer_nft": {
          "type": "object",
          "required": [
            "recipient",
            "token_id"
          ],
          "properties": {
            "recipient": {
              "type": "string"
            },
            "token_id": {
              "type": "string"
            }
          }
        }
      },
      "additionalProperties": false
    },
    ...
  ],
  }
}
```


**Campi**

- `recipient`: Indica chi deve ricevere l'NFT
- `token_id`: Indica l'id dell'NFT da trasferire

**Esempio di messaggio**

```json
{
    "transfer_nft": {
        "recipient": "did:com:1cjnpack2jqngdhj9cap23h4n3dmxcvqswgyrlc",
        "token_id": "00001"
    }
}
```




### Send

Manda un NFT dal contratto originale a un altro. Il contratto ricevente deve avere un metodo reciver

**Json Schema definition**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ExecuteMsg",
  "description": "This is like Cw721ExecuteMsg but we add a Mint command for an owner to make this stand-alone. You will likely want to remove mint and use other control logic in any contract that inherits this.",
  "oneOf": [
    ...
    {
      "description": "Send is a base message to transfer a token to a contract and trigger an action on the receiving contract.",
      "type": "object",
      "required": [
        "send_nft"
      ],
      "properties": {
        "send_nft": {
          "type": "object",
          "required": [
            "contract",
            "msg",
            "token_id"
          ],
          "properties": {
            "contract": {
              "type": "string"
            },
            "msg": {
              "$ref": "#/definitions/Binary"
            },
            "token_id": {
              "type": "string"
            }
          }
        }
      },
      "additionalProperties": false
    },
    ...
  ],
  }
}
```




**Campi**

- `recipient`: Indica chi deve ricevere l'NFT
- `msg`: Messaggio da far eseguire al contratto ricevente. Dipende dal contratto a cui viene inviato l'NFT. Il messaggio deve essere espresso in binario. Dovrebbe essere in base64.
- `token_id`: Indica l'id dell'NFT da trasferire

**Esempio di messaggio**

```json
{
    "send_nft": {
        "recipient": "did:com:1cjnpack2jqngdhj9cap23h4n3dmxcvqswgyrlc",
        "msg": "ewogICAgInNlbmRfbmZ0IjogewogICAgICAgICJyZWNpcGllbnQiOiAiZGlkOmNvbToxY2pucGFjazJqcW5nZGhqOWNhcDIzaDRuM2RteGN2cXN3Z3lybGMiLAogICAgICAgICJtc2ciOiAiIiwKICAgICAgICAidG9rZW5faWQiOiAiMDAwMDEiCiAgICB9Cn0=",
        "token_id": "00001"
    }
}
```



### Burn

**Descrizione**

Permette di bruciare (cancellare) un NFT

**Json Schema definition**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ExecuteMsg",
  "description": "This is like Cw721ExecuteMsg but we add a Mint command for an owner to make this stand-alone. You will likely want to remove mint and use other control logic in any contract that inherits this.",
  "oneOf": [
    ...
    {
      "description": "Burn an NFT the sender has access to",
      "type": "object",
      "required": [
        "burn"
      ],
      "properties": {
        "burn": {
          "type": "object",
          "required": [
            "token_id"
          ],
          "properties": {
            "token_id": {
              "type": "string"
            }
          }
        }
      },
      "additionalProperties": false
    }
    ...
  ],
  }
}
```

**Campi**

- `token_id`: Indica l'id dell'NFT da bruciare

**Esempio di messaggio**

```json
{
    "burn": {
        "token_id": "00001"
    }
}
```



### Approve

WIP
**Descrizione**


**Json Schema definition**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ExecuteMsg",
  "description": "This is like Cw721ExecuteMsg but we add a Mint command for an owner to make this stand-alone. You will likely want to remove mint and use other control logic in any contract that inherits this.",
  "oneOf": [
    ...

    ...
  ],
  }
}
```

**Campi**


**Esempio di messaggio**

```json
{

}
```
### Revoke

WIP
**Descrizione**


**Json Schema definition**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ExecuteMsg",
  "description": "This is like Cw721ExecuteMsg but we add a Mint command for an owner to make this stand-alone. You will likely want to remove mint and use other control logic in any contract that inherits this.",
  "oneOf": [
    ...

    ...
  ],
  }
}
```

**Campi**


**Esempio di messaggio**

```json
{

}
```

### Approve all


WIP


**Descrizione**

Allows operator to transfer / send any token from the owner's account. If expiration is set, then this allowance has a time/height limit

approve_all

**Json Schema definition**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ExecuteMsg",
  "description": "This is like Cw721ExecuteMsg but we add a Mint command for an owner to make this stand-alone. You will likely want to remove mint and use other control logic in any contract that inherits this.",
  "oneOf": [
    ...

    ...
  ],
  }
}
```

**Campi**


**Esempio di messaggio**

```json
{

}
```



### Revoke all

revoke_all


WIP

**Descrizione**

revoke_all

**Json Schema definition**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ExecuteMsg",
  "description": "This is like Cw721ExecuteMsg but we add a Mint command for an owner to make this stand-alone. You will likely want to remove mint and use other control logic in any contract that inherits this.",
  "oneOf": [
    ...

    ...
  ],
  }
}
```

**Campi**


**Esempio di messaggio**

```json
{

}
```



## Metodi query di interazione con il contratto


### Proprietario di un certo NFT (owner_of)


**Json Schema definition**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "QueryMsg",
  "oneOf": [
    {
      "description": "Return the owner of the given token, error if token does not exist Return type: OwnerOfResponse",
      "type": "object",
      "required": [
        "owner_of"
      ],
      "properties": {
        "owner_of": {
          "type": "object",
          "required": [
            "token_id"
          ],
          "properties": {
            "include_expired": {
              "description": "unset or false will filter out expired approvals, you must set to true to see them",
              "type": [
                "boolean",
                "null"
              ]
            },
            "token_id": {
              "type": "string"
            }
          }
        }
      },
      "additionalProperties": false
    },
    ...
  ]
}
```

**Campi**

- `token_id`: Indica l'id dell'NFT di cui si vuole conoscere il proprietario

**Esempio di messaggio**

```json
{
    "owner_of": {
        "token_id": "00001"
    }
}
```

**Esempio risposta**
```json
{
    "data":{
        "owner":"did:com:19fe4e45jakkwcf7ysajf3zqekd982a66zl4a6u",
        "approvals":[]
    }
}
```


### Approval (approval)

WIP

**Json Schema definition**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "QueryMsg",
  "oneOf": [
    ...
    {
      "description": "Return operator that can access all of the owner's tokens. Return type: `ApprovalResponse`",
      "type": "object",
      "required": [
        "approval"
      ],
      "properties": {
        "approval": {
          "type": "object",
          "required": [
            "spender",
            "token_id"
          ],
          "properties": {
            "include_expired": {
              "type": [
                "boolean",
                "null"
              ]
            },
            "spender": {
              "type": "string"
            },
            "token_id": {
              "type": "string"
            }
          }
        }
      },
      "additionalProperties": false
    },
    ...
  ]
}
```

**Campi**

- `token_id`: Indica l'id dell'NFT di cui si vuole conoscere l'approval
- `spender`: Indica se lo spender è approvato ???

**Esempio di messaggio (??)**

```json
{
    "approval": {
        "spender": "did:com:19fe4e45jakkwcf7ysajf3zqekd982a66zl4a6u",
        "token_id": "00001"
    }
}
```

**Esempio risposta (??)**
```json
{
    "data":{
        "approvals":[
            "expires": {
                "never": {}
            },
            "spender": "did:com:19fe4e45jakkwcf7ysajf3zqekd982a66zl4a6u"
        ]
    }
}
```


### Approvals (approvals)

WIP

**Json Schema definition**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "QueryMsg",
  "oneOf": [
    ...
    {
      "description": "Return approvals that a token has Return type: `ApprovalsResponse`",
      "type": "object",
      "required": [
        "approvals"
      ],
      "properties": {
        "approvals": {
          "type": "object",
          "required": [
            "token_id"
          ],
          "properties": {
            "include_expired": {
              "type": [
                "boolean",
                "null"
              ]
            },
            "token_id": {
              "type": "string"
            }
          }
        }
      },
      "additionalProperties": false
    },
    ...
  ]
}
```

**Campi**

- `token_id`: Indica l'id dell'NFT di cui si vuole conoscere gli approvals

**Esempio di messaggio (??)**

```json
{
    "approvals": {
        "token_id": "00001"
    }
}
```

**Esempio risposta (??)**
```json
{
    "data":{
        "approvals":[
            {
                "expires": {
                    "never": {}
                },
                "spender": "did:com:19fe4e45jakkwcf7ysajf3zqekd982a66zl4a6u"
            },
            {
                "expires": {
                   "at_height": 12345678
                },
                "spender": "did:com:1cjnpack2jqngdhj9cap23h4n3dmxcvqswgyrlc"
            },
            {
                "expires": {
                   "at_time": 1658168998
                },
                "spender": "did:com:1cjnpack2jqngdhj9cap23h4n3dmxcvqswgyrlc"
            }
        ]
    }
}
```

### Tutti gli operatori (??)

WIP

**Json Schema definition**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "QueryMsg",
  "oneOf": [
    ...
    {
      "description": "List all operators that can access all of the owner's tokens Return type: `OperatorsResponse`",
      "type": "object",
      "required": [
        "all_operators"
      ],
      "properties": {
        "all_operators": {
          "type": "object",
          "required": [
            "owner"
          ],
          "properties": {
            "include_expired": {
              "description": "unset or false will filter out expired items, you must set to true to see them",
              "type": [
                "boolean",
                "null"
              ]
            },
            "limit": {
              "type": [
                "integer",
                "null"
              ],
              "format": "uint32",
              "minimum": 0.0
            },
            "owner": {
              "type": "string"
            },
            "start_after": {
              "type": [
                "string",
                "null"
              ]
            }
          }
        }
      },
      "additionalProperties": false
    },
    ...
  ]
}
```

**Campi**

- `owner`: Indica l'id dell'NFT di cui si vuole conoscere gli approvals

**Esempio di messaggio (??)**

```json
{
    "all_operators": {
        "owner": "did:com:19fe4e45jakkwcf7ysajf3zqekd982a66zl4a6u"
    }
}
```


**Esempio risposta (??)**
```json
{
    "data":{
        "operators":[
            {
                "expires": {
                    "never": {}
                },
                "spender": "did:com:19fe4e45jakkwcf7ysajf3zqekd982a66zl4a6u"
            },
            {
                "expires": {
                   "at_height": 12345678
                },
                "spender": "did:com:1cjnpack2jqngdhj9cap23h4n3dmxcvqswgyrlc"
            },
            {
                "expires": {
                   "at_time": 1658168998
                },
                "spender": "did:com:1cjnpack2jqngdhj9cap23h4n3dmxcvqswgyrlc"
            }
        ]
    }
}
```

### Numero di token presenti per un certo smart contract MFT


**Json Schema definition**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "QueryMsg",
  "oneOf": [
    ...
    {
      "description": "Total number of tokens issued",
      "type": "object",
      "required": [
        "num_tokens"
      ],
      "properties": {
        "num_tokens": {
          "type": "object"
        }
      },
      "additionalProperties": false
    },    
    ...
  ]
}
```

**Campi**


**Esempio di messaggio (??)**

```json
{
    "num_tokens": {}
}
```


**Esempio risposta (??)**
```json
{
    "data":{
        "count": 3
    }
}
```


### Informazione sul token

**Json Schema definition**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "QueryMsg",
  "oneOf": [
    ...
    {
      "description": "With MetaData Extension. Returns metadata about one particular token, based on *ERC721 Metadata JSON Schema* but directly from the contract: `NftInfoResponse`",
      "type": "object",
      "required": [
        "nft_info"
      ],
      "properties": {
        "nft_info": {
          "type": "object",
          "required": [
            "token_id"
          ],
          "properties": {
            "token_id": {
              "type": "string"
            }
          }
        }
      },
      "additionalProperties": false
    },
    ...
  ]
}
```

**Campi**

- `token_id`: Indica l'id dell'NFT di cui si vuole conoscere il dettaglio. A seconda del tipo di NFT, se base o con metadata in chain, il campo extension risulterà vuoto o valorizzato.

**Esempio di messaggio**

```json
{
    "nft_info": {
        "token_id": "00001"
    }
}
```



**Esempio risposta**

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

### Più informazioni di un certo token


**Json Schema definition**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "QueryMsg",
  "oneOf": [
    ...
    {
      "description": "With MetaData Extension. Returns metadata about one particular token, based on *ERC721 Metadata JSON Schema* but directly from the contract: `NftInfoResponse`",
      "type": "object",
      "required": [
        "nft_info"
      ],
      "properties": {
        "nft_info": {
          "type": "object",
          "required": [
            "token_id"
          ],
          "properties": {
            "token_id": {
              "type": "string"
            }
          }
        }
      },
      "additionalProperties": false
    },
    ...
  ]
}
```

**Campi**

- `token_id`: Indica l'id dell'NFT di cui si vuole conoscere il dettaglio. A seconda del tipo di NFT, se base o con metadata in chain, il campo extension risulterà vuoto o valorizzato.

**Esempio di messaggio**

```json
{
    "nft_info": {
        "token_id": "00001"
    }
}
```



**Esempio risposta**

```json
{
  "data": {
    "access": {
      "owner": "did:com:19fe4e45jakkwcf7ysajf3zqekd982a66zl4a6u",
      "approvals": []
    },
    "info": {
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
          {
            "display_type": null,
            "trait_type": "background",
            "value": "black"
          },
          { "display_type": null, "trait_type": "dress", "value": "blue" },
          { "display_type": null, "trait_type": "eyes", "value": "brown" }
        ],
        "background_color": null,
        "animation_url": null,
        "youtube_url": null
      }
    }
  }
}
```


### NFT posseduti da un certo proprietario



**Json Schema definition**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "QueryMsg",
  "oneOf": [
    ...
    {
      "description": "With Enumerable extension. Returns all tokens owned by the given address, [] if unset. Return type: TokensResponse.",
      "type": "object",
      "required": [
        "tokens"
      ],
      "properties": {
        "tokens": {
          "type": "object",
          "required": [
            "owner"
          ],
          "properties": {
            "limit": {
              "type": [
                "integer",
                "null"
              ],
              "format": "uint32",
              "minimum": 0.0
            },
            "owner": {
              "type": "string"
            },
            "start_after": {
              "type": [
                "string",
                "null"
              ]
            }
          }
        }
      },
      "additionalProperties": false
    },
    ...
  ]
}
```

**Campi**

- `owner`: L'account di cui si vuole sapere il balance degli NFT.
- `limit`: FACOLTATIVO. Si può definire un limite nella visualizzazione degli NFT
- - `start_after`: FACOLTATIVO. Si può definire un limite nella visualizzazione degli NFT


**Esempio di messaggio**

```json
{
    "tokens": {
        "owner": "did:com:1cjnpack2jqngdhj9cap23h4n3dmxcvqswgyrlc"
    }
}
```



**Esempio risposta**

```json
{
  "data": {
    "tokens": [
        "00001",
        "00002"
    ]
  }
}
```


### Lista di tutti gli id die token di un certo contratto

**Json Schema definition**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "QueryMsg",
  "oneOf": [
    ...
    {
      "description": "With Enumerable extension. Requires pagination. Lists all token_ids controlled by the contract. Return type: TokensResponse.",
      "type": "object",
      "required": [
        "all_tokens"
      ],
      "properties": {
        "all_tokens": {
          "type": "object",
          "properties": {
            "limit": {
              "type": [
                "integer",
                "null"
              ],
              "format": "uint32",
              "minimum": 0.0
            },
            "start_after": {
              "type": [
                "string",
                "null"
              ]
            }
          }
        }
      },
      "additionalProperties": false
    },
    ...
  ]
}
```

**Campi**

- `limit`: FACOLTATIVO. Si può definire un limite nella visualizzazione degli NFT
- `start_after`: FACOLTATIVO. Si può definire un limite nella visualizzazione degli NFT



**Esempio di messaggio**

```json
{
    "all_tokens": {
    }
}
```



**Esempio risposta**

```json
{
  "data": {
    "tokens": [
        "00001",
        "00002"
    ]
  }
}
```


### Indirizzo del minter di un certo contratto

**Json Schema definition**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "QueryMsg",
  "oneOf": [
    ...
    {
      "type": "object",
      "required": [
        "minter"
      ],
      "properties": {
        "minter": {
          "type": "object"
        }
      },
      "additionalProperties": false
    }
    ...
  ]
}
```

**Campi**

**Esempio di messaggio**

```json
{
    "minter": {
    }
}
```


**Esempio risposta**

```json
{
    "data": {
        "minter":"did:com:1cjnpack2jqngdhj9cap23h4n3dmxcvqswgyrlc"
    }
}
```