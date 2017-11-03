#
#   eduVPN - End-user friendly VPN
#
#   Copyright: 2017, The Commons Conservancy eduVPN Programme
#   SPDX-License-Identifier: GPL-3.0+
#

!IF "$(PLAT)" == "x86"
PLAT_NATIVE=Win32
!ELSE
PLAT_NATIVE=$(PLAT)
!ENDIF

SETUP_TARGET=$(PLAT)
!IF "$(CFG)" == "Debug"
SETUP_TARGET=$(SETUP_TARGET)D
!ENDIF

# WiX parameters
WIX_CANDLE_FLAGS_LOCAL=$(WIX_CANDLE_FLAGS) -arch $(PLAT) \
	-deduVPN.TargetDir="bin\$(CFG)\$(PLAT)\\" \
	-deduVPN.OpenVPN.VersionInformational="$(OPENVPN_VERSION_STR) $(SETUP_TARGET)" \
	-deduVPN.Client.VersionInformational="$(PRODUCT_VERSION_STR) $(SETUP_TARGET)"
!IF "$(PLAT)" == "x64"
WIX_CANDLE_FLAGS_LOCAL=$(WIX_CANDLE_FLAGS_LOCAL) -deduVPN.ProgramFilesFolder="ProgramFiles64Folder"
!ELSE
WIX_CANDLE_FLAGS_LOCAL=$(WIX_CANDLE_FLAGS_LOCAL) -deduVPN.ProgramFilesFolder="ProgramFilesFolder"
!ENDIF

!IF "$(CFG)" == "Debug"
VC150REDIST_MSM=Microsoft_VC150_DebugCRT_$(PLAT).msm
!ELSE
VC150REDIST_MSM=Microsoft_VC150_CRT_$(PLAT).msm
!ENDIF


######################################################################
# Setup
######################################################################

!IF "$(CFG)" == "Release"
SetupBuild :: \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)" \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\libeay32.dll" \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\liblzo2-2.dll" \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\libpkcs11-helper-1.dll" \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\openvpn.exe" \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\ssleay32.dll" \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\openvpnserv.exe"

SetupBuild ::
	msbuild.exe "eduVPN.sln" /p:Configuration="$(CFG)" /p:Platform="$(PLAT)" $(MSBUILD_FLAGS)

SetupMSI :: \
	"$(SETUP_DIR)\eduVPNOpenVPN_$(OPENVPN_VERSION_STR)_$(SETUP_TARGET).msi" \
	"$(SETUP_DIR)\eduVPNCore_$(PRODUCT_VERSION_STR)_$(SETUP_TARGET).msi"
!ENDIF


######################################################################
# Building
######################################################################

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)" : "$(OUTPUT_DIR)\$(CFG)"
	if not exist $@ md $@

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Client.exe" \
"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Resources.dll" \
"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\OpenVPN.Resources.dll" ::
	msbuild.exe "eduVPN.sln" /p:Configuration="$(CFG)" /p:Platform="$(PLAT)" $(MSBUILD_FLAGS)

Clean ::
	-msbuild.exe "eduVPN.sln" /t:Clean /p:Configuration="$(CFG)" /p:Platform="$(PLAT)" $(MSBUILD_FLAGS)

"OpenVPN\$(PLAT_NATIVE)-Output\$(CFG)\openvpnserv.exe" ::
	msbuild.exe "OpenVPN\openvpn.sln" /p:Configuration="$(CFG)" /p:Platform="$(PLAT_NATIVE)" $(MSBUILD_FLAGS)

Clean ::
	-msbuild.exe "OpenVPN\openvpn.sln" /t:Clean /p:Configuration="$(CFG)" /p:Platform="$(PLAT_NATIVE)" $(MSBUILD_FLAGS)

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\libeay32.dll" : "$(OUTPUT_DIR)\OpenVPN\$(PLAT)\libeay32.dll"
	copy /y $** $@ > NUL

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\liblzo2-2.dll" : "$(OUTPUT_DIR)\OpenVPN\$(PLAT)\liblzo2-2.dll"
	copy /y $** $@ > NUL

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\libpkcs11-helper-1.dll" : "$(OUTPUT_DIR)\OpenVPN\$(PLAT)\libpkcs11-helper-1.dll"
	copy /y $** $@ > NUL

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\openvpn.exe" : "$(OUTPUT_DIR)\OpenVPN\$(PLAT)\openvpn.exe"
	copy /y $** $@ > NUL

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\openvpnserv.exe" : "OpenVPN\$(PLAT_NATIVE)-Output\$(CFG)\openvpnserv.exe"
	copy /y $** "$(@:"=).tmp" > NUL
