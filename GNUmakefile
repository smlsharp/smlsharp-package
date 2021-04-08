# GNU make is required.

all:
.DELETE_ON_ERROR:

DOCKERFLAGS = --security-opt=seccomp=unconfined

################

# VARNAMEs are variables. FuncNames are functions.

override B:=$(shell tput bold 2>/dev/null)
override R:=$(shell tput setaf 1 2>/dev/null)
override G:=$(shell tput setaf 2 2>/dev/null)
override E:=$(shell tput sgr0 2>/dev/null)

VERSION ?= $(shell echo $(lastword $(sort $(wildcard smlsharp-*.tar.gz))) \
                   | sed 's/^smlsharp-//;s/\.tar\.gz$$//')
ifeq ($(VERSION),)
$(error $(B)$(R)no source package found$(E))
endif
$(info $(B)$(G)VERSION: $(VERSION)$(E))

REPOS = repos
BUILD = BUILD
HOMEBREW = homebrew-smlsharp

$(BUILD)/:
	mkdir $@

ifeq ($(wildcard $(REPOS)/),)
$(error $(B)$(R)$(REPOS)/ is not found. Do "git clone"$(E))
endif

USER ?= $(shell whoami)
GIT_USER_NAME ?= Katsuhiro Ueno
GIT_USER_EMAIL ?= katsu@riec.tohoku.ac.jp

DEBDISTS = debian_sid debian_buster ubuntu_20.10 ubuntu_20.04
RPMDISTS = fedora_rawhide fedora_33 centos_8 centos_7
DEBARCH = amd64
RPMARCH = x86_64
SMLVERSION = $(VERSION)
SMLDEBREVISION = 1
SMLRPMREVISION = 1
MYTHVERSION = 1.00
MYTHDEBREVISION = 2
MYTHRPMREVISION = 2
RELVERSION = 1
override SMLPKGVERSION = $(subst -,~,$(SMLVERSION))
override MYTHPKGVERSION = $(subst -,~,$(MYTHVERSION))

MACOS_CODENAME := $(shell homebrew/codename.sh)
ifeq ($(MACOS_CODENAME),)
$(info $(R)This does not seem macOS; build for homebrew is skipped.$(E))
else
$(info $(G)macOS codename: $(MACOS_CODENAME)$(E))
ifeq ($(wildcard $(HOMEBREW)/),)
$(error $(B)$(R)$(HOMEBREW)/ is not found. Do "git clone"$(E))
endif
endif
override BREW_BOTTLE_URL = https://github.com/smlsharp/repos/raw/main/homebrew

################
# package version numbers and suffixes

# set the accurate version to RAWHIDEBUILD.
# rpm/*/build.sh will fail if RAWHIDEBUILD is not accurate.
RAWHIDEBUILD = fc35

override DistOs = $(patsubst %/,%,$(dir $(subst _,/,$1)))
override DistVer = $(notdir $(subst _,/,$1))
override DebBuild = \
  $(strip \
    $(if $(filter ubuntu,$(call DistOs,$1)),ppa1~ubuntu$(call DistVer,$1).1, \
      $(and $(filter-out debian_sid,$1),+1~$(call DistVer,$1)1)))
override RpmBuild = \
  $(strip \
    $(if $(filter centos,$(call DistOs,$1)),el$(call DistVer,$1), \
      $(if $(filter fedora_rawhide,$1),$(RAWHIDEBUILD), \
        $(if $(filter fedora,$(call DistOs,$1)),fc$(call DistVer,$1), \
          $(error RpmBuild: $1 is unknown)))))
# centos_7 => el7, fedora_30 => fc30, fedora_rawhide => $(RAWHIDEBUILD)

override SmlDebRevision = $(SMLDEBREVISION)$(call DebBuild,$1)
override SmlDebVersion = $(SMLPKGVERSION)-$(call SmlDebRevision,$1)
override SmlDebSuffix = _$(call SmlDebVersion,$1)_$(or $2,$(DEBARCH)).deb
override SmlDebDscSuffix = _$(call SmlDebVersion,$1).dsc
override SmlDebDebianSuffix = _$(call SmlDebVersion,$1).debian.tar.xz
override SmlRpmRevision = $(SMLRPMREVISION).$(call RpmBuild,$1)
override SmlRpmVersion = $(SMLPKGVERSION)-$(call SmlRpmRevision,$1)
override SmlRpmSuffix = -$(call SmlRpmVersion,$1).$(or $2,$(RPMARCH)).rpm
override SmlRpmSrcSuffix = -$(call SmlRpmVersion,$1).src.rpm

