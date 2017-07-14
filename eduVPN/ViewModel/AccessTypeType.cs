﻿/*
    eduVPN - End-user friendly VPN

    Copyright: 2017, The Commons Conservancy eduVPN Programme
    SPDX-License-Identifier: GPL-3.0+
*/

namespace eduVPN.ViewModel
{
    /// <summary>
    /// User required VPN access type type
    /// </summary>
    public enum AccessTypeType
    {
        /// <summary>
        /// The requested access type is unknown (default).
        /// </summary>
        Unknown = 0,

        /// <summary>
        /// Use VPN to browse internet over a secured channel
        /// (i.e. when using an untrusted public WiFi hotspot).
        /// </summary>
        SecureInternet,

        /// <summary>
        /// Use VPN to access organization's intranet resources.
        /// </summary>
        InstituteAccess,
    }
}
