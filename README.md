# openvpn-ca-rotation
To manage Certificate Authority (CA) rotation securely and reproducibly for OpenVPN using Easy-RSA and DevOps workflows.

# 🔐 OpenVPN CA Rotation

This repository provides a secure and DevOps-friendly workflow for **rotating your OpenVPN Certificate Authority (CA)** and reissuing all associated certificates using [Easy-RSA](https://github.com/OpenVPN/easy-rsa).

---

## 📌 Why Rotate the CA?

- Your current CA key is compromised or expired
- You're practicing good PKI hygiene
- You want to upgrade crypto (from static DH to ECDH)
- You want to enforce a new trust chain
- Rotate CA & reissue certs every 3–5 years
---

## 🧱 Requirements

- OpenVPN + Easy-RSA 3 installed on your server
- Ubuntu/Debian recommended (but portable)
- Sudo/root access
- Backup before rotation!

---

## 📁 openvpn-ca-rotation <br>
├── README.md # Overview and full manual CA rotation steps <br> 
├── scripts/ <br>
│   └── rotate-ca.sh  # (Optional) Automates CA rotation  <br>

## 🔁 CA Rotation Steps

Before rotation check serial key current CA and compare it with generated <br>
Security reasons and valitidy - if the CA was really rotated!
```
openssl x509 -in ca.crt -noout -serial | cut -d'=' -f2
```


### 1. Backup current OpenVPN and PKI
```
sudo cp -r /etc/openvpn /etc/openvpn-backup
cp -r ~/openvpn-ca ~/openvpn-ca-backup
```
2. Clean and reinitialize Easy-RSA
```
cd ~/openvpn-ca
./easyrsa clean-all
./easyrsa init-pki
```
3. Create a new password-protected CA
```
./easyrsa build-ca
```
4. Generate and sign a new server certificate
```
./easyrsa gen-req server
./easyrsa sign-req server server
```
5. Regenerate DH parameters (unless switching to ECDH)
```
./easyrsa gen-dh

Instead of dh dh.pem, use this in server.conf:
ecdh-curve secp384r1
```
6. Generate new TLS key (recommended)
```
openvpn --genkey --secret ta.key
```
7. Reissue all client certificates
```
./easyrsa gen-req client1
./easyrsa sign-req client client1
```
8. Deploy new certs and keys
```
sudo cp pki/ca.crt pki/issued/server.crt pki/private/server.key pki/dh.pem ta.key /etc/openvpn/
```
10. Distribute new .ovpn configs to clients


CRL (Certificate Revocation List) is not neccesary. Why? <br>
Old certs are untrusted by default because we fully rotated to new CA.