override MythDebRevision = $(MYTHDEBREVISION)$(call DebBuild,$1)
override MythDebVersion = $(MYTHPKGVERSION)-$(call MythDebRevision,$1)
override MythDebSuffix = _$(call MythDebVersion,$1)_$(or $2,$(DEBARCH)).deb
override MythDebDscSuffix = _$(call MythDebVersion,$1).dsc
override MythDebDebianSuffix = _$(call MythDebVersion,$1).debian.tar.xz
override MythRpmRevision = $(MYTHRPMREVISION).$(call RpmBuild,$1)
override MythRpmVersion = $(MYTHPKGVERSION)-$(call MythRpmRevision,$1)
override MythRpmSuffix = -$(call MythRpmVersion,$1).$(or $2,$(RPMARCH)).rpm
override MythRpmSrcSuffix = -$(call MythRpmVersion,$1).src.rpm

override RelRpmVariant = \
  $(strip \
    $(if $(filter fedora_rawhide,$1),rawhide/31-1, \
      $(if $(filter fedora,$(call DistOs,$1)),fedora/31-1, \
        $(if $(filter centos_7,$1),centos/7-1, \
          $(if $(filter centos_8,$1),centos/8-1, \
            $(error RelRpmVariant: $1 is unknown))))))
override RelRpmOs = $(patsubst %/,%,$(dir $(call RelRpmVariant,$1)))
override RelRpmVersion = $(subst /,-,$(call RelRpmVariant,$1))
override RelRpmSuffix = -$(call RelRpmVersion,$1).noarch.rpm
override RelRpmSrcSuffix = -$(call RelRpmVersion,$1).src.rpm

################
# repository directory hierarchy

override DebRootDir = $(call DistOs,$1)
override DebDistsDir = $(call DebRootDir,$1)/dists/$(call DistVer,$1)
override DebPoolDir = $(call DebRootDir,$1)/pool
override SmlDebPoolDir = $(call DebPoolDir,$1)/s/smlsharp
override MythDebPoolDir = $(call DebPoolDir,$1)/m/massivethreads

override RpmRootDir = $(call DistOs,$1)
override RpmBinDir = $(call RpmRootDir,$1)/$(call DistVer,$1)/$(RPMARCH)
override RpmSrcDir = $(call RpmRootDir,$1)/$(call DistVer,$1)/source
override RpmBinPackDir = $(call RpmBinDir,$1)/Packages
override RpmSrcPackDir = $(call RpmSrcDir,$1)/Packages

override MythDebFiles = \
  $1/$(call MythDebPoolDir,$2)/massivethreads$(call MythDebSuffix,$2,) \
  $1/$(call MythDebPoolDir,$2)/massivethreads-dev$(call MythDebSuffix,$2,) \
  $1/$(call MythDebPoolDir,$2)/massivethreads-ld$(call MythDebSuffix,$2,) \
  $1/$(call MythDebPoolDir,$2)/massivethreads-ld-dev$(call MythDebSuffix,$2,) \
  $1/$(call MythDebPoolDir,$2)/massivethreads-dr$(call MythDebSuffix,$2,) \
  $1/$(call MythDebPoolDir,$2)/massivethreads-dr-dev$(call MythDebSuffix,$2,) \
  $1/$(call MythDebPoolDir,$2)/massivethreads-doc$(call MythDebSuffix,$2,all) \
  $1/$(call MythDebPoolDir,$2)/massivethreads$(call MythDebDscSuffix,$2) \
  $1/$(call MythDebPoolDir,$2)/massivethreads$(call MythDebDebianSuffix,$2) \
  $1/$(call MythDebPoolDir,$2)/massivethreads_$(MYTHPKGVERSION).orig.tar.gz
override MythRpmFiles = \
  $1/$(call RpmBinPackDir,$2)/massivethreads$(call MythRpmSuffix,$2,) \
  $1/$(call RpmBinPackDir,$2)/massivethreads-devel$(call MythRpmSuffix,$2,) \
  $1/$(call RpmBinPackDir,$2)/massivethreads-ld$(call MythRpmSuffix,$2,) \
  $1/$(call RpmBinPackDir,$2)/massivethreads-ld-devel$(call MythRpmSuffix,$2,) \
  $1/$(call RpmBinPackDir,$2)/massivethreads-dl$(call MythRpmSuffix,$2,) \
  $1/$(call RpmBinPackDir,$2)/massivethreads-dr$(call MythRpmSuffix,$2,) \
  $1/$(call RpmBinPackDir,$2)/massivethreads-dr-devel$(call MythRpmSuffix,$2,) \
  $1/$(call RpmBinPackDir,$2)/massivethreads-doc$(call MythRpmSuffix,$2,noarch)\
  $1/$(call RpmSrcPackDir,$2)/massivethreads$(call MythRpmSrcSuffix,$2)
