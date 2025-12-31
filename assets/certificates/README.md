# i2pd iOS Certificates and Subscription Keys

These files are used by i2pd for secure routing.

This directory contains:

- Router identity keys (created on first run)
- Subscription seed certificates
- Any custom destination keys

## Files Created at Runtime

- `router.keys` - Your router's identity keys (auto-generated)
- `router.info` - Router information file
- `ntcp2.keys` - NTCP2 transport keys

## Subscription Seeds

The default subscription seeds for address book are:

- `http://inr.i2p/export/alive-hosts.txt`
- `http://i2p-projekt.i2p/hosts.txt`
- `http://stats.i2p/cgi-bin/newhosts.txt`

## Security Note

The `router.keys` file is your identity on the I2P network.
Keep it secure and backed up.
