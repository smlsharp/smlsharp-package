Name: smlsharp
Version: 4.1.0
Release: 0%{?dist}
Summary: Standard ML compiler with practical extensions
License: MIT
URL: https://smlsharp.github.io/
Source0: https://github.com/smlsharp/smlsharp/releases/download/v4.1.0/smlsharp-4.1.0.tar.gz
Group: Development/Languages
ExclusiveArch: x86_64
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires: llvm18-devel
BuildRequires: massivethreads-devel
BuildRequires: gmp-devel
Requires: llvm18
Requires: massivethreads-devel
Requires: gmp-devel
Requires: gcc
Requires: gcc-c++

%description
SML# is a variant of Standard ML programming language
equipped with practical features including seamless
interoperability with C, integration with SQL, native
multithread support, and separate compilation.

%package smlformat
Summary: Pretty printer generator for SML#
Group: Development/Languages

%description smlformat
Pretty printer generator for SML#

%package smllex
Summary: Lexical analyzer generator for SML#
Group: Development/Languages

%description smllex
Lexical analyzer generator for SML#

%package smlyacc
Summary: Parser generator for SML#
Group: Development/Languages

%description smlyacc
Parser generator for SML#

%prep
%setup -q -n %{name}-4.1.0
cp -p src/smlnj/LICENSE LICENSE_smlnj
cp -p src/smlnj-lib/LICENSE LICENSE_smlnj-lib
for i in src/smlformat/doc/OVERVIEW_en.txt src/smlformat/doc/OVERVIEW_ja.txt; do
  (rm "$i" && iconv -f shift_jis -t utf-8 > "$i") < "$i"
done

%build
set -ex
%configure --with-llvm=/usr/lib64/llvm18
make %{?_smp_mflags} stage
make %{?_smp_mflags} all

%check
set -ex
make %{?_smp_mflags} test

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT
sed -i '/^LDFLAGS /s/=.*$/=/' $RPM_BUILD_ROOT%{_libdir}/smlsharp/config.mk

%files
%defattr(-,root,root,-)
%license LICENSE
%license LICENSE_smlnj
%license LICENSE_smlnj-lib
%license src/runtime/netlib/dtoa.c
%doc README.md
%doc Changes
%{_bindir}/smlsharp
%{_libdir}/smlsharp
%{_mandir}/man1/smlsharp.1.gz

%files smlformat
%license LICENSE
%doc src/smlformat/README.txt
%doc src/smlformat/doc/OVERVIEW_en.txt
%doc src/smlformat/doc/OVERVIEW_ja.txt
%doc src/smlformat/doc/PPAlgorithm.txt
%doc src/smlformat/doc/SimpleTreePP.sml
%{_bindir}/smlformat
%{_mandir}/man1/smlformat.1.gz

%files smllex
%license LICENSE_smlnj
%doc src/ml-lex/README
%doc src/ml-lex/README.smlsharp
%{_bindir}/smllex
%{_mandir}/man1/smllex.1.gz

%files smlyacc
%license src/ml-yacc/COPYRIGHT
%doc src/ml-yacc/README
%doc src/ml-yacc/README.smlsharp
%{_bindir}/smlyacc
%{_mandir}/man1/smlyacc.1.gz

%changelog
* Fri Nov  8 2024 Katsuhiro Ueno <katsu@ie.niigata-u.ac.jp> - 4.1.0-0
- New upstream release.

* Tue Apr  6 2021 Katsuhiro Ueno <katsu@riec.tohoku.ac.jp> - 4.0.0-1
- New upstream release.

* Mon Mar 15 2021 Katsuhiro Ueno <katsu@riec.tohoku.ac.jp> - 3.7.1-1
- New upstream release.

* Mon Jan  4 2021 Katsuhiro Ueno <katsu@riec.tohoku.ac.jp> - 3.7.0-1
- New upstream release.

* Fri May 29 2020 Katsuhiro Ueno <katsu@riec.tohoku.ac.jp> - 3.6.0-1
- New upstream release.

* Tue Dec 24 2019 Katsuhiro Ueno <katsu@riec.tohoku.ac.jp> - 3.5.0-1
- Initial package.
