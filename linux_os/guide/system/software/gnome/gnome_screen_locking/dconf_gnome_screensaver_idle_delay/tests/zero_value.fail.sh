#!/bin/bash
# packages = dconf,gdm
# variables = inactivity_timeout_value=900

. $SHARED/dconf_test_functions.sh

clean_dconf_settings
add_dconf_profiles
add_dconf_setting "org/gnome/desktop/session" "idle-delay" "uint32 0" "local.d" "00-security-settings"

{{% if 'ubuntu' in product %}}
add_dconf_lock "org/gnome/desktop/session" "idle-delay" "local.d" "00-security-settings"
{{% endif %}}
