Name:           my-wakeup-fix
Version:        1.0
Release:        1%{?dist}
Summary:        Custom fix for wakeup devices

License:        MIT
URL:            https://github.com/woeiru/lab
Source0:        disable-devices-as-wakeup.sh
Source1:        disable_wakeup.te

Requires:       bash
BuildRequires:  selinux-policy-devel

%description
Custom fix to disable specific devices as wakeup sources

%install
mkdir -p %{buildroot}/usr/local/bin
install -m 755 %{SOURCE0} %{buildroot}/usr/local/bin/disable-devices-as-wakeup.sh
mkdir -p %{buildroot}/usr/share/selinux/packages
install -m 644 %{SOURCE1} %{buildroot}/usr/share/selinux/packages/disable_wakeup.te

%files
/usr/local/bin/disable-devices-as-wakeup.sh
/usr/share/selinux/packages/disable_wakeup.te

%post
semodule -i /usr/share/selinux/packages/disable_wakeup.te

%preun
semodule -r disable_wakeup

%changelog
* Mon Sep 11 2023 Your Name <your.email@example.com> - 1.0-1
- Initial version
