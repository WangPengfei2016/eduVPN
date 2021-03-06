#
#   eduVPN - VPN for education and research
#
#   Copyright: 2017-2019 The Commons Conservancy eduVPN Programme
#   SPDX-License-Identifier: GPL-3.0+
#

CLIENT_TARGET=LetsConnect
CLIENT_TITLE=Let's Connect!
CLIENT_UPGRADE_CODE={5F7860D5-5563-4492-930B-C8C77A539504}
CLIENT_ABOUT_URL=https://letsconnect-vpn.org/

IDS_CLIENT_TITLE=101
IDS_CLIENT_DESCRIPTION=102
IDS_CLIENT_PUBLISHER=103
IDS_CORE_TITLE=104

WIX_CANDLE_FLAGS_CFG_PLAT_CLIENT=$(WIX_CANDLE_FLAGS_CFG_PLAT) \
	-dTAPWinPre.ProductGUID="$(LETSCONNECT_TAPWINPRE_VERSION_GUID)" \
	-dOpenVPN.ProductGUID="$(LETSCONNECT_OPENVPN_VERSION_GUID)" \
	-dCore.ProductGUID="$(LETSCONNECT_CORE_VERSION_GUID)" \
!IF "$(PLAT)" == "x64"
	-dTAPWinPre.UpgradeGUID="{CF82B6AD-EA1D-4DBA-8328-84E164701793}" \
	-dOpenVPN.UpgradeGUID="{4EB92ECE-8B6E-4FFF-9DD2-8626FB90BCD3}" \
	-dCore.UpgradeGUID="{090C24F6-1F11-4DB8-9338-68E3526139F5}"
!ELSE
	-dTAPWinPre.UpgradeGUID="{BC858264-4A39-4917-AB32-6A8DA8C12C72}" \
	-dOpenVPN.UpgradeGUID="{973B9D4D-16BD-4CEC-8B6C-7729D58B0BF9}" \
	-dCore.UpgradeGUID="{76E93AAB-1F90-4AA3-B7EE-F697A4B1B479}"
!ENDIF
