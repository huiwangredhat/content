# platform = multi_platform_all


{{{ bash_dconf_settings("org/gnome/desktop/screensaver", "show-full-name-in-top-bar", "false", "local.d", "00-security-settings", rule_id=rule_id) }}}
{{{ bash_dconf_lock("org/gnome/desktop/screensaver", "show-full-name-in-top-bar", "local.d", "00-security-settings-lock") }}}
