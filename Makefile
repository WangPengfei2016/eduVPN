#
#   eduVPN - End-user friendly VPN
#
#   Copyright: 2017, The Commons Conservancy eduVPN Programme
#   SPDX-License-Identifier: GPL-3.0+
#

PRODUCT_NAME=eduVPN Client
PRODUCT_VERSION_MAJ=1
PRODUCT_VERSION_MIN=0
PRODUCT_VERSION_REV=8
PRODUCT_VERSION=$(PRODUCT_VERSION_MAJ).$(PRODUCT_VERSION_MIN).$(PRODUCT_VERSION_REV)
PRODUCT_VERSION_STR=$(PRODUCT_VERSION_MAJ).$(PRODUCT_VERSION_MIN)-alpha6

OUTPUT_DIR=bin
SETUP_DIR=$(OUTPUT_DIR)\Setup
SETUP_NAME=eduVPN-Client-Win

# Default testing configuration and platform
CFG=Debug
!IF "$(PROCESSOR_ARCHITECTURE)" == "AMD64"
PLAT=x64
!ELSE
PLAT=x86
!ENDIF

# Utility default flags
!IF "$(PROCESSOR_ARCHITECTURE)" == "AMD64"
REG_FLAGS=/f /reg:64
REG_FLAGS32=/f /reg:32
!ELSE
REG_FLAGS=/f
!ENDIF
DEVENV_FLAGS=/NoLogo
CSCRIPT_FLAGS=//Nologo
WIX_WIXCOP_FLAGS=-nologo "-set1$(MAKEDIR)\wixcop.xml"
WIX_CANDLE_FLAGS=-nologo -deduVPN.Version="$(PRODUCT_VERSION)" -ext WixNetFxExtension -ext WixUtilExtension -ext WixBalExtension
WIX_LIGHT_FLAGS=-nologo -dcl:high -spdb -sice:ICE03 -sice:ICE60 -sice:ICE61 -sice:ICE69 -sice:ICE82 -ext WixNetFxExtension -ext WixUtilExtension -ext WixBalExtension
WIX_INSIGNIA_FLAGS=-nologo


######################################################################
# Default target
######################################################################

All :: \
	Setup


######################################################################
# Registration
######################################################################

Register :: \
	RegisterOpenVPNInteractiveService \
	RegisterSettings \
	RegisterShortcuts

Unregister :: \
	UnregisterShortcuts \
	UnregisterSettings \
	UnregisterOpenVPNInteractiveService

RegisterSettings :: \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Client.exe"
	reg.exe add "HKCR\org.eduvpn.app"                    /v "URL Protocol" /t REG_SZ /d ""                                                                     $(REG_FLAGS) > NUL
	reg.exe add "HKCR\org.eduvpn.app\DefaultIcon"        /ve               /t REG_SZ /d "$(MAKEDIR)\$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Client.exe,1"          $(REG_FLAGS) > NUL
	reg.exe add "HKCR\org.eduvpn.app\shell\open\command" /ve               /t REG_SZ /d "\"$(MAKEDIR)\$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Client.exe\" \"%1\"" $(REG_FLAGS) > NUL

UnregisterSettings ::
	-reg.exe delete "HKCR\org.eduvpn.app" $(REG_FLAGS) > NUL

RegisterShortcuts :: \
	"$(PROGRAMDATA)\Microsoft\Windows\Start Menu\Programs\$(PRODUCT_NAME).lnk"

UnregisterShortcuts ::
	-if exist "$(PROGRAMDATA)\Microsoft\Windows\Start Menu\Programs\$(PRODUCT_NAME).lnk" rd /s /q "$(PROGRAMDATA)\Microsoft\Windows\Start Menu\Programs\$(PRODUCT_NAME).lnk"