override SmlDebFiles = \
  $1/$(call SmlDebPoolDir,$2)/smlsharp$(call SmlDebSuffix,$2,) \
  $1/$(call SmlDebPoolDir,$2)/smlsharp$(call SmlDebDscSuffix,$2,) \
  $1/$(call SmlDebPoolDir,$2)/smlsharp$(call SmlDebDebianSuffix,$2,) \
  $1/$(call SmlDebPoolDir,$2)/smlsharp_$(SMLPKGVERSION).orig.tar.gz
override SmlRpmFiles = \
  $1/$(call RpmBinPackDir,$2)/smlsharp$(call SmlRpmSuffix,$2,) \
  $1/$(call RpmBinPackDir,$2)/smlsharp$(call SmlRpmSrcSuffix,$2)
override RelDebFiles = \
  $1/$(call DebDistsDir,$2)/sources.list \
  $1/$(call DebDistsDir,$2)/smlsharp-archive-keyring.gpg
override RelRpmFiles = \
  $1/$(call RpmRootDir,$2)/smlsharp-release$(call RelRpmSuffix,$2) \
  $1/$(call RpmRootDir,$2)/smlsharp-release$(call RelRpmSrcSuffix,$2)

override MYTH_BOTTLE_FILE = \
  massivethreads-$(MYTHVERSION).$(MACOS_CODENAME).bottle.tar.gz
override SML_BOTTLE_FILE = \
  smlsharp-$(SMLVERSION).$(MACOS_CODENAME).bottle.tar.gz
override MYTH_BREW_FILES = \
  $(REPOS)/homebrew/$(MYTH_BOTTLE_FILE)
override SML_BREW_FILES = \
  $(REPOS)/homebrew/$(SML_BOTTLE_FILE)

################
# if the packages has already been published, use them instead of building them.

override define Def
ifneq ($$(wildcard $$(call $1,$$(REPOS),$4)),)
override BUILD_$1_$4 =
else
override BUILD_$1_$4 = $$(BUILD)/$2-$$($3VERSION)_$4.tar
endif
endef
$(foreach i,$(DEBDISTS),$(eval $(call Def,MythDebFiles,massivethreads,MYTH,$i)))
$(foreach i,$(RPMDISTS),$(eval $(call Def,MythRpmFiles,massivethreads,MYTH,$i)))
$(foreach i,$(DEBDISTS),$(eval $(call Def,SmlDebFiles,smlsharp,SML,$i)))
$(foreach i,$(RPMDISTS),$(eval $(call Def,SmlRpmFiles,smlsharp,SML,$i)))
$(foreach i,$(DEBDISTS),$(eval $(call Def,RelDebFiles,release,REL,$i)))
$(foreach i,$(RPMDISTS),$(eval $(call Def,RelRpmFiles,release,REL,$i)))

override MythDebBuild = $(BUILD_MythDebFiles_$1)
override MythRpmBuild = $(BUILD_MythRpmFiles_$1)
override SmlDebBuild = $(BUILD_SmlDebFiles_$1)
override SmlRpmBuild = $(BUILD_SmlRpmFiles_$1)
override RelDebBuild = $(BUILD_RelDebFiles_$1)
override RelRpmBuild = $(BUILD_RelRpmFiles_$1)

ifneq ($(MACOS_CODENAME),) 
ifneq ($(wildcard $(MYTH_BREW_FILES)),)
override BUILD_MYTH_BREW =
else
override BUILD_MYTH_BREW = $(BUILD)/massivethreads-$(MYTHVERSION)_homebrew.tar
endif
ifneq ($(wildcard $(SML_BREW_FILES)),)
override BUILD_SML_BREW =
else
override BUILD_SML_BREW = $(BUILD)/smlsharp-$(SMLVERSION)_homebrew.tar
endif
endif

#################
# top-level recipe

.PHONY: myth-deb myth-rpm myth-brew myth
myth-deb: $(foreach i,$(DEBDISTS),$(call MythDebBuild,$i))
myth-rpm: $(foreach i,$(RPMDISTS),$(call MythRpmBuild,$i))
myth-brew: $(BUILD_MYTH_BREW)
myth: myth-deb myth-rpm myth-brew

.PHONY: smlsharp-deb smlsharp-rpm smlsharp-brew smlsharp
smlsharp-deb: $(foreach i,$(DEBDISTS),$(call SmlDebBuild,$i))
smlsharp-rpm: $(foreach i,$(RPMDISTS),$(call SmlRpmBuild,$i))
smlsharp-brew: $(BUILD_SML_BREW)
smlsharp: smlsharp-deb smlsharp-rpm smlsharp-brew

.PHONY: release-deb release-rpm release
release-deb: $(foreach i,$(DEBDISTS),$(call RelDebBuild,$i))
release-rpm: $(foreach i,$(RPMDISTS),$(call RelRpmBuild,$i))
release: release-deb release-rpm

