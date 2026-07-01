# module: kms-key

One customer-managed CMK per purpose, rotation always on (ADR-017; Volume 10). Use
`multi_region = true` for keys whose ciphertext must be readable in the `eu-west-1` DR
region (ADR-018). No key is ever shared across unrelated purposes.
