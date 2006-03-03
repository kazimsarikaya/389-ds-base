#
# BEGIN COPYRIGHT BLOCK
# This Program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; version 2 of the License.
# 
# This Program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with
# this Program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place, Suite 330, Boston, MA 02111-1307 USA.
# 
# In addition, as a special exception, Red Hat, Inc. gives You the additional
# right to link the code of this Program with code not covered under the GNU
# General Public License ("Non-GPL Code") and to distribute linked combinations
# including the two, subject to the limitations in this paragraph. Non-GPL Code
# permitted under this exception must only link to the code of this Program
# through those well defined interfaces identified in the file named EXCEPTION
# found in the source code files (the "Approved Interfaces"). The files of
# Non-GPL Code may instantiate templates or use macros or inline functions from
# the Approved Interfaces without causing the resulting work to be covered by
# the GNU General Public License. Only Red Hat, Inc. may make changes or
# additions to the list of Approved Interfaces. You must obey the GNU General
# Public License in all respects for all of the Program code and other code used
# in conjunction with the Program except the Non-GPL Code covered by this
# exception. If you modify this file, you may extend this exception to your
# version of the file, but you are not obligated to do so. If you do not wish to
# provide this exception without modification, you must delete this exception
# statement from your version and license this file solely under the GPL without
# exception. 
# 
# 
# Copyright (C) 2005 Red Hat, Inc.
# All rights reserved.
# END COPYRIGHT BLOCK
#
# This file defines dependencies for components and 
# tells how to satisfy thoes dependencies

# For internal components, we use ftp_puller_new.pl
# We should consider using wget or something like that
# in the future.

BUILD_MODE = ext

ifndef NSPR_SOURCE_ROOT
NSPR_IMPORT = $(COMPONENTS_DIR)/nspr20/$(NSPR_RELDATE)/$(FULL_RTL_OBJDIR)
NSPR_DEP = $(NSPR_LIBPATH)/libnspr4.$(LIB_SUFFIX)

ifndef NSPR_PULL_METHOD
NSPR_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(NSPR_DEP): $(NSCP_DISTDIR_FULL_RTL)
ifdef COMPONENT_DEPS
	$(FTP_PULL) -method $(NSPR_PULL_METHOD) \
		-objdir $(NSPR_BUILD_DIR) -componentdir $(NSPR_IMPORT) \
		-files lib,include
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component NSPR file $@" ; \
	fi
endif # NSPR_SOURCE_ROOT

ifndef DBM_SOURCE_ROOT
DBM_IMPORT = $(COMPONENTS_DIR)/dbm/$(DBM_RELDATE)/$(NSOBJDIR_NAME)
ifeq ($(ARCH), WINNT)
  DBM_DEP = $(DBM_LIBPATH)/dbm.$(LIB_SUFFIX)
else
  DBM_DEP = $(DBM_LIBPATH)/libdbm.$(LIB_SUFFIX)
endif

ifndef DBM_PULL_METHOD
DBM_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(DBM_DEP): $(NSCP_DISTDIR_FULL_RTL)
ifdef COMPONENT_DEPS
	$(FTP_PULL) -method $(DBM_PULL_METHOD) \
		-objdir $(DBM_BUILD_DIR) -componentdir $(DBM_IMPORT)/.. \
		-files xpheader.jar -unzip $(DBM_INCDIR)
	$(FTP_PULL) -method $(DBM_PULL_METHOD) \
		-objdir $(DBM_BUILD_DIR) -componentdir $(DBM_IMPORT) \
		-files mdbinary.jar -unzip $(DBM_BUILD_DIR)
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component DBM file $@" ; \
	fi
endif # DBM_SOURCE_ROOT

ifndef SECURITY_SOURCE_ROOT
SECURITY_IMPORT = $(COMPONENTS_DIR)/nss/$(SECURITY_RELDATE)/$(FULL_RTL_OBJDIR)
ifeq ($(ARCH), WINNT)
  SECURITY_DEP = $(SECURITY_LIBPATH)/ssl3.$(DLL_SUFFIX)
else
  SECURITY_DEP = $(SECURITY_LIBPATH)/libssl3.$(DLL_SUFFIX)
endif
# if building 64 bit version, also need the 32 bit version of nssckbi.so
# rename it as nssckbi32.so
ifeq ($(USE_64), 1)
# assumes there is a 32 bit version
  SHARED32_BUILD_DIR = $(NSCP_DISTDIR_FULL_RTL)/shared32
  NSS32_IMPORT = $(subst $(NS64TAG),,$(SECURITY_IMPORT))
  NSS32_BINNAMES = modutil
  NSS32_LIBNAMES = $(SECURITY_LIBNAMES.pkg)
  NSS32_NEED_CHK = $(SECURITY_NEED_CHK)
  ifeq ($(ARCH), SOLARIS)
    NSS32_LIBNAMES += freebl_hybrid_3 freebl_pure32_3
# these libs have a corresponding .chk file
    NSS32_NEED_CHK += freebl_hybrid_3 freebl_pure32_3
  endif
  ifeq ($(ARCH), HPUX)
    NSS32_LIBNAMES += freebl_hybrid_3 freebl_pure32_3
