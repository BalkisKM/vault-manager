# Vault Manager Contract

A smart contract for managing multiple secure asset vaults with
permission-based access and on-chain accounting.

## Key Functions
- `create-vault` — Deploy a new vault with an owner
- `deposit` — Store assets into a designated vault
- `withdraw` — Controlled asset release to authorized users
- `get-vault-balance` — Check stored asset amount in vault
- `set-allowed` — Grant or revoke vault usage permissions

Useful for lending pools, custody services, DAOs, and automated protocols.