.PHONY: deb rpm
deb: myth-deb smlsharp-deb release-deb $(BUILD)/deb.tar $(BUILD)/ubuntu.tar
rpm: myth-rpm smlsharp-rpm release-rpm $(BUILD)/rpm.tar
brew: myth-brew smlsharp-brew $(BUILD)/homebrew.tar

.PHONY: repo
repo-deb: $(BUILD)/deb.tar $(BUILD)/ubuntu.tar
repo-rpm: $(BUILD)/rpm.tar
repo-brew: $(BUILD)/homebrew.tar
repo: repo-deb repo-rpm repo-brew

.PHONY: all
all: myth smlsharp release $(BUILD)/all.tar $(BUILD)/ppa.tar | $(REPOS)/


#################
# utilities

override define SHA256
  sha256 () { \
    sum=`openssl dgst -sha256 "$$@"` && \
    echo "$$sum" && \
    sum=`echo "$$sum" | sed 's/^.*[= ]//'`; \
  }
endef

override define HttpGet
  rm -f $@
  curl -L -o $@ $1
  $(SHA256); set -e; sha256 $@; test "_$$sum" = '_$(strip $2)'
endef


#################
# recipe for massivethreads

$(BUILD)/massivethreads-1.00.tar.gz: \
| $(BUILD)/
	$(call HttpGet,\
	https://github.com/massivethreads/massivethreads/archive/v1.00.tar.gz, \
	85b83ff096e2984c725faa4814a9c5e77c143198660ec60118b897afdfd05f98)

$(BUILD)/massivethreads-$(MYTHVERSION)_manpages.patch: \
  massivethreads/man/dag2any.1 \
  massivethreads/man/drview.1 \
| $(BUILD)/
	-rm -f $@
	set -ex; \
	l=`git log -1 --format='%ad' --date=raw -- massivethreads/man`; \
	d=`echo "$$l" | cut -d\  -f1`; \
	tmp=`mktemp -d`; \
	trap 'rm -rf "$$tmp"' EXIT; \
	trap 'exit 127' INT QUIT; \
	mkdir "$$tmp/a" "$$tmp/b"; \
	cp $^ "$$tmp/b"; \
	perl -e 'utime @ARGV' "$$d" "$$d" "$$tmp/b/"*; \
	(cd "$$tmp" && diff -ruN a b || :) > $@

override define Rule
ifeq ($$(call MythDebBuild,$1),)
$$(BUILD)/massivethreads-$$(MYTHVERSION)_$1.tar: \
  $$(call MythDebFiles,$$(REPOS),$1) \
| $$(BUILD)/
	pax -w -s '|^.*/||' $$(call MythDebFiles,$$(REPOS),$1) > $$@
else
$$(BUILD)/massivethreads-$$(MYTHVERSION)_$1.tar: \
  $$(BUILD)/massivethreads-$$(MYTHVERSION).tar.gz \
  massivethreads/man/dag2any.1 \
  massivethreads/man/drview.1 \
  $$(shell find deb/massivethreads/debian -type f) \
  deb/massivethreads/build.sh \
| $$(BUILD)/
	@printf '%s\n' '$$(B)$$(R)**** Build massivethreads for $1 ****$$(E)'
	docker run --rm --sig-proxy=false $(DOCKERFLAGS) -i -w /root \
	  -v '$$(realpath .):/host:ro' \
	  -e 'version=$$(MYTHVERSION)' \
	  -e 'pkgversion=$$(MYTHPKGVERSION)' \
	  -e 'debrevision=$$(MYTHDEBREVISION)' \
	  -e 'debdist=$$(call DistVer,$1)' \
	  -e 'debarch=$$(DEBARCH)' \
	  -e 'debbuild=$$(call DebBuild,$1)' \
	  -e 'source=$$(BUILD)/massivethreads-$$(MYTHVERSION).tar.gz' \
	  buildsmlsharp:$1 \
	  /host/deb/massivethreads/build.sh > $$@
endif
endef
$(foreach i,$(DEBDISTS),$(eval $(call Rule,$i)))

override define Rule
ifeq ($$(call MythRpmBuild,$1),)
$$(BUILD)/massivethreads-$$(MYTHVERSION)_$1.tar: \
  $$(call MythRpmFiles,$$(REPOS),$1) \
| $$(BUILD)/
	pax -w -s '|^.*/||' $$(call MythRpmFiles,$$(REPOS),$1) > $$@
else
$$(BUILD)/massivethreads-$$(MYTHVERSION)_$1.tar: \
  $$(BUILD)/massivethreads-$$(MYTHVERSION).tar.gz \
  $$(BUILD)/massivethreads-$$(MYTHVERSION)_manpages.patch \
  rpm/massivethreads/massivethreads.spec \
  rpm/massivethreads/build.sh \
  rpm/version.sh \
