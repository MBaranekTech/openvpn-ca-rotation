#!/bin/bash
# rotate-ca.sh: Rotates the OpenVPN Certificate Authority (CA) and deploys new server certificates using Easy-RSA

set -e  # Exit immediately if any command fails

echo "=== Starting OpenVPN CA Rotation ==="

# === CONFIGURATION SECTION ===
# Path to the Easy-RSA installation directory
EASYRSA_DIR=/home/mba/openvpn-ca

# OpenVPN config directory
OPENVPN_DIR=/etc/openvpn

# Common name for the server certificate (used in cert creation)
SERVER_NAME="server"

# Tag backups and files with the current date
DATE_TAG=$(date +%Y%m%d)

# === BACKUP CURRENT CONFIGURATION ===
echo "[+] Backing up current OpenVPN and Easy-RSA folders..."

# Create full backups in case we need to roll back
cp -r $OPENVPN_DIR "${OPENVPN_DIR}-backup-${DATE_TAG}"
cp -r $EASYRSA_DIR "${EASYRSA_DIR}-backup-${DATE_TAG}"

# === CLEAN OUT OLD CERTIFICATES & INIT NEW PKI ===
echo "[+] Cleaning out existing PKI and initializing a new one..."

cd "$EASYRSA_DIR"
./easyrsa clean-all        # Remove old keys and certificates
./easyrsa init-pki         # Set up a new Public Key Infrastructure (PKI) structure

# === BUILD A NEW CERTIFICATE AUTHORITY ===
echo "[+] Creating a new Certificate Authority (CA)..."

# This will prompt you to enter CA details (like country, organization, etc.)
./easyrsa build-ca

# === CREATE A NEW SERVER CERTIFICATE REQUEST ===
echo "[+] Generating a new server certificate request..."

# This creates the private key and CSR for the VPN server
./easyrsa gen-req "$SERVER_NAME"

# === SIGN THE SERVER CERTIFICATE REQUEST WITH OUR NEW CA ===
echo "[+] Signing the server certificate..."

# Approve the request and create a signed certificate for the server
./easyrsa sign-req server "$SERVER_NAME"

# === GENERATE DIFFIE-HELLMAN PARAMETERS (for key exchange) ===
echo "[+] Generating Diffie-Hellman parameters (this might take a while)..."

./easyrsa gen-dh

# === GENERATE TLS AUTH KEY (extra protection against certain attacks) ===
echo "[+] Creating TLS authentication key..."

# This key helps protect against some common OpenVPN attacks (e.g. DoS)
openvpn --genkey secret "$EASYRSA_DIR/ta.key"

# === DEPLOY NEW CERTIFICATES AND KEYS TO THE OPENVPN SERVER ===
echo "[+] Copying new certs and keys into OpenVPN config directory..."

# Copy all necessary files into the OpenVPN server directory
sudo cp pki/ca.crt "$OPENVPN_DIR/ca.crt"
sudo cp pki/issued/"$SERVER_NAME".crt "$OPENVPN_DIR/server.crt"
sudo cp pki/private/"$SERVER_NAME".key "$OPENVPN_DIR/server.key"
sudo cp pki/dh.pem "$OPENVPN_DIR/dh.pem"
sudo cp "$EASYRSA_DIR/ta.key" "$OPENVPN_DIR/ta.key"

# === RESTART THE OPENVPN SERVICE TO APPLY CHANGES ===
echo "[+] Restarting OpenVPN to apply new certificates..."

sudo systemctl restart openvpn@server

# === DONE! ===
echo "OpenVPN CA and server certificate rotation completed successfully."