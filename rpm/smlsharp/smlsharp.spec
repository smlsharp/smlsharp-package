Name: smlsharp
Version: 0.0.0~pre0
Release: 1%{?dist}
Summary: Standard ML compiler with practical extensions
License: BSD
URL: https://www.pllab.riec.tohoku.ac.jp/smlsharp/
Source0: %{name}-0.0.0-pre0.tar.gz
Group: Development/Languages
ExclusiveArch: x86_64
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires: llvm-devel >= 12.0.0, llvm-devel < 13.0.0
BuildRequires: massivethreads-devel
BuildRequires: gmp-devel
Requires: llvm >= 12.0.0, llvm < 13.0.0
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
%setup -q -n %{name}-0.0.0-pre0
cp -p src/smlnj/LICENSE LICENSE_smlnj
cp -p src/smlnj-lib/LICENSE LICENSE_smlnj-lib
for i in src/smlformat/doc/OVERVIEW_en.txt src/smlformat/doc/OVERVIEW_ja.txt; do
  (rm "$i" && iconv -f shift_jis -t utf-8 > "$i") < "$i"
done

%build
set -ex
%configure
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
* Wed Apr 29 2019 Katsuhiro Ueno <katsu@riec.tohoku.ac.jp> - 0.0.0~pre0-1
- Initial package.