| $$(BUILD)/
	@printf '%s\n' '$$(B)$$(R)**** Build massivethreads for $1 ****$$(E)'
	docker run --rm --sig-proxy=false $(DOCKERFLAGS) -i -w /root \
	  -v '$$(realpath .):/host:ro' \
	  -e 'version=$$(MYTHVERSION)' \
	  -e 'pkgversion=$$(MYTHPKGVERSION)' \
	  -e 'rpmrevision=$$(MYTHRPMREVISION)' \
	  -e 'rpmbuild=$$(call RpmBuild,$1)' \
	  -e 'rpmarch=$$(RPMARCH)' \
	  -e 'source=$$(BUILD)/massivethreads-$$(MYTHVERSION).tar.gz' \
	  -e 'man=$$(BUILD)/massivethreads-$$(MYTHVERSION)_manpages.patch' \
	  buildsmlsharp:$1 \
	  /host/rpm/massivethreads/build.sh > $$@
endif
endef
$(foreach i,$(RPMDISTS),$(eval $(call Rule,$i)))

$(BUILD)/massivethreads-1.00.rb: \
  homebrew/massivethreads.rb \
| $(BUILD)/
	cp $< $@

ifeq ($(BUILD_MYTH_BREW),)
$(BUILD)/massivethreads-$(MYTHVERSION)_homebrew.tar: \
  $(MYTH_BREW_FILES) \
  $(HOMEBREW)/Formula/massivethreads.rb \
| $(BUILD)/
	pax -w -s '|^.*/||' $^ > $@
else
$(BUILD)/massivethreads-$(MYTHVERSION)_homebrew.tar: \
  $(BUILD)/massivethreads-$(MYTHVERSION).tar.gz \
  $(BUILD)/massivethreads-$(MYTHVERSION).rb \
  homebrew/build.sh \
| $(BUILD)/
	@printf '%s\n' '$(B)$(R)**** Build massivethreads for homebrew ****$(E)'
	bottle_url='$(BREW_BOTTLE_URL)' \
	prerequisite= \
	rbfile=$(BUILD)/massivethreads-$(MYTHVERSION).rb \
	source=$(BUILD)/massivethreads-$(MYTHVERSION).tar.gz \
	homebrew/build.sh autoconf automake libtool > $@
endif


#################
# recipe for smlsharp

$(BUILD)/smlsharp-$(SMLVERSION)_deb.changelog: \
  smlsharp-$(SMLVERSION).history \
  deb/smlsharp/genchangelog.sh \
| $(BUILD)/
	deb/smlsharp/genchangelog.sh < $< > $@

$(BUILD)/smlsharp-$(SMLVERSION)_rpm.changelog: \
  smlsharp-$(SMLVERSION).history \
  rpm/smlsharp/genchangelog.sh \
| $(BUILD)/
	rpm/smlsharp/genchangelog.sh < $< > $@

override define Rule
$$(BUILD)/smlsharp-$$(SMLVERSION)_$1.tar: \
  smlsharp-$$(SMLVERSION).tar.gz \
  $$(BUILD)/smlsharp-$$(SMLVERSION)_deb.changelog \
  $$(BUILD)/massivethreads-$$(MYTHVERSION)_$1.tar \
  $$(shell find deb/smlsharp/debian -type f) \
  deb/smlsharp/build.sh
	@printf '%s\n' '$$(B)$$(R)**** Build smlsharp for $1 ****$$(E)'
	docker run --rm --sig-proxy=false $(DOCKERFLAGS) -i -w /root \
	  -v '$$(realpath .):/host:ro' \
	  -e 'version=$$(SMLVERSION)' \
	  -e 'pkgversion=$$(SMLPKGVERSION)' \
	  -e 'debrevision=$$(SMLDEBREVISION)' \
	  -e 'debdist=$$(call DistVer,$1)' \
	  -e 'debarch=$$(DEBARCH)' \
	  -e 'debbuild=$$(call DebBuild,$1)' \
	  -e 'source=$$<' \
	  -e 'changelog=$$(BUILD)/smlsharp-$$(SMLVERSION)_deb.changelog' \
	  -e 'debmyth=$$(BUILD)/massivethreads-$$(MYTHVERSION)_$1.tar' \
	  buildsmlsharp:$1 \
	  /host/deb/smlsharp/build.sh > $$@
endef
$(foreach i,$(DEBDISTS),$(eval $(call Rule,$i)))

