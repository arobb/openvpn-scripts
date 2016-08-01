#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )


if [ -d "$1" ];
then
  cd "$1"
fi


#
# Check for a client certificate in the appropriate directory
#
clientcrtcount="$(ls -l *.crt | grep -v "ca.crt" | wc -l | sed -n 's/^[[:space:]]*\([0-9]*\).*$/\1/p')"
if [ "$clientcrtcount" -eq "0" ];
then
  echo "Cannot find a client certificate (.crt) file."
  exit 1
fi


#
# Extact client name
#
clientname=$(grep "Subject: CN=" *.crt | head -1 | sed -n 's/^.*CN=\(.*\).*$/\1/p')
clientconfig="$clientname.ovpn"

cp "$DIR/openvpn-client.config" "./$clientconfig"


#
# Spacing
#
echo "" >> "$clientconfig"


#
# CA Cert
#
echo '<ca>' >> "$clientconfig"
cat "ca.crt" >> "$clientconfig"
echo '</ca>' >> "$clientconfig"
echo "" >> "$clientconfig"


#
# Client cert
#
echo '<cert>' >> "$clientconfig"

write="no"
while IFS='' read -r line || [[ -n "$line" ]]; do

  # Find the first line that holds the certificate
  echo "$line" | grep -e '-----BEGIN' > /dev/null
  if [ "$?" -eq "0" ];
  then
    write="yes"
  fi

  if [ "$write" == "yes" ];
  then
    echo "$line" >> "$clientconfig"
  fi
done < "$clientname.crt"

echo '</cert>' >> "$clientconfig"
echo "" >> "$clientconfig"


#
# Client key
#
echo '<key>' >> "$clientconfig"
cat "$clientname.key" >> "$clientconfig"
echo '</key>' >> "$clientconfig"
echo "" >> "$clientconfig"


#
# HMAC pre-shared key
#
echo '<tls-auth>' >> "$clientconfig"

write="no"
while IFS='' read -r line || [[ -n "$line" ]]; do

  # Find the first line that holds the certificate
  echo "$line" | grep -e '-----BEGIN' > /dev/null
  if [ "$?" -eq "0" ];
  then
    write="yes"
  fi

  if [ "$write" == "yes" ];
  then
    echo "$line" >> "$clientconfig"
  fi
done < "ta.key"

echo '</tls-auth>' >> "$clientconfig"
echo "" >> "$clientconfig"


echo "Don't forget to set the server values."
echo "$PWD/$clientconfig ready."
