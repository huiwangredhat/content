#!/bin/bash
{{% if sshd_distributed_config == "false" %}}
# platform = Not Applicable
{{% else %}}
# platform = multi_platform_all
{{% endif %}}

SSHD_PARAM="RekeyLimit"

mkdir -p /etc/ssh/sshd_config.d
touch /etc/ssh/sshd_config.d/nothing

if grep -q "^\s*${SSHD_PARAM}" /etc/ssh/sshd_config /etc/ssh/sshd_config.d/* ; then
   sed -i "/^\s*${SSHD_PARAM}.*/Id" /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*
fi

echo "${SSHD_PARAM} 512M 1h" >> /etc/ssh/sshd_config.d/good_config.conf
echo "${SSHD_PARAM} 1G 3h" >> /etc/ssh/sshd_config.d/bad_config.conf