override define Rule
$$(BUILD)/smlsharp-$$(SMLVERSION)_$1.tar: \
  smlsharp-$$(SMLVERSION).tar.gz \
  $$(BUILD)/smlsharp-$$(SMLVERSION)_rpm.changelog \
  $$(BUILD)/massivethreads-$$(MYTHVERSION)_$1.tar \
  rpm/smlsharp/smlsharp.spec \
  rpm/smlsharp/build.sh \
  rpm/version.sh
	@printf '%s\n' '$$(B)$$(R)**** Build smlsharp for $1 ****$$(E)'
	docker run --rm --sig-proxy=false $(DOCKERFLAGS) -i -w /root \
	  -v '$$(realpath .):/host:ro' \
	  -e 'version=$$(SMLVERSION)' \
	  -e 'pkgversion=$$(SMLPKGVERSION)' \
	  -e 'rpmrevision=$$(RPMREVISION)' \
	  -e 'rpmbuild=$$(call RpmBuild,$1)' \
	  -e 'rpmarch=$$(RPMARCH)' \
	  -e 'source=$$<' \
	  -e 'changelog=$$(BUILD)/smlsharp-$$(SMLVERSION)_rpm.changelog' \
	  -e 'rpmmyth=$$(BUILD)/massivethreads-$$(MYTHVERSION)_$1.tar' \
	  buildsmlsharp:$1 \
	  /host/rpm/smlsharp/build.sh > $$@
endef
$(foreach i,$(RPMDISTS),$(eval $(call Rule,$i)))

SMLSHARP_RB_AWK = '\
  {print}\
  /^ *system ".\/configure"/\
  {print "system \"make\", \"src/config/main/Version.sml\" \#\#D\#\#";\
   print "inreplace \"src/config/main/Version.sml\", \#\#D\#\#";\
   print " HOMEBREW_PREFIX, \"/usr/local\" \#\#D\#\#"}\
  /^ *system \"make\", \"all\"/\
  {print "inreplace \"src/config.mk\", \#\#D\#\#";\
   print " HOMEBREW_PREFIX, \"/usr/local\" \#\#D\#\#";\
   print "system \"make\", \"-t\" \#\#D\#\#"}\
'

$(BUILD)/smlsharp-$(SMLVERSION).rb: \
  smlsharp-$(SMLVERSION).tar.gz \
  homebrew/smlsharp.rb \
| $(BUILD)/
	awk $(SMLSHARP_RB_AWK) homebrew/smlsharp.rb > $@
	sed -i '' '/test do/,/end/s/^/##K##/' $@
	sed -i '' 's/0.0.0-pre0/$(SMLVERSION)/g' $@
	$(SHA256); \
	set -ex; \
	sha256 $<; \
	sed -i '' "/sha256/s/\".*\"/\"$$sum\"/" $@

$(BUILD)/smlsharp-$(SMLVERSION)_homebrew.tar: \
  smlsharp-$(SMLVERSION).tar.gz \
  $(BUILD)/massivethreads-$(MYTHVERSION)_homebrew.tar \
  $(BUILD)/smlsharp-$(SMLVERSION).rb \
  homebrew/build.sh \
| $(BUILD)/
	@printf '%s\n' '$(B)$(R)**** Build smlsharp for homebrew ****$(E)'
	bottle_url='$(BREW_BOTTLE_URL)' \
	prerequisite=$(BUILD)/massivethreads-$(MYTHVERSION)_homebrew.tar \
	rbfile=$(BUILD)/smlsharp-$(SMLVERSION).rb \
	source=$< \
	no_cellar_any=yes \
	homebrew/build.sh gmp xz llvm@11 massivethreads: > $@


#################
# recipe for release

override define Rule
$$(BUILD)/release-$(RELVERSION)_$1.tar: \
  deb/smlsharp.list.in \
  signing-key-pub.asc \
| $$(BUILD)/
	@printf '%s\n' '$$(B)$$(R)**** Build smlsharp-release for $1 ****$$(E)'
	@set -ex; \
	tmp=`mktemp -d`; \
	trap 'rm -rf "$$$$tmp"' EXIT; \
	trap 'exit 127' INT QUIT; \
	sed -e 's/@OS@/$$(call DistOs,$1)/;s/@VER@/$$(call DistVer,$1)/' \
	  deb/smlsharp.list.in > "$$$$tmp/smlsharp.list"; \
	gpg --dearmor -o "$$$$tmp/smlsharp-archive-keyring.gpg" \
	  signing-key-pub.asc; \
	(cd "$$$$tmp" && pax -w *) > $$@
endef
$(foreach i,$(DEBDISTS),$(eval $(call Rule,$i)))

override define Rule
$$(BUILD)/release-$(RELVERSION)_$1.tar: \
  signing-key-pub.asc \
  rpm/smlsharp-release/yum.repos.d/smlsharp.$$(call RelRpmOs,$1).repo \
  rpm/smlsharp-release/smlsharp-release-$(call RelRpmVersion,$1).spec \
  rpm/smlsharp-release/build.sh \