# these libs have a corresponding .chk file
    NSS32_NEED_CHK += freebl_hybrid_3 freebl_pure32_3
  endif
  NSSCKBI_FILE = $(LIB_PREFIX)nssckbi.$(DLL_SUFFIX)
  NSSCKBI32_FILE = $(LIB_PREFIX)nssckbi32.$(DLL_SUFFIX)
  NSS32_PULLFILES = bin/modutil lib/$(NSSCKBI_FILE) $(addprefix lib/$(LIB_PREFIX),$(addsuffix .$(DLL_SUFFIX),$(NSS32_LIBNAMES))) $(addprefix lib/$(LIB_PREFIX),$(addsuffix .chk,$(NSS32_NEED_CHK)))

  NSPR32_IMPORT = $(subst $(NS64TAG),,$(NSPR_IMPORT))
  NSPR32_LIBNAMES = $(NSPR_LIBNAMES)
  NSPR32_PULLFILES = lib/$(LIB_PREFIX)$(subst $(SPACE),$(COMMA)lib/$(LIB_PREFIX),$(addsuffix .$(DLL_SUFFIX),$(NSPR_LIBNAMES)))

# we need to package the root cert file in the alias directory
  PACKAGE_SRC_DEST += $(SHARED32_BUILD_DIR)/lib/$(NSSCKBI32_FILE) alias
# all other files go under shared32/bin or /lib
  PACKAGE_SRC_DEST += $(SHARED32_BUILD_DIR)/bin/modutil shared32/bin

