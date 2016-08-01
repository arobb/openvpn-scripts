#!/bin/bash
# Build a client key pair


# Server directory
serverdir="/home/pi/openvpn-keys/server-4096/easy-rsa/easyrsa3"

# Client directory
clientdir="/home/pi/openvpn-keys/clients-4096/easy-rsa/easyrsa3"


# Client name as first param
if [ -z "$1" ];
then
  echo "No client name provided."
  exit 1
else
  clientname="$1"
fi


# Check for existing entries
existingreq="no"
# Check for existing client-side cert request
if [ -f "$clientdir/pki/reqs/$clientname.req" ];
then
  echo "Already exists: $clientdir/pki/reqs/$clientname.req"
  existingreq="yes"
fi

# Check for private key
if [ -f "$clientdir/pki/private/$clientname.key" ];
then
  echo "Already exists: $clientdir/pki/private/$clientname.key"
  existingreq="yes"
fi

# Check for server-imported cert request
if [ -f "$serverdir/pki/reqs/$clientname.req" ];
then
  echo "Already exists: $serverdir/pki/reqs/$clientname.req"
  existingreq="yes"
fi

# Check for issued certificate
if [ -f "$serverdir/pki/issued/$clientname.crt" ];
then
  echo "Already exists: $serverdir/pki/issued/$clientname.crt"
  existingreq="yes"
fi

# Check issued database for entry
grep 'CN=work' $serverdir/pki/index.txt >/dev/null
if [ "$?" -eq "0" ];
then
  echo "PKI database contains entry. Use 'sed -i '/CN=$clientname/d' $serverdir/pki/index.txt' to remove."
  existingreq="yes"
fi

if [ "$existingreq" == "yes" ];
then
  echo "Entry/ies already exist for client named '$clientname'. Please remove them or choose a different name."
  exit 1
fi


# Make a directory for the keys/certs output
if [ -d "$clientname" ];
then
  echo "Directory with the client name already exists. Please remove so I don't accidentally overwrite something important."
  exit 1
else
  currentdir="$PWD"
fi


# Create request
echo "Creating CSR..."
cd "$clientdir"
$clientdir/easyrsa --batch --req-cn="$clientname" gen-req "$clientname" nopass
result=$?

if [ "$result" -ne "0" ];
then
  echo "Create request failed."
  exit "$result"
fi


# Import request
echo "Importing request..."
cd "$serverdir"
$serverdir/easyrsa import-req "$clientdir/pki/reqs/$clientname.req" "$clientname"
result=$?

if [ "$result" -ne "0" ];
then
  echo "Import request failed."
  exit "$result"
fi


# Sign request
echo "Signing request..."
cd "$serverdir"
$serverdir/easyrsa --batch sign-req client "$clientname"
result=$?

if [ "$result" -ne "0" ];
then
  echo "Sign request failed."
  exit "$result"
fi


# Copy keys and certs to local dir
cd "$currentdir"
mkdir "$clientname"
cd "$clientname"

cp "$serverdir/pki/ca.crt" ./
cp "$serverdir/pki/ta.key" ./
cp "$serverdir/pki/issued/$clientname.crt" ./
cp "$clientdir/pki/private/$clientname.key" ./