!IFDEF MANIFESTCERTIFICATETHUMBPRINT
	signtool.exe sign /sha1 "$(MANIFESTCERTIFICATETHUMBPRINT)" /fd sha256 /as /tr "$(MANIFESTTIMESTAMPRFC3161URL)" /q "$(@:"=).tmp"
!ENDIF
	move /y "$(@:"=).tmp" $@ > NUL

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\ssleay32.dll" : "$(OUTPUT_DIR)\OpenVPN\$(PLAT)\ssleay32.dll"
	copy /y $** $@ > NUL

Clean ::
	-if exist "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\libeay32.dll"           del /f /q "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\libeay32.dll"
	-if exist "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\liblzo2-2.dll"          del /f /q "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\liblzo2-2.dll"
	-if exist "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\libpkcs11-helper-1.dll" del /f /q "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\libpkcs11-helper-1.dll"
	-if exist "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\openvpn.exe"            del /f /q "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\openvpn.exe"
	-if exist "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\openvpnserv.exe"        del /f /q "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\openvpnserv.exe"
	-if exist "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\ssleay32.dll"           del /f /q "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\ssleay32.dll"

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\$(VC150REDIST_MSM)" : "$(VCINSTALLDIR)Redist\MSVC\14.10.25008\MergeModules\$(VC150REDIST_MSM)"
	copy /y $** $@ > NUL

Clean ::
	-if exist "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\$(VC150REDIST_MSM)" del /f /q "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\$(VC150REDIST_MSM)"

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPNOpenVPN.wixobj" : \
	"eduVPNOpenVPN.wxs"
	"$(WIX)bin\wixcop.exe" $(WIX_WIXCOP_FLAGS) "eduVPNOpenVPN.wxs"
	"$(WIX)bin\candle.exe" $(WIX_CANDLE_FLAGS_LOCAL) -out $@ "eduVPNOpenVPN.wxs"

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\OpenVPN.Resources.dll.wixobj" : "OpenVPN.Resources\OpenVPN.Resources.wxs"
	"$(WIX)bin\wixcop.exe" $(WIX_WIXCOP_FLAGS) $**
	"$(WIX)bin\candle.exe" $(WIX_CANDLE_FLAGS_LOCAL) -out $@ $**

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPNCore.wixobj" : \
	"eduVPNCore.wxs" \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\$(VC150REDIST_MSM)"
	"$(WIX)bin\wixcop.exe" $(WIX_WIXCOP_FLAGS) "eduVPNCore.wxs"
	"$(WIX)bin\candle.exe" $(WIX_CANDLE_FLAGS_LOCAL) -deduVPN.VC150RedistMSM="$(VC150REDIST_MSM)" -out $@ "eduVPNCore.wxs"

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduEd25519.dll.wixobj" : "eduEd25519\eduEd25519\eduEd25519.wxs"
	"$(WIX)bin\wixcop.exe" $(WIX_WIXCOP_FLAGS) $**
	"$(WIX)bin\candle.exe" $(WIX_CANDLE_FLAGS_LOCAL) -out $@ $**

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduJSON.dll.wixobj" : "eduJSON\eduJSON\eduJSON.wxs"
	"$(WIX)bin\wixcop.exe" $(WIX_WIXCOP_FLAGS) $**
	"$(WIX)bin\candle.exe" $(WIX_CANDLE_FLAGS_LOCAL) -out $@ $**

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduOAuth.dll.wixobj" : "eduOAuth\eduOAuth\eduOAuth.wxs"
	"$(WIX)bin\wixcop.exe" $(WIX_WIXCOP_FLAGS) $**
	"$(WIX)bin\candle.exe" $(WIX_CANDLE_FLAGS_LOCAL) -out $@ $**

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduOpenVPN.dll.wixobj" : "eduOpenVPN\eduOpenVPN\eduOpenVPN.wxs"
	"$(WIX)bin\wixcop.exe" $(WIX_WIXCOP_FLAGS) $**
	"$(WIX)bin\candle.exe" $(WIX_CANDLE_FLAGS_LOCAL) -out $@ $**

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.dll.wixobj" : "eduVPN\eduVPN.wxs"
	"$(WIX)bin\wixcop.exe" $(WIX_WIXCOP_FLAGS) $**
	"$(WIX)bin\candle.exe" $(WIX_CANDLE_FLAGS_LOCAL) -out $@ $**

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Resources.dll.wixobj" : "eduVPN.Resources\eduVPN.Resources.wxs"
	"$(WIX)bin\wixcop.exe" $(WIX_WIXCOP_FLAGS) $**
	"$(WIX)bin\candle.exe" $(WIX_CANDLE_FLAGS_LOCAL) -out $@ $**

"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Client.exe.wixobj" : "eduVPN.Client\eduVPN.Client.wxs"
	"$(WIX)bin\wixcop.exe" $(WIX_WIXCOP_FLAGS) $**
	"$(WIX)bin\candle.exe" $(WIX_CANDLE_FLAGS_LOCAL) -out $@ $**

