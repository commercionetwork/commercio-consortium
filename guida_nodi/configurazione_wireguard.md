## 1) Scenario

Abbiamo due macchine che vogliamo mettere in comunicazione point-to-point.

Una macchina su rete esterna che chiameremo `peer 1` e una macchina su rete interna che chiameremo `peer 2`.

* Peer 1
  * Ip statico: 167.76.76.76
  * Ip assegnato per la vpn: 192.168.1.10 

* Peer 2
  * Ip statico: 10.0.0.50
  * Ip assegnato per la vpn: 192.168.1.11 

## 2) Installazione wireguard Peer 1

```sh
# Installare wireguard

apt install wireguard --assume-yes
```

```sh
# Generare le chiavi pubbliche e private che serviranno per mettere in comunicazione le macchine

mkdir -p /etc/wireguard/keys

sh -c 'cd /etc/wireguard/keys; umask 077; wg genkey | tee privatekey | wg pubkey > publickey'

```

```sh
# Verificare che abbia effettivamente generato le chiavi pubbliche e private

cat /etc/wireguard/keys/privatekey

cat /etc/wireguard/keys/publickey
```

## 3) Installazione wireguard Peer 2

```sh
# Installare wireguard

apt install wireguard --assume-yes
```

```sh
# Generare le chiavi pubbliche e private che serviranno per mettere in comunicazione le macchine

mkdir -p /etc/wireguard/keys

sh -c 'cd /etc/wireguard/keys; umask 077; wg genkey | tee privatekey | wg pubkey > publickey'

```

```sh
# Verificare che abbia effettivamente generato le chiavi pubbliche e private

cat /etc/wireguard/keys/privatekey

cat /etc/wireguard/keys/publickey
```


## 4) Configurazione wireguard Peer1

```sh
# Generare file di configurazione di wireguard

vim /etc/wireguard/wg0.conf

```

All'interno del file di configurazione indicare quanto segue:

```sh
## Set Up WireGuard VPN on Ubuntu By Editing/Creating wg0.conf File ##

[Interface]
## Indicare l'ip scelto da assegnare all'interfaccia vpn indicando la subnet ##
Address = 192.168.1.10/24
 
## Indicare una porta in ascolto ##
ListenPort = 41194
 
## Indicare la chiave privata generata in precedenza /etc/wireguard/privatekey ##
PrivateKey = eEvqkSJVw.........hecvNHU=

## Indicare il flag per rendere persistenti le configurazioni anche al riavvio della macchina ##
SaveConfig = true
```

```sh
# Avviare i servizi

systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
systemctl status wg-quick@wg0

```

```sh
# Verificare se è stata creata l'interfaccia

sudo wg

sudo ifconfig wg0

```

## 5) Configurazione wireguard Peer2

```sh
# Generare file di configurazione di wireguard

vim /etc/wireguard/wg0.conf

```

All'interno del file di configurazione indicare quanto segue:

```sh
## Set Up WireGuard VPN on Ubuntu By Editing/Creating wg0.conf File ##

[Interface]
## Indicare l'ip scelto da assegnare all'interfaccia vpn indicando la subnet ##
Address = 192.168.1.11/24
 
## Indicare una porta in ascolto ##
ListenPort = 50122
 
## Indicare la chiave privata generata in precedenza /etc/wireguard/privatekey ##
PrivateKey = eEvqkSJVw.........hecvNHU=

## Indicare il flag per rendere persistenti le configurazioni anche al riavvio della macchina ##
SaveConfig = true
```

```sh
# Avviare i servizi

systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
systemctl status wg-quick@wg0

```


```sh
# Verificare se è stata creata l'interfaccia

sudo wg

sudo ifconfig wg0

```

## 5) Mettere in comunicazione i due Peer

#### 5.a) Configurazioni su Peer1

```sh
systemctl stop wg-quick@wg0

vim /etc/wireguard/wg0.conf
```

```sh
[Interface]
.......

[Peer]
## Indicare la chiave pubblica di peer2 ##
PublicKey = LikYk..........1kk=

## Indicare l'ip scelto per l'interfaccia della vpn di peer2 ##
AllowedIPs = 192.168.1.11/32

## Anche se non si indica manualmente l'endpoint nel file, wireguard si prende in automatico l'indirizzo pubblico del server e lo scrive nel file ##
Endpoint: 11.22.33.44:50122
```

```sh
systemctl start wg-quick@wg0
```

#### 5.b) Configurazioni su Peer2

```sh
systemctl stop wg-quick@wg0

vim /etc/wireguard/wg0.conf
```

```sh
[Interface]
.......

[Peer]
## Indicare la chiave pubblica di peer1 ##
PublicKey = LikYk..........1kk=

## Indicare l'ip scelto per l'interfaccia della vpn di peer1 ##
AllowedIPs = 192.168.1.10/32

## Indicare l'ip pubblico di peer1 con la porta in ascolto ##
Endpoint = 167.76.76.76:41194

## Essendo che su peer1 non abbiamo indicato l'endpoint con l'ip pubblico di peer2, la connessione viene aperta solo nel momento in cui peer2 tenta di comunicare con peer1 e non viceversa poichè peer1 non ha indicato nessun endpoint.

È quindi necessario utilizzare questo flag che ogni 15 secondi manda dei pacchetti per tenere aperta la connessione ##

PersistentKeepalive = 15
```

```sh
systemctl start wg-quick@wg0
```

## 6) Verifiche finali

```sh
# Ping da peer 1 a peer 2

ping 192.168.1.11

# Ping da peer 2 a peer 1

ping 192.168.1.10

```




## 7) Gestione

### 7.1) Modifica configurazioni
Per modificare le configurazioni, es. modifica ip

```bash
systemctl stop wg-quick@wg0
```

editare la configurazione con le modifiche desiderate


```bash
vim /etc/wireguard/wg0.conf
```

Riavviare il service
```bash
systemctl start wg-quick@wg0
```