RegisterOpenVPNInteractiveService :: \
	UnregisterOpenVPNInteractiveServiceSCM \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)" \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\libeay32.dll" \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\liblzo2-2.dll" \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\libpkcs11-helper-1.dll" \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\openvpn.exe" \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\ssleay32.dll" \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\openvpnserv.exe" \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Resources.dll"
	reg.exe add "HKLM\Software\eduVPN" /v "exe_path"         /t REG_SZ /d "$(MAKEDIR)\$(OUTPUT_DIR)\$(CFG)\$(PLAT)\openvpn.exe" $(REG_FLAGS) > NUL
	reg.exe add "HKLM\Software\eduVPN" /v "config_dir"       /t REG_SZ /d "$(MAKEDIR)\$(OUTPUT_DIR)\$(CFG)\$(PLAT)"             $(REG_FLAGS) > NUL
	reg.exe add "HKLM\Software\eduVPN" /v "config_ext"       /t REG_SZ /d "conf"                                                $(REG_FLAGS) > NUL
	reg.exe add "HKLM\Software\eduVPN" /v "log_dir"          /t REG_SZ /d "$(MAKEDIR)\$(OUTPUT_DIR)\$(CFG)\$(PLAT)"             $(REG_FLAGS) > NUL
	reg.exe add "HKLM\Software\eduVPN" /v "log_append"       /t REG_SZ /d "0"                                                   $(REG_FLAGS) > NUL
	reg.exe add "HKLM\Software\eduVPN" /v "priority"         /t REG_SZ /d "NORMAL_PRIORITY_CLASS"                               $(REG_FLAGS) > NUL
	reg.exe add "HKLM\Software\eduVPN" /v "ovpn_admin_group" /t REG_SZ /d "Users"                                               $(REG_FLAGS) > NUL
	sc.exe create eduVPNServiceInteractive \
		binpath= "$(MAKEDIR)\$(OUTPUT_DIR)\$(CFG)\$(PLAT)\openvpnserv.exe" \
		DisplayName= "@$(MAKEDIR)\$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Resources.dll,-4" \
		type= share \
		start= auto \
		depend= "tap0901/Dhcp"
	sc.exe description eduVPNServiceInteractive "@$(MAKEDIR)\$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Resources.dll,-5"
	net.exe start eduVPNServiceInteractive

UnregisterOpenVPNInteractiveService :: \
	UnregisterOpenVPNInteractiveServiceSCM
	-reg.exe delete "HKLM\Software\eduVPN" /v "exe_path"         $(REG_FLAGS) > NUL
	-reg.exe delete "HKLM\Software\eduVPN" /v "config_dir"       $(REG_FLAGS) > NUL
	-reg.exe delete "HKLM\Software\eduVPN" /v "config_ext"       $(REG_FLAGS) > NUL
	-reg.exe delete "HKLM\Software\eduVPN" /v "log_dir"          $(REG_FLAGS) > NUL
	-reg.exe delete "HKLM\Software\eduVPN" /v "log_append"       $(REG_FLAGS) > NUL
	-reg.exe delete "HKLM\Software\eduVPN" /v "priority"         $(REG_FLAGS) > NUL
	-reg.exe delete "HKLM\Software\eduVPN" /v "ovpn_admin_group" $(REG_FLAGS) > NUL

UnregisterOpenVPNInteractiveServiceSCM ::
	-net.exe stop eduVPNServiceInteractive > NUL 2>&1
	-sc.exe delete eduVPNServiceInteractive > NUL 2>&1


######################################################################
# Setup
######################################################################

Setup :: \
	SetupBuild \
	SetupMSI \
	SetupExe


######################################################################
# Shortcut creation
######################################################################

"$(PROGRAMDATA)\Microsoft\Windows\Start Menu\Programs\$(PRODUCT_NAME).lnk" : \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Client.exe" \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Resources.dll"
	cscript.exe "bin\MkLnk.wsf" //Nologo $@ "$(MAKEDIR)\$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Client.exe" \
		/F:"$(MAKEDIR)\$(OUTPUT_DIR)\$(CFG)\$(PLAT)" \
		/LN:"@$(MAKEDIR)\$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Resources.dll,-1" \
		/C:"@$(MAKEDIR)\$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Resources.dll,-2"