# do not need redundant copy of nssckbi
  NSS32_NSPR32_SRC_LIBS = $(filter-out $(SHARED32_BUILD_DIR)/lib/$(NSSCKBI32_FILE),$(wildcard $(SHARED32_BUILD_DIR)/lib/*))
  PACKAGE_SRC_DEST += $(addsuffix $(SPACE)shared32/lib,$(NSS32_NSPR32_SRC_LIBS))

ifdef BUILD_PATCH
# need 32-bit LDAP C SDK libs for SP2
  LDAPSDK32_IMPORT = $(subst $(NS64TAG),,$(LDAP_RELEASE))
  LDAPSDK32_PULLFILES = lib/$(LIB_PREFIX)$(subst $(SPACE),$(COMMA)lib/$(LIB_PREFIX),$(addsuffix .$(DLL_SUFFIX),$(LDAP_SOLIB_NAMES)))
endif # BUILD_PATCH
endif # USE_64

ifdef VSFTPD_HACK
SECURITY_FILES=lib,bin/$(subst $(SPACE),$(COMMA)bin/,$(SECURITY_TOOLS))
else
SECURITY_FILES=lib,include,bin/$(subst $(SPACE),$(COMMA)bin/,$(SECURITY_TOOLS))
endif

ifndef SECURITY_PULL_METHOD
SECURITY_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(SECURITY_DEP): $(NSCP_DISTDIR_FULL_RTL)
ifdef COMPONENT_DEPS
	mkdir -p $(SECURITY_BINPATH)
	$(FTP_PULL) -method $(SECURITY_PULL_METHOD) \
		-objdir $(SECURITY_BUILD_DIR) -componentdir $(SECURITY_IMPORT) \
		-files $(SECURITY_FILES)
ifdef VSFTPD_HACK
# work around vsftpd -L problem
	$(FTP_PULL) -method $(SECURITY_PULL_METHOD) \
		-objdir $(SECURITY_BUILD_DIR) -componentdir $(COMPONENTS_DIR)/nss/$(SECURITY_RELDATE) \
		-files include
endif
# if building 64 bit version, also need the 32 bit version of nssckbi.so
# rename it as nssckbi32.so
# also need the 32 bit modutil, other NSS shared libraries and NSPR shared libraries
ifeq ($(USE_64), 1)
	mkdir -p $(SHARED32_BUILD_DIR)/bin
	mkdir -p $(SHARED32_BUILD_DIR)/lib
	$(FTP_PULL) -method $(SECURITY_PULL_METHOD) \
		-objdir $(SHARED32_BUILD_DIR) -componentdir $(NSPR32_IMPORT) \
		-files $(NSPR32_PULLFILES)
	$(FTP_PULL) -method $(SECURITY_PULL_METHOD) \
		-objdir $(SHARED32_BUILD_DIR) -componentdir $(NSS32_IMPORT) \
		-files $(subst $(SPACE),$(COMMA),$(NSS32_PULLFILES))
ifdef BUILD_PATCH
	$(FTP_PULL) -method $(LDAPSDK_PULL_METHOD) \
		-objdir $(SHARED32_BUILD_DIR) -componentdir $(LDAPSDK32_IMPORT) \
		-files $(subst $(SPACE),$(COMMA),$(LDAPSDK32_PULLFILES))
endif
	mv -f $(SHARED32_BUILD_DIR)/lib/$(NSSCKBI_FILE) $(SHARED32_BUILD_DIR)/lib/$(NSSCKBI32_FILE)
endif # USE_64
endif # COMPONENT_DEPS
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component NSS file $@" ; \
	fi
endif # SECURITY_SOURCE_ROOT

ifndef SVRCORE_SOURCE_ROOT
SVRCORE_IMPORT = $(COMPONENTS_DIR)/svrcore/$(SVRCORE_RELDATE)/$(NSOBJDIR_NAME)
#SVRCORE_IMPORT = $(COMPONENTS_DIR_DEV)/svrcore/$(SVRCORE_RELDATE)/$(NSOBJDIR_NAME)
ifeq ($(ARCH), WINNT)
  SVRCORE_DEP = $(SVRCORE_LIBPATH)/svrcore.$(LIB_SUFFIX)
else
  SVRCORE_DEP = $(SVRCORE_LIBPATH)/libsvrcore.$(LIB_SUFFIX)
endif

ifndef SVRCORE_PULL_METHOD
SVRCORE_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(SVRCORE_DEP): $(NSCP_DISTDIR)
ifdef COMPONENT_DEPS
	$(FTP_PULL) -method $(SVRCORE_PULL_METHOD) \
		-objdir $(SVRCORE_BUILD_DIR) -componentdir $(SVRCORE_IMPORT)/.. \
		-files xpheader.jar -unzip $(SVRCORE_INCDIR)
	$(FTP_PULL) -method $(SVRCORE_PULL_METHOD) \
		-objdir $(SVRCORE_BUILD_DIR) -componentdir $(SVRCORE_IMPORT) \
		-files mdbinary.jar -unzip $(SVRCORE_BUILD_DIR)
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component SVRCORE file $@" ; \
	fi
endif # SVRCORE_SOURCE_ROOT

ifndef LDAPSDK_SOURCE_ROOT
ifndef LDAP_VERSION
  LDAP_VERSION = $(LDAP_RELDATE)
endif
ifndef LDAP_SBC
#LDAP_SBC = $(COMPONENTS_DIR_DEV)
LDAP_SBC = $(COMPONENTS_DIR)
endif
LDAPOBJDIR = $(FULL_RTL_OBJDIR)
# LDAP does not have PTH version, so here is the hack which treat non PTH
# version as PTH version
ifeq ($(USE_PTHREADS), 1)
  LDAP_RELEASE = $(LDAP_SBC)/$(LDAPCOMP_DIR)/$(LDAP_VERSION)/$(NSOBJDIR_NAME1)
else
  LDAP_RELEASE = $(LDAP_SBC)/$(LDAPCOMP_DIR)/$(LDAP_VERSION)/$(LDAPOBJDIR)
endif
ifeq ($(ARCH), WINNT)
  LDAPSDK_DEP = $(LDAPSDK_LIBPATH)/nsldap32v$(LDAP_SUF).$(DLL_SUFFIX)
  LDAPSDK_PULL_LIBS = lib/nsldapssl32v$(LDAP_SUF).$(LIB_SUFFIX),lib/nsldapssl32v$(LDAP_SUF).$(LDAP_DLL_SUFFIX),lib/nsldap32v$(LDAP_SUF).$(LIB_SUFFIX),lib/nsldap32v$(LDAP_SUF).$(LDAP_DLL_SUFFIX),lib/nsldappr32v$(LDAP_SUF).$(LIB_SUFFIX),lib/nsldappr32v$(LDAP_SUF).$(LDAP_DLL_SUFFIX)
else
  LDAPSDK_DEP = $(LDAPSDK_LIBPATH)/libldap$(LDAP_SUF).$(DLL_SUFFIX)
  LDAPSDK_PULL_LIBS = lib/libssldap$(LDAP_SUF)$(LDAP_DLL_PRESUF).$(LDAP_DLL_SUFFIX),lib/libldap$(LDAP_SUF)$(LDAP_DLL_PRESUF).$(LDAP_DLL_SUFFIX),lib/libprldap$(LDAP_SUF)$(LDAP_DLL_PRESUF).$(LDAP_DLL_SUFFIX)
endif

ifndef LDAPSDK_PULL_METHOD
LDAPSDK_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(LDAPSDK_DEP): $(NSCP_DISTDIR_FULL_RTL)
ifdef COMPONENT_DEPS
	mkdir -p $(LDAP_LIBPATH)
	$(FTP_PULL) -method $(LDAPSDK_PULL_METHOD) \
		-objdir $(LDAP_ROOT) -componentdir $(LDAP_RELEASE) \
		-files include,$(LDAPSDK_PULL_LIBS),bin
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component LDAPSDK file $@" ; \
	fi
endif # LDAPSDK_SOURCE_ROOT

ifndef SASL_SOURCE_ROOT
#SASL_RELEASE = $(COMPONENTS_DIR_DEV)/sasl/$(SASL_VERSDIR)/$(SASL_RELDATE)/$(NSOBJDIR_NAME)
SASL_RELEASE = $(COMPONENTS_DIR)/sasl/$(SASL_VERSDIR)/$(SASL_RELDATE)/$(NSOBJDIR_NAME)
SASL_DEP = $(SASL_INCLUDE)/sasl.h
ifndef SASL_PULL_METHOD
SASL_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(SASL_DEP): $(NSCP_DISTDIR_FULL_RTL)
ifdef COMPONENT_DEPS
	$(FTP_PULL) -method $(SASL_PULL_METHOD) \
		-objdir $(SASL_BUILD_DIR) -componentdir $(SASL_RELEASE) \
		-files include
	$(FTP_PULL) -method $(SASL_PULL_METHOD) \
		-objdir $(SASL_BUILD_DIR)/lib -componentdir $(SASL_RELEASE)/lib \
		-files $(SASL_LIBS)
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component SASL file $@" ; \
	fi
endif # SASL_SOURCE_ROOT

ifndef ICU_SOURCE_ROOT
ICU_RELEASE = $(COMPONENTS_DIR)/libicu/$(ICU_VERSDIR)/$(ICU_RELDATE)/$(NSOBJDIR_NAME)
ICU_DEP = $(ICU_INCPATH)/unicode/ucol.h
ifndef ICU_PULL_METHOD
ICU_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(ICU_DEP): $(NSCP_DISTDIR_FULL_RTL)
ifdef COMPONENT_DEPS
	$(FTP_PULL) -method $(ICU_PULL_METHOD) \
		-objdir $(ICU_BUILD_DIR) -componentdir $(ICU_RELEASE) \
		-files lib,include,bin
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component ICU file $@" ; \
	fi
endif # ICU_SOURCE_ROOT

ifndef DB_SOURCE_ROOT
#if no version specified, we'll use the latest one
ifndef DB_VERSION
  DB_VERSION=20040130
endif
# define the paths to the component parts
db_components_share=$(COMPONENTS_DIR)/$(db_component_name)
MY_NSOBJDIR_TAG=$(NSOBJDIR_TAG).OBJ
db_release_config =$(db_components_share)/$(DB_VERSION)/$(NSCONFIG_NOTAG)$(NS64TAG)$(MY_NSOBJDIR_TAG)
# add ",bin" to DB_FILES if you want the programs like db_verify, db_recover, etc.
DB_FILES=include,lib,bin

ifeq ($(ARCH), WINNT)
  DB_LIB_DEP =$(DB_STATIC_LIB)
else	# not WINNT
  DB_LIB_DEP =$(DB_LIBPATH)/$(DB_LIBNAME).$(DLL_SUFFIX)
endif	# not WINNT

ifndef DB_PULL_METHOD
DB_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(DB_LIB_DEP): $(NSCP_DISTDIR)
ifdef COMPONENT_DEPS
	$(FTP_PULL) -method $(DB_PULL_METHOD) \
		-objdir $(db_path_config) -componentdir $(db_release_config) \
		-files $(DB_FILES)
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component $(db_component_name) file $@" ; \
	fi
endif # DB_SOURCE_ROOT

######## END OF OPEN SOURCE COMPONENTS ######################

######## The rest of these components are internal only (for now)

# ADMINUTIL library #######################################
ADMINUTIL_VERSION=$(ADMINUTIL_RELDATE)
ADMINUTIL_BASE=adminsdk/$(ADMINUTIL_VERSDIR)/${ADMINUTIL_VERSION}
ADMSDKOBJDIR = $(FULL_RTL_OBJDIR)
ADMINUTIL_IMPORT=$(COMPONENTS_DIR)/${ADMINUTIL_BASE}/$(NSOBJDIR_NAME)
#ADMINUTIL_IMPORT=$(COMPONENTS_DIR_DEV)/${ADMINUTIL_BASE}/$(NSOBJDIR_NAME)
# this is the base directory under which the component's files will be found
# during the build process
ADMINUTIL_BUILD_DIR=$(NSCP_DISTDIR_FULL_RTL)/adminutil
ADMINUTIL_LIBPATH=$(ADMINUTIL_BUILD_DIR)/lib
ADMINUTIL_INCPATH=$(ADMINUTIL_BUILD_DIR)/include

PACKAGE_SRC_DEST += $(ADMINUTIL_LIBPATH)/property bin/slapd/lib
LIBS_TO_PKG += $(wildcard $(ADMINUTIL_LIBPATH)/*.$(DLL_SUFFIX))
LIBS_TO_PKG_CLIENTS += $(wildcard $(ADMINUTIL_LIBPATH)/*.$(DLL_SUFFIX))

#
# Libadminutil
#
ADMINUTIL_DEP = $(ADMINUTIL_LIBPATH)/libadminutil$(ADMINUTIL_VER).$(LIB_SUFFIX)
ifeq ($(ARCH), WINNT)
ADMINUTIL_LINK = /LIBPATH:$(ADMINUTIL_LIBPATH) libadminutil$(ADMINUTIL_VER).$(LIB_SUFFIX)
ADMINUTIL_S_LINK = /LIBPATH:$(ADMINUTIL_LIBPATH) libadminutil_s$(ADMINUTIL_VER).$(LIB_SUFFIX)
LIBADMINUTILDLL_NAMES = $(ADMINUTIL_LIBPATH)/libadminutil$(ADMINUTIL_VER).$(DLL_SUFFIX)
else
ADMINUTIL_LINK=-L$(ADMINUTIL_LIBPATH) -ladminutil$(ADMINUTIL_VER)
endif
ADMINUTIL_INCLUDE=-I$(ADMINUTIL_INCPATH) \
	-I$(ADMINUTIL_INCPATH)/libadminutil \
	-I$(ADMINUTIL_INCPATH)/libadmsslutil

ifndef ADMINUTIL_PULL_METHOD
ADMINUTIL_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(ADMINUTIL_DEP): ${NSCP_DISTDIR_FULL_RTL}
ifdef COMPONENT_DEPS
	$(FTP_PULL) -method $(ADMINUTIL_PULL_METHOD) \
		-objdir $(ADMINUTIL_BUILD_DIR) \
		-componentdir $(ADMINUTIL_IMPORT) \
		-files include,lib
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component adminutil file $@" ; \
	fi

###########################################################
# Net-SNMP

ifndef NETSNMP_SOURCE_ROOT
#NETSNMP_RELEASE = $(COMPONENTS_DIR_DEV)/net-snmp/$(NETSNMP_VER)/$(NSOBJDIR_NAME)
NETSNMP_RELEASE = $(COMPONENTS_DIR)/net-snmp/$(NETSNMP_VER)/$(NSOBJDIR_NAME)
NETSNMP_DEP = $(NETSNMP_INCDIR)/net-snmp/net-snmp-includes.h
ifndef NETSNMP_PULL_METHOD
NETSNMP_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif
                                                                                                                          
$(NETSNMP_DEP): $(NSCP_DISTDIR_FULL_RTL)
ifneq ($(ARCH), WINNT)
ifdef COMPONENT_DEPS
	$(FTP_PULL) -method $(NETSNMP_PULL_METHOD) \
		-objdir $(NETSNMP_BUILD_DIR) -componentdir $(NETSNMP_RELEASE) \
		-files lib,include,bin
endif
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component NETSNMP file $@" ; \
	fi
endif # NETSNMP_SOURCE_ROOT

###########################################################

### SETUPSDK #############################
# this is where the build looks for setupsdk components
SETUP_SDK_BUILD_DIR = $(NSCP_DISTDIR)/setupsdk
SETUPSDK_VERSION = $(SETUP_SDK_RELDATE)
SETUPSDK_RELEASE = $(COMPONENTS_DIR)/setupsdk/$(SETUPSDK_VERSDIR)/$(SETUPSDK_VERSION)/$(NSOBJDIR_NAME)
#SETUPSDK_RELEASE = $(COMPONENTS_DIR_DEV)/setupsdk/$(SETUPSDK_VERSDIR)/$(SETUPSDK_VERSION)/$(NSOBJDIR_NAME)
SETUPSDK_LIBPATH = $(SETUP_SDK_BUILD_DIR)/lib
SETUPSDK_INCDIR = $(SETUP_SDK_BUILD_DIR)/include
SETUPSDK_BINPATH = $(SETUP_SDK_BUILD_DIR)/bin
SETUPSDK_INCLUDE = -I$(SETUPSDK_INCDIR)

ifeq ($(ARCH), WINNT)
SETUP_SDK_FILES = setupsdk.tar.gz -unzip $(NSCP_DISTDIR)/setupsdk
SETUPSDK_DEP = $(SETUPSDK_LIBPATH)/nssetup32.$(LIB_SUFFIX)
SETUPSDKLINK = /LIBPATH:$(SETUPSDK_LIBPATH) nssetup32.$(LIB_SUFFIX)
SETUPSDK_S_LINK = /LIBPATH:$(SETUPSDK_LIBPATH) nssetup32_s.$(LIB_SUFFIX)
else
SETUP_SDK_FILES = bin,lib,include
SETUPSDK_DEP = $(SETUPSDK_LIBPATH)/libinstall.$(LIB_SUFFIX)
SETUPSDKLINK = -L$(SETUPSDK_LIBPATH) -linstall
SETUPSDK_S_LINK = $(SETUPSDKLINK)
endif

ifndef SETUPSDK_PULL_METHOD
SETUPSDK_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(SETUPSDK_DEP): $(NSCP_DISTDIR)
ifdef COMPONENT_DEPS
	$(FTP_PULL) -method $(SETUPSDK_PULL_METHOD) \
		-objdir $(SETUP_SDK_BUILD_DIR) -componentdir $(SETUPSDK_RELEASE) \
		-files $(SETUP_SDK_FILES)
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component SETUPSDK file $@" ; \
	fi
# apache-axis java classes #######################################
AXIS = axis-$(AXIS_VERSION).zip
AXIS_FILES = $(AXIS)
AXIS_RELEASE = $(COMPONENTS_DIR)/axis
#AXISJAR_DIR = $(AXISJAR_RELEASE)/$(AXISJAR_COMP)/$(AXISJAR_VERSION)
AXIS_DIR = $(AXIS_RELEASE)/$(AXIS_VERSION)
AXIS_FILE = $(CLASS_DEST)/$(AXIS)
AXIS_DEP = $(AXIS_FILE) 
AXIS_REL_DIR=$(subst -bin,,$(subst .zip,,$(AXIS)))


# This is java, so there is only one real platform subdirectory

#PACKAGE_UNDER_JAVA += $(AXIS_FILE)

ifndef AXIS_PULL_METHOD
AXIS_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(AXIS_DEP): $(CLASS_DEST) 
ifdef COMPONENT_DEPS
	echo "Inside ftppull"
	$(FTP_PULL) -method $(COMPONENT_PULL_METHOD) \
		-objdir $(CLASS_DEST) -componentdir $(AXIS_DIR) \
		-files $(AXIS_FILES) -unzip $(CLASS_DEST)
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component AXIS files $@" ; \
	fi

###########################################################


# other dsml java classes #######################################
DSMLJAR = activation.jar,jaxrpc-api.jar,jaxrpc.jar,saaj.jar,xercesImpl.jar,xml-apis.jar
DSMLJAR_FILES = $(DSMLJAR)
DSMLJAR_RELEASE = $(COMPONENTS_DIR)
#DSMLJARJAR_DIR = $(DSMLJARJAR_RELEASE)/$(DSMLJARJAR_COMP)/$(DSMLJARJAR_VERSION)
DSMLJAR_DIR = $(DSMLJAR_RELEASE)/dsmljars
DSMLJAR_FILE = $(CLASS_DEST)
DSMLJAR_DEP = $(CLASS_DEST)/activation.jar $(CLASS_DEST)/jaxrpc-api.jar $(CLASS_DEST)/jaxrpc.jar $(CLASS_DEST)/saaj.jar $(CLASS_DEST)/xercesImpl.jar $(CLASS_DEST)/xml-apis.jar

ifndef DSMLJAR_PULL_METHOD
DSMLJAR_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(DSMLJAR_DEP): $(CLASS_DEST) 
ifdef COMPONENT_DEPS
	echo "Inside ftppull"
	$(FTP_PULL) -method $(COMPONENT_PULL_METHOD) \
		-objdir $(CLASS_DEST) -componentdir $(DSMLJAR_DIR) \
		-files $(DSMLJAR_FILES)

endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component DSMLJAR files $@" ; \
	fi

###########################################################

# XMLTOOLS java classes #######################################
CRIMSONJAR = crimson.jar
CRIMSON_LICENSE = LICENSE.crimson
CRIMSONJAR_FILES = $(CRIMSONJAR),$(CRIMSON_LICENSE)
CRIMSONJAR_RELEASE = $(COMPONENTS_DIR)
CRIMSONJAR_DIR = $(CRIMSONJAR_RELEASE)/$(CRIMSONJAR_COMP)/$(CRIMSONJAR_VERSION)
CRIMSONJAR_FILE = $(CLASS_DEST)/$(CRIMSONJAR)
CRIMSONJAR_DEP = $(CRIMSONJAR_FILE) $(CLASS_DEST)/$(CRIMSON_LICENSE)


# This is java, so there is only one real platform subdirectory

PACKAGE_UNDER_JAVA += $(CRIMSONJAR_FILE)

ifndef CRIMSONJAR_PULL_METHOD
CRIMSONJAR_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(CRIMSONJAR_DEP): $(CLASS_DEST)
ifdef COMPONENT_DEPS
	echo "Inside ftppull"
	$(FTP_PULL) -method $(COMPONENT_PULL_METHOD) \
		-objdir $(CLASS_DEST) -componentdir $(CRIMSONJAR_DIR) \
		-files $(CRIMSONJAR_FILES)
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component CRIMSONJAR files $@" ; \
	fi

###########################################################

# ANT java classes #######################################
ifeq ($(BUILD_JAVA_CODE),1)
#  (we use ant for building some Java code)
ANTJAR = ant.jar
JAXPJAR = jaxp.jar
ANT_FILES = $(ANTJAR) $(JAXPJAR)
ANT_RELEASE = $(COMPONENTS_DIR)
ANT_HOME = $(ANT_RELEASE)/$(ANT_COMP)/$(ANT_VERSION)
ANT_DIR = $(ANT_HOME)/lib
ANT_DEP = $(addprefix $(CLASS_DEST)/, $(ANT_FILES))
ANT_CP = $(subst $(SPACE),$(PATH_SEP),$(ANT_DEP))
ANT_PULL = $(subst $(SPACE),$(COMMA),$(ANT_FILES))

ifndef ANT_PULL_METHOD
ANT_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(ANT_DEP): $(CLASS_DEST) $(CRIMSONJAR_DEP)
ifdef COMPONENT_DEPS
	echo "Inside ftppull"
	$(FTP_PULL) -method $(COMPONENT_PULL_METHOD) \
		-objdir $(CLASS_DEST) -componentdir $(ANT_DIR) \
		-files $(ANT_PULL)
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component ant files $@" ; \
	fi
endif
###########################################################

# Servlet SDK classes #######################################
SERVLETJAR = servlet.jar
SERVLET_FILES = $(SERVLETJAR)
SERVLET_RELEASE = $(COMPONENTS_DIR)
SERVLET_DIR = $(SERVLET_RELEASE)/$(SERVLET_COMP)/$(SERVLET_VERSION)
SERVLET_DEP = $(addprefix $(CLASS_DEST)/, $(SERVLET_FILES))
SERVLET_CP = $(subst $(SPACE),$(PATH_SEP),$(SERVLET_DEP))
SERVLET_PULL = $(subst $(SPACE),$(COMMA),$(SERVLET_FILES))

ifndef SERVLET_PULL_METHOD
SERVLET_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(SERVLET_DEP): $(CLASS_DEST)
ifdef COMPONENT_DEPS
	echo "Inside ftppull"
	$(FTP_PULL) -method $(COMPONENT_PULL_METHOD) \
		-objdir $(CLASS_DEST) -componentdir $(SERVLET_DIR) \
		-files $(SERVLET_PULL)
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component servlet SDK files $@" ; \
	fi

###########################################################

# LDAP java classes #######################################
LDAPJDK = ldapjdk.jar
LDAPJDK_VERSION = $(LDAPJDK_RELDATE)
LDAPJDK_RELEASE = $(COMPONENTS_DIR)
LDAPJDK_DIR = $(LDAPJDK_RELEASE)
LDAPJDK_IMPORT = $(LDAPJDK_RELEASE)/$(LDAPJDK_COMP)/$(LDAPJDK_VERSION)/$(NSOBJDIR_NAME)
# This is java, so there is only one real platform subdirectory
LDAPJARFILE=$(CLASS_DEST)/ldapjdk.jar
LDAPJDK_DEP=$(LDAPJARFILE)

#PACKAGE_UNDER_JAVA += $(LDAPJARFILE)

ifndef LDAPJDK_PULL_METHOD
LDAPJDK_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(LDAPJDK_DEP): $(CLASS_DEST)
ifdef COMPONENT_DEPS
	$(FTP_PULL) -method $(LDAPJDK_PULL_METHOD) \
		-objdir $(CLASS_DEST) -componentdir $(LDAPJDK_IMPORT) \
		-files $(LDAPJDK)
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component LDAPJDK file $@" ; \
	fi

###########################################################
# LDAP Console java classes
###########################################################
LDAPCONSOLEJAR = ds$(LDAPCONSOLE_REL).jar
LDAPCONSOLEJAR_EN = ds$(LDAPCONSOLE_REL)_en.jar

#LDAPCONSOLE_RELEASE=$(COMPONENTS_DIR_DEV)
LDAPCONSOLE_RELEASE=$(COMPONENTS_DIR)
LDAPCONSOLE_JARDIR = $(LDAPCONSOLE_RELEASE)/ldapconsole/$(LDAPCONSOLE_COMP)$(BUILD_MODE)/$(LDAPCONSOLE_RELDATE)/jars
LDAPCONSOLE_DEP = $(CLASS_DEST)/$(LDAPCONSOLEJAR)
LDAPCONSOLE_FILES=$(LDAPCONSOLEJAR),$(LDAPCONSOLEJAR_EN)

ifndef LDAPCONSOLE_PULL_METHOD
LDAPCONSOLE_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(LDAPCONSOLE_DEP): $(CLASS_DEST)
ifdef COMPONENT_DEPS
	$(FTP_PULL) -method $(LDAPCONSOLE_PULL_METHOD) \
		-objdir $(CLASS_DEST) -componentdir $(LDAPCONSOLE_JARDIR) \
		-files $(LDAPCONSOLE_FILES)
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component LDAPCONSOLE file $@" ; \
	fi

###########################################################
### Perldap package #######################################

#PERLDAP_COMPONENT_DIR = $(COMPONENTS_DIR_DEV)/perldap/$(PERLDAP_VERSION)/$(NSOBJDIR_NAME_32)
PERLDAP_COMPONENT_DIR = $(COMPONENTS_DIR)/perldap/$(PERLDAP_VERSION)/$(NSOBJDIR_NAME_32)
PERLDAP_ZIP_FILE = perldap14.zip

###########################################################

# JSS classes - for the Mission Control Console ######
JSSJAR = jss$(JSS_JAR_VERSION).jar
JSSJARFILE = $(CLASS_DEST)/$(JSSJAR)
JSS_RELEASE = $(COMPONENTS_DIR)/$(JSS_COMP)/$(JSS_VERSION)
JSS_DEP = $(JSSJARFILE)

#PACKAGE_UNDER_JAVA += $(JSSJARFILE)

ifndef JSS_PULL_METHOD
JSS_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(JSS_DEP): $(CLASS_DEST)
ifdef COMPONENT_DEPS
ifdef VSFTPD_HACK
# work around vsftpd -L problem
	$(FTP_PULL) -method $(JSS_PULL_METHOD) \
		-objdir $(CLASS_DEST)/jss -componentdir $(JSS_RELEASE) \
        -files xpclass.jar
	mv $(CLASS_DEST)/jss/xpclass.jar $(CLASS_DEST)/$(JSSJAR)
	rm -rf $(CLASS_DEST)/jss
else
	$(FTP_PULL) -method $(JSS_PULL_METHOD) \
		-objdir $(CLASS_DEST) -componentdir $(JSS_RELEASE) \
		-files $(JSSJAR)
endif
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component JSS file $@" ; \
	fi

###########################################################

### JSP compiler package ##################################

JSPC_REL = $(JSPC_VERSDIR)
JSPC_REL_DATE = $(JSPC_VERSION)
JSPC_FILES = jasper-compiler.jar jasper-runtime.jar
JSPC_RELEASE = $(COMPONENTS_DIR)
JSPC_DIR = $(JSPC_RELEASE)/$(JSPC_COMP)/$(JSPC_VERSION)
JSPC_DEP = $(addprefix $(CLASS_DEST)/, $(JSPC_FILES))
JSPC_CP = $(subst $(SPACE),$(PATH_SEP),$(JSPC_DEP))
JSPC_PULL = $(subst $(SPACE),$(COMMA),$(JSPC_FILES))

ifndef JSPC_PULL_METHOD
JSPC_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(JSPC_DEP): $(CLASS_DEST)
ifdef COMPONENT_DEPS
	echo "Inside ftppull"
	$(FTP_PULL) -method $(COMPONENT_PULL_METHOD) \
		-objdir $(CLASS_DEST) -componentdir $(JSPC_DIR) \
		-files $(JSPC_PULL)
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component jspc files $@" ; \
	fi

###########################################################

###########################################################
### Admin Server package ##################################

ADMIN_REL = $(ADM_VERSDIR)
ADMIN_REL_DATE = $(ADM_VERSION)
ADMIN_FILE = admserv.tar.gz
ADMIN_FILE_TAR = admserv.tar
ADMSDKOBJDIR = $(NSCONFIG)$(NSOBJDIR_TAG).OBJ
IMPORTADMINSRV_BASE=$(COMPONENTS_DIR)/$(ADMIN_REL)/$(ADMIN_REL_DATE)
#IMPORTADMINSRV_BASE=$(COMPONENTS_DIR_DEV)/$(ADMIN_REL)/$(ADMIN_REL_DATE)
IMPORTADMINSRV = $(IMPORTADMINSRV_BASE)/$(NSOBJDIR_NAME_32)
ADMSERV_DIR=$(ABS_ROOT_PARENT)/dist/$(NSOBJDIR_NAME)/admserv
ADMSERV_DEP = $(ADMSERV_DIR)/setup$(EXE_SUFFIX)

ifdef FORTEZZA
  ADM_VERSION = $(ADM_RELDATE)F
else
  ifeq ($(SECURITY), domestic)
    ADM_VERSION = $(ADM_RELDATE)D
  else
    ifneq ($(ARCH), IRIX)
        ADM_VERSION = $(ADM_RELDATE)E
    else
        ADM_VERSION = $(ADM_RELDATE)D
    endif
  endif
endif

ADM_VERSION = $(ADM_RELDATE)
ADM_RELEASE = $(COMPONENTS_DIR)/$(ADM_VERSDIR)/$(ADM_VERSION)/$(NSOBJDIR_NAME)

ifndef ADMSERV_PULL_METHOD
ADMSERV_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

ifndef ADMSERV_DEPS
ADMSERV_DEPS = $(COMPONENT_DEPS)
endif
#IMPORTADMINSRV = /share/builds/sbsrel1/admsvr/admsvr62/ships/20030702.2/spd04_Solaris8/SunOS5.8-domestic-optimize-normal
#ADM_RELEASE = /share/builds/sbsrel1/admsvr/admsvr62/ships/20030702.2/spd04_Solaris8/SunOS5.8-domestic-optimize-normal
$(ADMSERV_DEP): $(ABS_ROOT_PARENT)/dist/$(NSOBJDIR_NAME)
ifdef ADMSERV_DEPS
	$(FTP_PULL) -method $(ADMSERV_PULL_METHOD) \
		-objdir $(ADMSERV_DIR) -componentdir $(IMPORTADMINSRV) \
		-files $(ADMIN_FILE) -unzip $(ADMSERV_DIR)
endif
	@if [ ! -f $@ ] ; \
	then echo "Error: could not get component ADMINSERV file $@" ; \
	exit 1 ; \
	fi
### Admin Server END ######################################

### DOCS #################################
# this is where the build looks for slapd docs
DSDOC_DIR = $(ABS_ROOT)/../dist/dsdoc
DSDOC_VERSDIR = $(DIR_NORM_VERSION)$(BUILD_MODE)
#DSDOC_RELEASE = $(COMPONENTS_DIR_DEV)/ldapserverdoc/$(DSDOC_VERSDIR)/$(DSDOC_RELDATE)
DSDOC_RELEASE = $(COMPONENTS_DIR)/ldapserverdoc/$(DSDOC_VERSDIR)/$(DSDOC_RELDATE)
                                                                                                                          
DSDOC_CLIENTS = slapd_clients.zip
DSDOC_COPYRIGHT = slapd_copyright.zip
DSDOC_FILES = $(DSDOC_COPYRIGHT),$(DSDOC_CLIENTS)
DSDOC_DEP := $(DSDOC_DIR)/$(DSDOC_COPYRIGHT)

ifndef DSDOC_PULL_METHOD
DSDOC_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(DSDOC_DEP): $(NSCP_DISTDIR)
	$(FTP_PULL) -method $(DSDOC_PULL_METHOD) \
		-objdir $(DSDOC_DIR) -componentdir $(DSDOC_RELEASE) \
		-files $(DSDOC_FILES)
	@if [ ! -f $@ ] ; \
	then echo "Error: could not get component DSDOC file $@" ; \
	exit 1 ; \
	fi
### DOCS END #############################


# Windows sync component for Active Directory
ADSYNC = PassSync.msi
ADSYNC_DEST = $(NSCP_DISTDIR_FULL_RTL)/winsync
ADSYNC_FILE = $(ADSYNC_DEST)/$(ADSYNC)
ADSYNC_FILES = $(ADSYNC)
ADSYNC_RELEASE = $(COMPONENTS_DIR)/winsync/passsync
# windows make naming convention - release = optimize, debug = full
ifeq ($(BUILD_DEBUG), optimize)
	ADSYNC_DIR_SUFFIX=release
else
	ADSYNC_DIR_SUFFIX=debug
endif
ADSYNC_DIR = $(ADSYNC_RELEASE)/$(ADSYNC_VERSION)/$(ADSYNC_DIR_SUFFIX)

ADSYNC_DEP = $(ADSYNC_FILE)
PACKAGE_SRC_DEST += $(ADSYNC_FILE) winsync

ifndef ADSYNC_PULL_METHOD
ADSYNC_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(ADSYNC_DEP): $(NSCP_DISTDIR_FULL_RTL) 
ifdef COMPONENT_DEPS
	echo "Inside ftppull"
	$(FTP_PULL) -method $(COMPONENT_PULL_METHOD) \
		-objdir $(ADSYNC_DEST) -componentdir $(ADSYNC_DIR) \
		-files $(ADSYNC_FILES)
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component ADSYNC files $@" ; \
	fi
# Windows sync component for Active Directory

# Windows sync component for NT4
NT4SYNC = ntds.msi
NT4SYNC_DEST = $(NSCP_DISTDIR_FULL_RTL)/winsync
NT4SYNC_FILE = $(NT4SYNC_DEST)/$(NT4SYNC)
NT4SYNC_FILES = $(NT4SYNC)
NT4SYNC_RELEASE = $(COMPONENTS_DIR)/winsync/ntds
# windows make naming convention - release = optimize, debug = full
ifeq ($(BUILD_DEBUG), optimize)
	NT4SYNC_DIR_SUFFIX=release
else
	NT4SYNC_DIR_SUFFIX=debug
endif
NT4SYNC_DIR = $(NT4SYNC_RELEASE)/$(NT4SYNC_VERSION)/$(NT4SYNC_DIR_SUFFIX)

NT4SYNC_DEP = $(NT4SYNC_FILE)
PACKAGE_SRC_DEST += $(NT4SYNC_FILE) winsync

ifndef NT4SYNC_PULL_METHOD
NT4SYNC_PULL_METHOD = $(COMPONENT_PULL_METHOD)
endif

$(NT4SYNC_DEP): $(NSCP_DISTDIR_FULL_RTL) 
ifdef COMPONENT_DEPS
	echo "Inside ftppull"
	$(FTP_PULL) -method $(COMPONENT_PULL_METHOD) \
		-objdir $(NT4SYNC_DEST) -componentdir $(NT4SYNC_DIR) \
		-files $(NT4SYNC_FILES)
endif
	-@if [ ! -f $@ ] ; \
	then echo "Error: could not get component NT4SYNC files $@" ; \
	fi
# Windows sync component for NT4
