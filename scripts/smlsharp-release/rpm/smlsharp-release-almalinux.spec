Name: smlsharp-release-almalinux
Version: 8
Release: 1
Summary: SML# release files
License: MIT
URL: https://smlsharp.github.io/
Source0: smlsharp.repo.almalinux
Source1: RPM-GPG-KEY-smlsharp
Group: System Environment/Base
BuildArch: noarch
Requires: almalinux-repos >= 8

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
* Sun Sep 22 2024 Katsuhiro Ueno <katsu@ie.niigata-u.ac.jp> - 8-1
- Initial package.
