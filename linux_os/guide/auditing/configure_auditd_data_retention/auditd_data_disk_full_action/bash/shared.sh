# platform = Red Hat Virtualization 4,multi_platform_ol,multi_platform_rhel,multi_platform_sle,multi_platform_slmicro,multi_platform_ubuntu,multi_platform_almalinux

{{{ bash_instantiate_variables("var_auditd_disk_full_action") }}}

var_auditd_disk_full_action="$(echo $var_auditd_disk_full_action | cut -d \| -f 1)"

{{{ bash_replace_or_append("/etc/audit/auditd.conf", '^disk_full_action', "$var_auditd_disk_full_action", cce_identifiers=cce_identifiers) }}}
