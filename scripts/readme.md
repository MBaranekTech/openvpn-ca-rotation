# OpenVPN CA Rotation Script

This script automates the rotation of the Certificate Authority (CA) and the server certificate for an OpenVPN server using Easy-RSA.

I built this script to better understand OpenVPN’s PKI lifecycle and automate a common maintenance task. The process includes:
- Backing up current configs
- Cleaning and reinitializing PKI
- Creating a new CA
- Generating and signing new server certs
- Deploying all required files to the OpenVPN server
- Restarting the OpenVPN service

## Requirements
- Easy-RSA installed
- OpenVPN installed and configured
- sudo privileges

> ⚠️ Always test in a safe environment before using in production.

## Usage
```bash
chmod +x rotate-ca.sh
./rotate-ca.sh