| $$(BUILD)/
	@printf '%s\n' '$$(B)$$(R)**** Build smlsharp-release for $1 ****$$(E)'
	docker run --rm --sig-proxy=false $(DOCKERFLAGS) -i -w /root \
	  -v '$$(realpath .):/host' \
	  -e 'rpmversion=$$(call RelRpmVersion,$1)' \
	  buildsmlsharp:$1 \
	  /host/rpm/smlsharp-release/build.sh > $$@
endef
$(foreach i,$(RPMDISTS),$(eval $(call Rule,$i)))


#################
# recipe for DEB repositories

$(BUILD)/deb.tar: \
  $(foreach i,$(DEBDISTS), \
    $(call MythDebBuild,$i) \
    $(call SmlDebBuild,$i) \
    $(call RelDebBuild,$i)) \
  signing-key_$(USER).asc \
  deb/repo.sh \
| $(BUILD)/ \
  $(REPOS)/
	@printf '%s\n' '$(B)$(R)**** Build APT repositories ****$(E)'
	gpg --decrypt 'signing-key_$(USER).asc' \
	| docker run --rm --sig-proxy=false $(DOCKERFLAGS) -i -w /root \
	    --tmpfs /mnt/ram:size=16m,mode=700 \
	    -v '$(realpath .):/host:ro' \
	    -e 'rootbasedir=$(REPOS)' \
	    -e 'roots=$(sort $(foreach i, \
                        $(filter-out ubuntu_%,$(DEBDISTS)), \
                        $(call DebRootDir,$i)))' \
	    buildsmlsharp:$(firstword $(DEBDISTS)) \
	    /host/deb/repo.sh \
	    $(foreach i,$(DEBDISTS), \
	      $(and $(call MythDebBuild,$i),\
	        $(call MythDebBuild,$i) \
	        $(call DistOs,$i)/$(call DistVer,$i) \
	        $(call MythDebPoolDir,$i)) \
	      $(and $(call SmlDebBuild,$i),\
	        $(call SmlDebBuild,$i) \
	        $(call DistOs,$i)/$(call DistVer,$i) \
	        $(call SmlDebPoolDir,$i)) \
	      $(and $(call RelDebBuild,$i),\
	        $(call RelDebBuild,$i) \
	        $(call DistOs,$i)/$(call DistVer,$i) \
	        $(call DebDistsDir,$i))) \
	    > $@

$(BUILD)/ppa.tar: \
  $(foreach i,$(filter ubuntu_%,$(DEBDISTS)), \
    $(call MythDebBuild,$i) \
    $(call SmlDebBuild,$i)) \
  ppa-key_$(USER).asc \
  deb/src.sh \
| $(BUILD)/ \
  $(REPOS)/
	@printf '%s\n' '$(B)$(R)**** Build Ubuntu source packages ****$(E)'
	gpg --decrypt 'ppa-key_$(USER).asc' \
	| docker run --rm --sig-proxy=false $(DOCKERFLAGS) -i -w /root \
	    --tmpfs /mnt/ram:size=16m,mode=700 \
	    -v '$(realpath .):/host:ro' \
	    buildsmlsharp:$(firstword $(DEBDISTS)) \
	    /host/deb/src.sh \
	    $(foreach i,$(filter ubuntu_%,$(DEBDISTS)), \
	      $(call MythDebBuild,$i) \
	      $(call SmlDebBuild,$i)) \
	    > $@

#################
# recipe for RPM repositories

$(BUILD)/rpm.tar: \
  $(foreach i,$(RPMDISTS), \
    $(call MythRpmBuild,$i) \
    $(call SmlRpmBuild,$i) \
    $(call RelRpmBuild,$i)) \
  signing-key_$(USER).asc \
  rpm/repo.sh \
| $(BUILD)/ \
  $(REPOS)/
	@printf '%s\n' '$(B)$(R)**** Build YUM repositories ****$(E)'
	gpg --decrypt 'signing-key_$(USER).asc' \
	| docker run --rm --sig-proxy=false -i -w /root \
	    --tmpfs /mnt/ram:size=16m,mode=700 \
	    -v '$(realpath .):/host:ro' \
	    -e 'rootbasedir=$(REPOS)' \
	    -e 'roots=$(sort $(foreach i,$(RPMDISTS),$(call RpmRootDir,$i)))' \
	    buildsmlsharp:$(firstword $(RPMDISTS)) \
	    sh /host/rpm/repo.sh \
	    $(foreach i,$(RPMDISTS), \
	      $(and $(call MythRpmBuild,$i),\
	        $(call MythRpmBuild,$i) \
	        $(call RpmBinPackDir,$i) \
	        $(call RpmSrcPackDir,$i)) \
	      $(and $(call SmlRpmBuild,$i),\
	        $(call SmlRpmBuild,$i) \
	        $(call RpmBinPackDir,$i) \
	        $(call RpmSrcPackDir,$i)) \
	      $(and $(call RelRpmBuild,$i),\
	        $(call RelRpmBuild,$i) \
	        $(call RpmRootDir,$i) \
	        $(call RpmRootDir,$i))) \
	    > $@


