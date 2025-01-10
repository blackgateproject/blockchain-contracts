# Blockchain

This is where the source for BlackGate's Blockchain module resides, there is noticeable overlap with the backend so both frontend's backend and blockchain's backend for now is seperate.

Ideally this is what it should be later on, subject to change however

# How to run tests

```
# Copy this as it is and run in a terminal
git clone https://github.com/blackgateproject/blockchain.git
cd blockchain
npm install
npx hardhat compile; npx hardhat test
```

## How to run the hardhat test network for the frontend

```
# Copy this as it is and run in a terminal
git clone https://github.com/blackgateproject/blockchain.git
cd blockchain
npm install
npx hardhat compile; npx hardhat node
```

### In a new terminal session run the following

```
npx hardhat ignition deploy ignition/modules/Blackgate.ts --network localhost
```




## Dev notes

#### Skipping this for now

- ~~Trying to setup Blockchain~~
  - ~~Contracts need more research~~
    - ~~Create one for each or make them based on flow? (8 vs 4)~~
  - ~~IPFS is required~~
    - ~~Switched from IPFS Client to Helia IPFS~~
    - ~~need to add a note that IPFS-Desktop has to be installed as well~~
    - ~~The problem w this is that IPFS-Desktop is public by default and i have to go over the Config Details to understand what the hell is going on~~
      - ~~Moving onto IPFS-Kubo?~~
    - ~~SWITCH:: Need to figure out a way to ensure that the IPFS nodes are distributed along with the chain nodes in test or at least scaled with the test nodes.~~
- ~~What we're actually doing when ID Creds are being sent to the blockchain layer (Looking at the diagram)~~
  - ~~On-chain (S_Contracts)~~
    - ~~A record that holds the following is created for each VC CRUD operation~~
      - ~~Header~~
        - ~~hash(PrevBlock)~~
        - ~~hash(CurrBlock)~~
        - ~~IDCommitment~~
          - ~~ID Commitment is the RSA Accumulator at that stage, that has been converted to a constant-length IDC~~
  - ~~Off-chain (IPFS)~~
    - ~~The VC recieved is stored here first (for schema refer to doc figure 2 on page 5)~~

#### TODO

- Critical
  - User Identity & Acess Management:
    - FR - 1: System should provide robust idenitty Management, ensure that UD & Identities are securely stored
      - TL;DR: User must be able to create accounts, they must also be able to sign into said accounts
        - User Roles are just two atm.
          - User can Access Federated Apps or manage their account creds
          - Admin can View all active users, edit their details and delete their accounts
- High
  - Support Page.
    - Not in FR but it must be functional if Critical have been addresed
- Medium
  - Decaying Trust Score
  - Admin revocation roles
