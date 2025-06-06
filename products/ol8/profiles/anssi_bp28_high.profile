documentation_complete: true

title: 'ANSSI-BP-028 (high)'

description: |-
    This profile contains configurations that align to ANSSI-BP-028 v2.0 at the high hardening level.

    ANSSI is the French National Information Security Agency, and stands for Agence nationale de la sécurité des systèmes d'information.
    ANSSI-BP-028 is a configuration recommendation for GNU/Linux systems.

    A copy of the ANSSI-BP-028 can be found at the ANSSI website:
    https://www.ssi.gouv.fr/administration/guide/recommandations-de-securite-relatives-a-un-systeme-gnulinux/

selections:
    - anssi:all:high
    - var_password_hashing_algorithm=SHA512
    - var_password_pam_unix_rounds=65536
    # An alternative solution for R67 is using nss-pam-ldapd package, in this case ensures SSL and certificate configuration
    - ldap_client_start_tls
    - ldap_client_tls_cacertpath
    # Following rules once had a prodtype incompatible with the ol8 product
    - '!accounts_passwords_pam_tally2_deny_root'
    - '!timer_logrotate_enabled'
    - '!ensure_redhat_gpgkey_installed'
    - '!ensure_almalinux_gpgkey_installed'
    - '!aide_periodic_checking_systemd_timer'
    - '!audit_rules_privileged_commands_rmmod'
    - '!grub2_mds_argument'
    - '!audit_rules_privileged_commands_modprobe'
    - '!package_dracut-fips-aesni_installed'
    - '!cracklib_accounts_password_pam_lcredit'
    - '!sysctl_fs_protected_regular'
    - '!cracklib_accounts_password_pam_ocredit'
    - '!audit_rules_privileged_commands_insmod'
    - '!chronyd_configure_pool_and_server'
    - '!accounts_passwords_pam_tally2'
    - '!cracklib_accounts_password_pam_ucredit'
    - '!accounts_passwords_pam_tally2_unlock_time'
    - '!cracklib_accounts_password_pam_minlen'
    - '!sysctl_fs_protected_fifos'
    - '!cracklib_accounts_password_pam_dcredit'
    - '!grub2_page_alloc_shuffle_argument'
    - '!package_kea_removed'
    - '!audit_rules_file_deletion_events_renameat2'
    - '!audit_rules_dac_modification_fchmodat2'
    # disable R45: Enable AppArmor security profiles
    - '!apparmor_configured'
    - '!all_apparmor_profiles_enforced'
    - '!grub2_enable_apparmor'
    - '!package_apparmor_installed'
    - '!package_pam_apparmor_installed'