Clean ::
	-if exist "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPNOpenVPN.wixobj"         del /f /q "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPNOpenVPN.wixobj"
	-if exist "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\OpenVPN.Resources.dll.wixobj" del /f /q "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\OpenVPN.Resources.dll.wixobj"
	-if exist "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPNCore.wixobj"            del /f /q "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPNCore.wixobj"
	-if exist "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduEd25519.dll.wixobj"        del /f /q "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduEd25519.dll.wixobj"
	-if exist "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduJSON.dll.wixobj"           del /f /q "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduJSON.dll.wixobj"
	-if exist "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduOAuth.dll.wixobj"          del /f /q "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduOAuth.dll.wixobj"
	-if exist "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduOpenVPN.dll.wixobj"        del /f /q "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduOpenVPN.dll.wixobj"
	-if exist "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.dll.wixobj"            del /f /q "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.dll.wixobj"
	-if exist "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Resources.dll.wixobj"  del /f /q "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Resources.dll.wixobj"
	-if exist "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Client.exe.wixobj"     del /f /q "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPN.Client.exe.wixobj"

"$(SETUP_DIR)\eduVPNOpenVPN_$(OPENVPN_VERSION_STR)_$(SETUP_TARGET).msi" : \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPNOpenVPN_$(OPENVPN_VERSION_STR)_$(SETUP_TARGET)_sl.mst" \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPNOpenVPN_$(OPENVPN_VERSION_STR)_$(SETUP_TARGET)_en-US.msi"
	copy /y "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPNOpenVPN_$(OPENVPN_VERSION_STR)_$(SETUP_TARGET)_en-US.msi" "$(@:"=).tmp" > NUL
	cscript.exe $(CSCRIPT_FLAGS) "bin\MSI.wsf" //Job:AddStorage "$(@:"=).tmp" "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPNOpenVPN_$(OPENVPN_VERSION_STR)_$(SETUP_TARGET)_sl.mst" 1060 /L
!IFDEF MANIFESTCERTIFICATETHUMBPRINT
	signtool.exe sign /sha1 "$(MANIFESTCERTIFICATETHUMBPRINT)" /t "$(MANIFESTTIMESTAMPURL)" /d "eduVPN Client OpenVPN Components" /q "$(@:"=).tmp"
!ENDIF
	attrib.exe +r "$(@:"=).tmp"
	if exist $@ attrib.exe -r $@
	move /y "$(@:"=).tmp" $@ > NUL

"$(SETUP_DIR)\eduVPNCore_$(PRODUCT_VERSION_STR)_$(SETUP_TARGET).msi" : \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPNCore_$(PRODUCT_VERSION_STR)_$(SETUP_TARGET)_sl.mst" \
	"$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPNCore_$(PRODUCT_VERSION_STR)_$(SETUP_TARGET)_en-US.msi"
	copy /y "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPNCore_$(PRODUCT_VERSION_STR)_$(SETUP_TARGET)_en-US.msi" "$(@:"=).tmp" > NUL
	cscript.exe $(CSCRIPT_FLAGS) "bin\MSI.wsf" //Job:AddStorage "$(@:"=).tmp" "$(OUTPUT_DIR)\$(CFG)\$(PLAT)\eduVPNCore_$(PRODUCT_VERSION_STR)_$(SETUP_TARGET)_sl.mst" 1060 /L
!IFDEF MANIFESTCERTIFICATETHUMBPRINT
	signtool.exe sign /sha1 "$(MANIFESTCERTIFICATETHUMBPRINT)" /t "$(MANIFESTTIMESTAMPURL)" /d "eduVPN Client Core" /q "$(@:"=).tmp"
!ENDIF
	attrib.exe +r "$(@:"=).tmp"
	if exist $@ attrib.exe -r $@
	move /y "$(@:"=).tmp" $@ > NUL

Clean ::
	-if exist "$(SETUP_DIR)\eduVPNOpenVPN_$(OPENVPN_VERSION_STR)_$(SETUP_TARGET).msi" del /f /q "$(SETUP_DIR)\eduVPNOpenVPN_$(OPENVPN_VERSION_STR)_$(SETUP_TARGET).msi"
	-if exist "$(SETUP_DIR)\eduVPNCore_$(PRODUCT_VERSION_STR)_$(SETUP_TARGET).msi"    del /f /q "$(SETUP_DIR)\eduVPNCore_$(PRODUCT_VERSION_STR)_$(SETUP_TARGET).msi"


######################################################################
# Locale-specific rules
######################################################################

LANG=en-US
!INCLUDE "MakefileCfgPlatLang.mak"

LANG=sl
!INCLUDE "MakefileCfgPlatLang.mak"