#################
# recipe for Homebrew repository

ifeq ($(BUILD_MYTH_BREW)$(BUILD_SML_BREW),)
$(BUILD)/homebrew.tar: \
| $(BUILD)/
	@set -ex; \
	tmp=`mktemp -d`; \
	trap 'rm -rf "$$tmp"' EXIT; \
	trap 'exit 127' INT QUIT; \
	mkdir "$$tmp/homebrew"; \
	tar -C "$$tmp" -cf - homebrew > $@
else
$(BUILD)/homebrew.tar: \
  $(BUILD_MYTH_BREW) \
  $(BUILD_SML_BREW) \
| $(BUILD)/
	@printf '%s\n' '$(B)$(R)**** Build Homebrew repository ****$(E)'
	@set -ex; \
	tmp=`mktemp -d`; \
	trap 'rm -rf "$$tmp"' EXIT; \
	trap 'exit 127' INT QUIT; \
	mkdir "$$tmp/homebrew"; \
	for i in $(BUILD_MYTH_BREW) $(BUILD_SML_BREW); do \
	  (cd "$$tmp/homebrew" && pax -rv '*.bottle.tar.gz') < "$$i"; \
	done; \
	(cd "$$tmp" && pax -w homebrew) > $@
endif

.PHONY: install-brew
ifeq ($(BUILD_MYTH_BREW)$(BUILD_SML_BREW),)
install-brew:
else
install-brew: \
  $(BUILD_MYTH_BREW) \
| $(HOMEBREW)/
	@set -ex; \
	tmp=`mktemp -d`; \
	trap 'rm -rf "$$tmp"' EXIT; \
	trap 'exit 127' INT QUIT; \
	git clone $(HOMEBREW) "$$tmp/a" \
	  --config gpg.program=$(realpath .)/homebrew/gpg.sh \
	  --config user.signingKey='@SIGNINGKEY@' \
	  --config user.name='$(GIT_USER_NAME)' \
	  --config user.email='$(GIT_USER_EMAIL)'; \
	(cd "$$tmp/a" && git checkout master && git checkout -b new); \
	$(and $(BUILD_MYTH_BREW), \
	  mkdir -p "$$tmp/a/Formula"; \
	  (cd "$$tmp/a/Formula" && pax -rv '*.rb') < $(BUILD_MYTH_BREW); \
	  gpg --decrypt signing-key_$(USER).asc \
	  | (exec 9<&0 0</dev/null; \
	     cd "$$tmp/a"; \
	     git add -A; \
	     git commit -S -m 'massivethreads-$(MYTHVERSION)');) \
	$(and $(BUILD_SML_BREW), \
	  mkdir -p "$$tmp/a/Formula"; \
	  (cd "$$tmp/a/Formula" && pax -rv '*.rb') < $(BUILD_SML_BREW); \
	  gpg --decrypt signing-key_$(USER).asc \
	  | (exec 9<&0 0</dev/null; \
	     cd "$$tmp/a"; \
	     git add -A; \
	     git commit -S -m 'smlsharp-$(SMLVERSION)');) \
	(cd $(HOMEBREW); \
	 git fetch "$$tmp/a" new; \
	 git branch new FETCH_HEAD)
endif


################
# the goal

$(BUILD)/all.tar: \
  $(BUILD)/deb.tar \
  $(BUILD)/rpm.tar \
  $(BUILD)/homebrew.tar \
| $(BUILD)/
	@set -ex; \
	tmp=`mktemp -d`; \
	trap 'rm -rf "$$tmp"' EXIT; \
	trap 'exit 127' INT QUIT; \
	mkdir -p "$$tmp"; \
	tar -xf $(BUILD)/deb.tar -C "$$tmp"; \
	tar -xf $(BUILD)/rpm.tar -C "$$tmp"; \
	tar -xf $(BUILD)/homebrew.tar -C "$$tmp"; \
	tar -cf - -C "$$tmp" . > $@

.PHONY: install
install: $(BUILD)/all.tar
	@set -ex; \
	tmp=`mktemp -d`; \
	trap 'rm -rf "$$tmp"' EXIT; \
	trap 'exit 127' INT QUIT; \
	git clone $(REPOS) "$$tmp/a"; \
	(cd "$$tmp/a" && git checkout main && git checkout -b new); \
	tar -xf $(BUILD)/all.tar -C "$$tmp/a"; \
	(cd "$$tmp/a"; \
	 find . -type f -size 0 -exec git rm -f '{}' +; \
	 git add -A; \
	 git commit -m 'Update for smlsharp $(SMLVERSION)'); \
	cd $(REPOS); \
	git fetch "$$tmp/a" new; \
	git branch new FETCH_HEAD
