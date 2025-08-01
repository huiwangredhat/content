---
documentation_complete: true

title: 'ANSSI-BP-028 (enhanced)'

description: |-
    This profile contains configurations that align to ANSSI-BP-028 v2.0 at the enhanced hardening level.

    ANSSI is the French National Information Security Agency, and stands for Agence nationale de la sécurité des systèmes d'information.
    ANSSI-BP-028 is a configuration recommendation for GNU/Linux systems.

    A copy of the ANSSI-BP-028 can be found at the ANSSI website:
      https://www.ssi.gouv.fr/administration/guide/recommandations-de-securite-relatives-a-un-systeme-gnulinux/

selections:
    - anssi:all:enhanced
    - 'package_rsyslog_installed'
    - 'service_rsyslog_enabled'
  # PASS_MIN_LEN is handled by PAM on debian systems.
    - '!accounts_password_minlen_login_defs'
  # ANSSI BP 28 suggest using libpam_pwquality, which isn't deployed by default
    - 'package_pam_pwquality_installed'
  # PAM honour login.defs file for algorithm
    - 'set_password_hashing_algorithm_logindefs'
  # Debian uses apparmor
    - '!selinux_state'
    - '!audit_rules_mac_modification'
    - '!selinux_policytype'
    - '!sebool_selinuxuser_execheap'
    - '!sebool_deny_execmem'
    - '!sebool_selinuxuser_execstack'
    - '!sebool_secure_mode_insmod'
    - '!sebool_ssh_sysadm_login'

  # this rule is incompatible with R38
    - '!file_groupownership_system_commands_dirs'

  # The following are MLS related rules (not part of ANSSI-BP-028)
    - '!accounts_polyinstantiated_tmp'
    - '!accounts_polyinstantiated_var_tmp'
    - '!enable_pam_namespace'
  # there is no tmp.mount unit on Debian 12.
    - '!systemd_tmp_mount_enabled'
  # this rule cannot handle /etc/chrony/chrony.conf path properly.
  # chronyd_specify_remote_server still report wether chrony is configured.
    - '!chronyd_configure_pool_and_server'

  # Following rules aren't compatible with Debian 13
    - '!accounts_passwords_pam_tally2_deny_root'
    - '!ensure_redhat_gpgkey_installed'
    - '!set_password_hashing_algorithm_systemauth'
    - '!package_dnf-automatic_installed'
    - '!dnf-automatic_security_updates_only'
    - '!cracklib_accounts_password_pam_lcredit'
    - '!dnf-automatic_apply_updates'
    - '!cracklib_accounts_password_pam_ocredit'
    - '!accounts_password_pam_unix_rounds_system_auth'
    - '!timer_dnf-automatic_enabled'
    - '!accounts_passwords_pam_tally2'
    - '!cracklib_accounts_password_pam_ucredit'
    - '!file_permissions_unauthorized_sgid'
    - '!ensure_gpgcheck_local_packages'
    - '!accounts_passwords_pam_tally2_unlock_time'
    - '!enable_authselect'
    - '!cracklib_accounts_password_pam_minlen'
    - '!cracklib_accounts_password_pam_dcredit'
    - '!ensure_gpgcheck_globally_activated'
    - '!file_permissions_unauthorized_suid'
    - '!ensure_gpgcheck_never_disabled'
    - '!ensure_oracle_gpgkey_installed'
    - '!ensure_almalinux_gpgkey_installed'
    - '!package_dracut-fips-aesni_installed'
    - '!audit_rules_file_deletion_events_renameat2'
    - '!audit_rules_dac_modification_fchmodat2'

  # The following rule is not applicable to Debian 13
    - '!logind_session_timeout'
