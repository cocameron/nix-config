# Secrets Management

Secrets are managed using [SOPS](https://github.com/getsops/sops) with age encryption.

## Location

Encrypted secrets are stored on each machine at:
- `/var/lib/sops-nix/secrets.yaml` - The encrypted secrets file
- `/var/lib/sops-nix/keys.txt` - The age key for decryption

**Note:** Secrets are NOT committed to this repository for an additional layer of security.

## Age Keys

Each machine has an age key defined in `.sops.yaml`:
- `colin` - Personal key
- `nixlab` - Server key

## Editing Secrets

On the deployed machine:
```bash
sops /var/lib/sops-nix/secrets.yaml
```

## Backup

Important: Manually backup `/var/lib/sops-nix/` on each machine to prevent data loss.
