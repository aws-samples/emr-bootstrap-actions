#! /bin/bash

echo "Cleaning minions that do not respond to ping... "

salt  '*'  test.ping > /tmp/all_hosts

cat all_hosts | grep return -B 1 | grep -v 'return' | cut -d ':' -f1 > /tmp/salt_error_hosts

for i in $( cat salt_error_hosts); do
  # for deleting the auth-key
  salt-key -d $i -y;
  # for delete the unauth key , sometimes it's needed:
  salt-key -d $i -y;
  # delete the pem file
  if [ -f /etc/salt/pki/master/minions/%i ]; then
        rm -f /etc/salt/pki/master/minions/$i
  fi
done

rm /tmp/all_hosts /tmp/salt_error_hosts
echo "done"
