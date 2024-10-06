#!/bin/bash

# Function to create the spec file
create_spec_file() {
    cat > my-wakeup-fix.spec << EOF
Name:           my-wakeup-fix
Version:        1.0
Release:        1%{?dist}
Summary:        Custom fix for wakeup issues

License:        MIT
URL:            https://example.com/my-wakeup-fix

Source0:        disable-devices-as-wakeup.sh
Source1:        disable_wakeup.te

Requires:       bash
BuildRequires:  selinux-policy-devel

%description
This package provides a custom fix for wakeup issues on immutable systems.

%install
mkdir -p %{buildroot}/usr/local/bin
mkdir -p %{buildroot}%{_datadir}/selinux/packages
install -m 755 %{SOURCE0} %{buildroot}/usr/local/bin/disable-devices-as-wakeup.sh
install -m 644 %{SOURCE1} %{buildroot}%{_datadir}/selinux/packages/disable_wakeup.te

%files
/usr/local/bin/disable-devices-as-wakeup.sh
%{_datadir}/selinux/packages/disable_wakeup.te

%post
semodule -i %{_datadir}/selinux/packages/disable_wakeup.te

%preun
semodule -r disable_wakeup

%changelog
* Thu Sep 12 2023 Your Name <your.email@example.com> - 1.0-1
- Initial version of the package
EOF
}

# Function to create the SELinux policy file
create_selinux_policy() {
    cat > disable_wakeup.te << EOF
module disable_wakeup 1.0;

require {
    type init_t;
    type bin_t;
    class file { execute open read };
}

#============= init_t ==============
allow init_t bin_t:file { execute open read };
EOF
}

# Main execution
echo "Creating necessary files for the wakeup fix..."
create_spec_file
create_selinux_policy

echo "Files created successfully. You can now proceed with building the RPM."
