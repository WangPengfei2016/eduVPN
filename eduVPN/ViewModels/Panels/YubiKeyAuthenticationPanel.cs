﻿/*
    eduVPN - End-user friendly VPN

    Copyright: 2017, The Commons Conservancy eduVPN Programme
    SPDX-License-Identifier: GPL-3.0+
*/

using eduVPN.Models;
using eduVPN.ViewModels.Windows;
using System.Net;

namespace eduVPN.ViewModels.Panels
{
    /// <summary>
    /// YubiKey authentication response panel class
    /// </summary>
    public class YubiKeyAuthenticationPanel : TwoFactorAuthenticationBasePanel
    {
        #region Properties

        /// <inheritdoc/>
        public override string ID { get => "yubi"; }

        /// <inheritdoc/>
        public override string DisplayName { get => Resources.Strings.TwoFactorAuthenticationMethodYubiKey; }

        #endregion

        #region Constructors

        /// <summary>
        /// Construct a panel
        /// </summary>
        /// <param name="parent">The page parent</param>
        public YubiKeyAuthenticationPanel(ConnectWizard parent) :
            base(parent)
        {
        }

        #endregion

        #region Methods

        /// <inheritdoc/>
        protected override TwoFactorEnrollmentCredentials GetEnrollmentCredentials()
        {
            return new YubiKeyEnrollmentCredentials()
            {
                Response = (new NetworkCredential("", Response)).SecurePassword
            };
        }

        #endregion
    }
}
