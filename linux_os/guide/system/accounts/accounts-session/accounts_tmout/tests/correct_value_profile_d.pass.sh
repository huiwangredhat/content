#!/bin/bash

{{% if 'ubuntu' in product %}}
# platform = Not Applicable
{{% endif %}}

# variables = var_accounts_tmout=700

TEST_FILE=/etc/profile.d/tmout.sh

sed -i "/.*TMOUT.*/d" /etc/profile

test -f $TEST_FILE || touch $TEST_FILE

if grep -q "TMOUT" $TEST_FILE; then
	sed -i "s/.*TMOUT.*/typeset -xr TMOUT=700/" $TEST_FILE
else
	echo "typeset -xr TMOUT=700" >> $TEST_FILE
fi
