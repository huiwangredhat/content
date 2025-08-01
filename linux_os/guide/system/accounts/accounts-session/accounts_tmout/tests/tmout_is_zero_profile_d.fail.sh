#!/bin/bash

# variables = var_accounts_tmout=900

TEST_FILE=/etc/profile.d/tmout.sh

sed -i "/.*TMOUT.*/d" /etc/profile

test -f $TEST_FILE || touch $TEST_FILE

if grep -q "TMOUT=" $TEST_FILE; then
    sed -i "s/.*TMOUT=.*/TMOUT=0/" $TEST_FILE
else
    echo "TMOUT=0" >> $TEST_FILE
fi
