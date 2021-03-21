Name: smlsharp-release-rawhide
Version: 31
Release: 1
Summary: SML# release files
License: BSD
URL: https://smlsharp.github.io/
Source0: smlsharp.rawhide.repo
Source1: RPM-GPG-KEY-smlsharp
Group: System Environment/Base
BuildArch: noarch
Requires: fedora-repos-rawhide >= 31

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
* Fri Mar 19 2021 Katsuhiro Ueno <katsu@riec.tohoku.ac.jp> - 31-1
- Migrated to GitHub.

* Thu Dec  5 2019 Katsuhiro Ueno <katsu@riec.tohoku.ac.jp> - 31-0
- Initial package.
