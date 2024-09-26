Name: massivethreads
Version: 1.00
Release: 3%{?dist}
Summary: A lightweight thread library for high productivity languages
License: BSD-2-Clause
URL: https://github.com/massivethreads/massivethreads
Source0: https://github.com/massivethreads/massivethreads/archive/v1.00.tar.gz
Patch0: massivethreads-1.00-manpages.patch
Patch1: glibc-pthread-yield.patch
Patch2: myth_wrap_malloc-memalign-pvalloc.patch
Patch3: skip-tests-memalign-pvalloc.patch
Group: Development/Libraries
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires: sqlite-devel

%description
MassiveThreads is a user-level thread library that can create
a massive number of threads significantly faster than native
operating system threads.

%package devel
Summary: Development files for the MassiveThreads library
Group: Development/Libraries
Requires: %{name} = %{version}-%{release}

%description devel
Libraries and header files for using the MassiveThreads library in
development.

%package ld
Summary: Static Pthread wrapper of the MassiveThreads library
Group: Development/Libraries

%description ld
This package provides libmyth-ld, a variant of the MassiveThreads
library, which overrides Pthreads API with corresponding MassiveThreads
API by using a linker functionality.

%package ld-devel
Summary: Development files for libmyth-ld
Group: Development/Libraries
Requires: %{name}-ld = %{version}-%{release}

%description ld-devel
Development files for using the static Pthread wrapper of MassiveThreads
in development.

%package dl
Summary: Dynamic Pthread wrapper of the MassiveThreads library
Group: Development/Libraries

%description dl
This package provides libmyth-dl, a variant of the MassiveThreads
library, which overrides Pthreads API by preloading this library through
the LD_PRELOAD functionality.

%package dr
Summary: DAG recorder of the MassiveThreads library
Group: Development/Libraries
Requires: pygtk2, python2-matplotlib

%description dr
Library files for the MassiveThreas DAG recorder.

%package dr-devel
Summary: DAG recorder of the MassiveThreads library
Group: Development/Libraries
Requires: %{name}-dr = %{version}-%{release}

%description dr-devel
Tools, libraries, and header files for MassiveThreads DAG recorder library.

%package doc
Summary: Documentation for the MassiveThreads library
Group: Documentation
BuildArch: noarch

%description doc
This package contains Users' guide for the MassiveThreads library.

%prep
%setup -q -n %{name}-1.00
%patch -P 0 -p1
%patch -P 1 -p1
%patch -P 2 -p1
%patch -P 3 -p1
sed -i 's|^#!/usr/bin/python|#!/usr/bin/python2|' src/profiler/drview/drview
mkdir doc
tar -cf - \
  examples/* \
  docs/*.txt \
  docs/reference \
  docs/texinfo/massivethreads.info \
  docs/texinfo/gpl/tbb.png \
  docs/texinfo/svg/dag.png \
  docs/texinfo/img/drview_screenshot_resized.png \
| tar -C doc -xf -
for i in docs/reference/styles/main.css \
         docs/reference/javascript/main.js \
         docs/reference/javascript/prettify.js
do
  %{__sed} 's/\r//' "$i" | iconv -f iso-8859-1 -t utf-8 > "doc/$i"
done

%build
%define _lto_cflags %{nil}
%configure --disable-fast-install
make %{?_smp_mflags}

%check
make %{?_smp_mflags} -C tests build
MYTH_NUM_WORKERS=2 make check

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT
rm $RPM_BUILD_ROOT/%{_libdir}/*.la
rm $RPM_BUILD_ROOT/%{_libdir}/*.a
mkdir -p $RPM_BUILD_ROOT/%{_datadir}/%{name}
cp -p src/myth-ld.opts $RPM_BUILD_ROOT/%{_datadir}/%{name}
mkdir -p $RPM_BUILD_ROOT/%{_mandir}/man1
cp -p dag2any.1 drview.1 $RPM_BUILD_ROOT/%{_mandir}/man1

%post -p /sbin/ldconfig
%postun -p /sbin/ldconfig
%post ld -p /sbin/ldconfig
%postun ld -p /sbin/ldconfig
%post dl -p /sbin/ldconfig
%postun dl -p /sbin/ldconfig
%post dr -p /sbin/ldconfig
%postun dr -p /sbin/ldconfig

%files
%defattr(-,root,root,-)
%license COPYRIGHT
%doc README.md
%{_libdir}/libmyth.so.*

%files devel
%defattr(-,root,root,-)
%license COPYRIGHT
%doc README.md
%{_includedir}/mtbb
%{_includedir}/myth.h
%{_includedir}/myth
%{_includedir}/tpswitch
%{_libdir}/libmyth.so

%files doc
%defattr(-,root,root,-)
%license COPYRIGHT
%doc README.md
%doc doc/examples
%doc doc/docs

%files ld
%defattr(-,root,root,-)
%license COPYRIGHT
%doc README.md
%{_libdir}/libmyth-ld.so.*

%files ld-devel
%defattr(-,root,root,-)
%license COPYRIGHT
%doc README.md
%{_libdir}/libmyth-ld.so
%{_datadir}/%{name}/myth-ld.opts

%files dl
%defattr(-,root,root,-)
%license COPYRIGHT
%doc README.md
%{_libdir}/libmyth-dl.so*

%files dr
%defattr(-,root,root,-)
%license COPYRIGHT
%doc README.md
%{_bindir}/*
%{_libdir}/libdr.so.*
%{_mandir}/man1/dag2any.1.gz
%{_mandir}/man1/drview.1.gz

%files dr-devel
%defattr(-,root,root,-)
%license COPYRIGHT
%doc README.md
%{_includedir}/dag_recorder.h
%{_includedir}/dag_recorder_impl.h
%{_includedir}/dag_recorder_inl.h
%{_includedir}/papi_counters.h
%{_libdir}/libdr.so

%changelog
* Wed Sep 25 2024 Katsuhiro Ueno <katsu@ie.niigata-u.ac.jp> - 1.00-3
- skip tests related to memalign and pvalloc.
- stop dealing with pthread_yield on glibc 2.34.
- add MYTH_NUM_WORKERS=2 to make check

* Sun Jan  3 2021 Katsuhiro Ueno <katsu@riec.tohoku.ac.jp> - 1.00-2
- opt-out LTO

* Fri Dec 20 2019 Katsuhiro Ueno <katsu@riec.tohoku.ac.jp> - 1.00-1
- new upstream version

* Wed Apr 17 2019 Katsuhiro Ueno <katsu@riec.tohoku.ac.jp> - 0.99-1
- Initial package
