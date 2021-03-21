Name: smlsharp-release-centos
Version: 7
Release: 1
Summary: SML# release files
License: BSD
URL: https://smlsharp.github.io/
Source0: smlsharp.centos.repo
Source1: RPM-GPG-KEY-smlsharp
Group: System Environment/Base
BuildArch: noarch
Requires: centos-release = 7
Requires: epel-release = 7

%description
This package provides the signing key for the SML# packages and
configuration files for accessing SML#'s private repository.

%prep

%build

%install
rm -rf $RPM_BUILD_ROOT
%{__install} -Dpm 644 %{SOURCE0} $RPM_BUILD_ROOT%{_sysconfdir}/yum.repos.d/smlsharp.repo
%{__install} -Dpm 644 %{SOURCE1} $RPM_BUILD_ROOT%{_sysconfdir}/pki/rpm-gpg/RPM-GPG-KEY-smlsharp

%files
%defattr(644,root,root,755)
%{_sysconfdir}/pki/rpm-gpg/RPM-GPG-KEY-smlsharp
%config(noreplace) %{_sysconfdir}/yum.repos.d/smlsharp.repo

%changelog
* Fri Mar 19 2021 Katsuhiro Ueno <katsu@riec.tohoku.ac.jp> - 7-1
- Migrated to GitHub.

* Sun May  5 2019 Katsuhiro Ueno <katsu@riec.tohoku.ac.jp> - 7-0
- Initial package.