######################################################################
# Building
######################################################################

"$(OUTPUT_DIR)\Release\eduVPN.wixobj" : "eduVPN.wxs"
	"$(WIX)bin\wixcop.exe" $(WIX_WIXCOP_FLAGS) $**
	"$(WIX)bin\candle.exe" $(WIX_CANDLE_FLAGS) -deduVPN.VersionInformational="$(PRODUCT_VERSION_STR)" -out $@ $**

Clean ::
	-if exist "$(OUTPUT_DIR)\Release\eduVPN.wixobj" del /f /q "$(OUTPUT_DIR)\Release\eduVPN.wixobj"

"$(OUTPUT_DIR)\Release\TAP-Windows.wixobj" : "TAP-Windows.wxs"
	"$(WIX)bin\wixcop.exe" $(WIX_WIXCOP_FLAGS) $**
	"$(WIX)bin\candle.exe" $(WIX_CANDLE_FLAGS) -out $@ $**

Clean ::
	-if exist "$(OUTPUT_DIR)\Release\TAP-Windows.wixobj"     del /f /q "$(OUTPUT_DIR)\Release\TAP-Windows.wixobj"
	-if exist "$(OUTPUT_DIR)\Release\tap-windows-9.21.2.exe" del /f /q "$(OUTPUT_DIR)\Release\tap-windows-9.21.2.exe"

"OpenVPN\config-msvc-local.h" : "Makefile"
	copy /y << $@ > NUL
/* This file is auto-generated. */

#undef PACKAGE_NAME
#define PACKAGE_NAME "eduVPN"

#undef PACKAGE_STRING
#define PACKAGE_STRING "$(PRODUCT_NAME) $(PRODUCT_VERSION_STR)"

#undef PACKAGE_TARNAME
#define PACKAGE_TARNAME "eduvpn"

#undef PACKAGE
#define PACKAGE "eduvpn"

#undef PRODUCT_VERSION_MAJOR
#define PRODUCT_VERSION_MAJOR "$(PRODUCT_VERSION_MAJ)"

#undef PRODUCT_VERSION_MINOR
#define PRODUCT_VERSION_MINOR "$(PRODUCT_VERSION_MIN)"

#undef PRODUCT_VERSION_PATCH
#define PRODUCT_VERSION_PATCH "$(PRODUCT_VERSION_REV)"

#undef PACKAGE_VERSION
#define PACKAGE_VERSION "$(PRODUCT_VERSION_STR)"

#undef PRODUCT_VERSION
#define PRODUCT_VERSION "$(PRODUCT_VERSION_STR)"

#undef PRODUCT_BUGREPORT
#define PRODUCT_BUGREPORT "eduvpn@eduvpn.org"

#undef OPENVPN_VERSION_RESOURCE
#define OPENVPN_VERSION_RESOURCE $(PRODUCT_VERSION_MAJ),$(PRODUCT_VERSION_MIN),$(PRODUCT_VERSION_REV),0
<<NOKEEP

Clean ::
	-if exist "OpenVPN\config-msvc-local.h" del /f /q "OpenVPN\config-msvc-local.h"


######################################################################
# Configuration and platform specific rules
######################################################################

CFG=Debug
PLAT=x86
!INCLUDE "BuildCfgPlat.mak"
PLAT=x64
!INCLUDE "BuildCfgPlat.mak"

CFG=Release
PLAT=x86
!INCLUDE "BuildCfgPlat.mak"
PLAT=x64
!INCLUDE "BuildCfgPlat.mak"


######################################################################
# Locale-specific rules
######################################################################

LANG=en-US
!INCLUDE "BuildLang.mak"

LANG=sl
!INCLUDE "BuildLang.mak"
