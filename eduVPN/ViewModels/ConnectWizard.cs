﻿/*
    eduVPN - End-user friendly VPN

    Copyright: 2017, The Commons Conservancy eduVPN Programme
    SPDX-License-Identifier: GPL-3.0+
*/

using Prism.Mvvm;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading;
using System.Windows.Threading;

namespace eduVPN.ViewModels
{
    /// <summary>
    /// Connect wizard
    /// </summary>
    public class ConnectWizard : BindableBase, IDisposable
    {
        #region Fields

        /// <summary>
        /// Instance directory URI IDs as used in <c>Properties.Settings.Default</c> collection
        /// </summary>
        private static readonly string[] _instance_directory_id = new string[]
        {
            "SecureInternetDirectory",
            "InstituteAccessDirectory",
        };

        #endregion

        #region Properties

        /// <summary>
        /// UI thread's dispatcher
        /// </summary>
        /// <remarks>
        /// Background threads must raise property change events in the UI thread.
        /// </remarks>
        public Dispatcher Dispatcher { get; }

        /// <summary>
        /// Token used to abort unfinished background processes in case of application shutdown.
        /// </summary>
        public static CancellationTokenSource Abort { get => _abort; }
        private static CancellationTokenSource _abort = new CancellationTokenSource();

        /// <summary>
        /// The page error; <c>null</c> when no error condition.
        /// </summary>
        public Exception Error
        {
            get { return _error; }
            set { _error = value; RaisePropertyChanged(); }
        }
        private Exception _error;

        /// <summary>
        /// Is wizard performing background tasks?
        /// </summary>
        public bool IsBusy
        {
            get { return _task_count > 0; }
        }

        /// <summary>
        /// Number of background tasks the wizard is performing
        /// </summary>
        public int TaskCount
        {
            get { lock (_task_count_lock) return _task_count; }
        }
        private int _task_count;
        private object _task_count_lock = new object();

        /// <summary>
        /// Available instance sources
        /// </summary>
        public Models.InstanceSourceInfo[] InstanceSources
        {
            get { return _instance_sources; }
        }
        private Models.InstanceSourceInfo[] _instance_sources;

        /// <summary>
        /// VPN configuration histories
        /// </summary>
        public ObservableCollection<Models.VPNConfiguration>[] ConfigurationHistories
        {
            get { return _configuration_histories; }
        }
        private ObservableCollection<Models.VPNConfiguration>[] _configuration_histories;

        /// <summary>
        /// Selected instance source
        /// </summary>
        public Models.InstanceSourceInfo InstanceSource
        {
            get { return _instance_source; }
            set { _instance_source = value; RaisePropertyChanged(); }
        }
        private Models.InstanceSourceInfo _instance_source;

        /// <summary>
        /// VPN configuration
        /// </summary>
        public Models.VPNConfiguration Configuration
        {
            get { return _configuration; }
            set { _configuration = value; RaisePropertyChanged(); }
        }
        private Models.VPNConfiguration _configuration;

        /// <summary>
        /// VPN session
        /// </summary>
        public Models.VPNSession Session
        {
            get { return _session; }
            set { _session = value; RaisePropertyChanged(); }
        }
        private Models.VPNSession _session;

        #region Pages

        /// <summary>
        /// The page the wizard is currently displaying
        /// </summary>
        public ConnectWizardPage CurrentPage
        {
            get { return _current_page; }
            set
            {
                _current_page = value;
                RaisePropertyChanged();
                _current_page.OnActivate();
            }
        }
        private ConnectWizardPage _current_page;

        /// <summary>
        /// Initializing wizard page
        /// </summary>
        public InitializingPage InitializingPage
        {
            get
            {
                if (_initializing_page == null)
                    _initializing_page = new InitializingPage(this);
                return _initializing_page;
            }
        }
        private InitializingPage _initializing_page;

        /// <summary>
        /// Instance source page
        /// </summary>
        public InstanceSourceSelectPage InstanceSourceSelectPage
        {
            get
            {
                if (_instance_source_page == null)
                    _instance_source_page = new InstanceSourceSelectPage(this);
                return _instance_source_page;
            }
        }
        private InstanceSourceSelectPage _instance_source_page;

        /// <summary>
        /// Instance selection page
        /// </summary>
        public InstanceSelectPage InstanceSelectPage
        {
            get
            {
                if (InstanceSource is Models.DistributedInstanceSourceInfo)
                {
                    if (_country_select_page == null)
                        _country_select_page = new CountrySelectPage(this);
                    return _country_select_page;
                }
                else
                {
                    if (_institute_select_page == null)
                        _institute_select_page = new InstituteSelectPage(this);
                    return _institute_select_page;
                }
            }
        }
        private CountrySelectPage _country_select_page;
        private InstituteSelectPage _institute_select_page;

        /// <summary>
        /// Custom instance source page
        /// </summary>
        public CustomInstanceSourcePage CustomInstanceSourcePage
        {
            get
            {
                if (_custom_instance_source_page == null)
                    _custom_instance_source_page = new CustomInstanceSourcePage(this);
                return _custom_instance_source_page;
            }
        }
        private CustomInstanceSourcePage _custom_instance_source_page;

        /// <summary>
        /// Authorization wizard page
        /// </summary>
        public AuthorizationPage AuthorizationPage
        {
            get
            {
                if (_authorization_page == null)
                    _authorization_page = new AuthorizationPage(this);
                return _authorization_page;
            }
        }
        private AuthorizationPage _authorization_page;

        /// <summary>
        /// (Instance and) profile selection wizard page
        /// </summary>
        public ProfileSelectBasePage ProfileSelectPage
        {
            get
            {
                if (InstanceSource is Models.FederatedInstanceSourceInfo ||
                    InstanceSource is Models.DistributedInstanceSourceInfo)
                {
                    if (_instance_and_profile_select_page == null)
                        _instance_and_profile_select_page = new InstanceAndProfileSelectPage(this);
                    return _instance_and_profile_select_page;
                }
                else
                {
                    if (_profile_select_page == null)
                        _profile_select_page = new ProfileSelectPage(this);
                    return _profile_select_page;
                }
            }
        }
        private ProfileSelectPage _profile_select_page;
        private InstanceAndProfileSelectPage _instance_and_profile_select_page;

        /// <summary>
        /// Status wizard page
        /// </summary>
        public StatusPage StatusPage
        {
            get
            {
                if (_status_page == null)
                    _status_page = new StatusPage(this);
                return _status_page;
            }
        }
        private StatusPage _status_page;

        #endregion

        #endregion

        #region Constructors

        /// <summary>
        /// Constructs the wizard
        /// </summary>
        public ConnectWizard()
        {
            // Save UI thread's dispatcher.
            Dispatcher = Dispatcher.CurrentDispatcher;

            if (Properties.Settings.Default.SettingsVersion == 0)
            {
                // Migrate settings from previous version.
                Properties.Settings.Default.Upgrade();
                Properties.Settings.Default.SettingsVersion = 1;
            }

            Dispatcher.ShutdownStarted += (object sender, EventArgs e) => {
                // Raise the abort flag to gracefully shutdown all background threads.
                Abort.Cancel();

                // Persist settings to disk.
                Properties.Settings.Default.Save();
            };

            Configuration = new Models.VPNConfiguration();

            // Show initializing wizard page.
            CurrentPage = InitializingPage;

            _instance_sources = new Models.InstanceSourceInfo[_instance_directory_id.Length];
            _configuration_histories = new ObservableCollection<Models.VPNConfiguration>[_instance_directory_id.Length];

            // Spawn instance source loading threads.
            var threads = new Thread[_instance_directory_id.Length];
            for (var i = 0; i < _instance_directory_id.Length; i++)
            {
                // Launch instance source load in the background.
                threads[i] = new Thread(new ParameterizedThreadStart(
                    param =>
                    {
                        var source_index = (int)param;
                        for (;;)
                        {
                            try
                            {
                                // Get instance source.
                                var response_cache = JSON.Response.Get(
                                    uri: new Uri((string)Properties.Settings.Default[_instance_directory_id[source_index]]),
                                    pub_key: Convert.FromBase64String((string)Properties.Settings.Default[_instance_directory_id[source_index] + "PubKey"]),
                                    ct: Abort.Token,
                                    previous: (JSON.Response)Properties.Settings.Default[_instance_directory_id[source_index] + "Cache"]);

                                // Parse instance source JSON.
                                var obj = (Dictionary<string, object>)eduJSON.Parser.Parse(
                                    response_cache.Value,
                                    Abort.Token);

                                // Load instance source.
                                _instance_sources[source_index] = Models.InstanceSourceInfo.FromJSON(obj);

                                if (response_cache.IsFresh)
                                {
                                    // If we got here, the loaded instance source is (probably) OK. Update cache.
                                    Properties.Settings.Default[_instance_directory_id[source_index] + "Cache"] = response_cache;
                                }

                                _configuration_histories[source_index] = new ObservableCollection<Models.VPNConfiguration>();

                                // Load configuration histories from settings.
                                var hist = (Models.VPNConfigurationSettingsList)Properties.Settings.Default[_instance_directory_id[source_index] + "ConfigHistory"];
                                foreach (var h in hist)
                                {
                                    var cfg = new Models.VPNConfiguration();

                                    try
                                    {
                                        // Restore configuration.
                                        if (_instance_sources[source_index] is Models.LocalInstanceSourceInfo instance_source_local &&
                                            h is Models.LocalVPNConfigurationSettings h_local)
                                        {
                                            // Local authenticating instance source:
                                            // - Restore instance, which is both: authenticating and connecting.
                                            // - Restore access token.
                                            // - Restore profile.
                                            cfg.AuthenticatingInstance = instance_source_local.Where(inst => inst.Base.AbsoluteUri == h_local.Instance.Base.AbsoluteUri).FirstOrDefault();
                                            if (cfg.AuthenticatingInstance == null) cfg.AuthenticatingInstance = h_local.Instance;
                                            cfg.AccessToken = h_local.AccessToken;
                                            if (cfg.AccessToken == null) continue;
                                            cfg.ConnectingInstance = cfg.AuthenticatingInstance;
                                            cfg.ConnectingProfile = cfg.ConnectingInstance.GetProfileList(cfg.AccessToken, Abort.Token).Where(p => p.ID == h_local.Profile).FirstOrDefault();
                                            if (cfg.ConnectingProfile == null) continue;
                                        }
                                        else if (_instance_sources[source_index] is Models.DistributedInstanceSourceInfo instance_source_distributed &&
                                            h is Models.DistributedVPNConfigurationSettings h_distributed)
                                        {
                                            // Distributed authenticating instance source:
                                            // - Restore authenticating instance.
                                            // - Restore access token.
                                            // - Restore last connected instance (optional).
                                            cfg.AuthenticatingInstance = instance_source_distributed.Where(inst => inst.Base.AbsoluteUri == h_distributed.AuthenticatingInstance).FirstOrDefault();
                                            if (cfg.AuthenticatingInstance == null) continue;
                                            cfg.AccessToken = h_distributed.AccessToken;
                                            if (cfg.AccessToken == null) continue;
                                            cfg.ConnectingInstance = instance_source_distributed.Where(inst => inst.Base.AbsoluteUri == h_distributed.LastInstance).FirstOrDefault();
                                        }
                                        else if (_instance_sources[source_index] is Models.FederatedInstanceSourceInfo instance_source_federated &&
                                            h is Models.FederatedVPNConfigurationSettings h_federated)
                                        {
                                            // Federated authenticating instance source:
                                            // - Get authenticating instance from federated instance source settings.
                                            // - Restore access token.
                                            // - Restore last connected instance (optional).
                                            cfg.AuthenticatingInstance = new Models.InstanceInfo(instance_source_federated);
                                            cfg.AccessToken = h_federated.AccessToken;
                                            if (cfg.AccessToken == null) continue;
                                            cfg.ConnectingInstance = instance_source_federated.Where(inst => inst.Base.AbsoluteUri == h_federated.LastInstance).FirstOrDefault();
                                        }
                                        else
                                            continue;
                                    }
                                    catch (Exception) { continue; }

                                    // Configuration successfuly restored. Add it.
                                    _configuration_histories[source_index].Add(cfg);
                                }

                                break;
                            }
                            catch (OperationCanceledException) { throw; }
                            catch (Exception ex)
                            {
                                // Make it a clean start next time.
                                Properties.Settings.Default[_instance_directory_id[source_index] + "Cache"] = null;

                                // Notify the sender the instance source loading failed. However, continue with other instance sources.
                                // This will overwrite all previous error messages.
                                Error = new AggregateException(String.Format(Resources.Strings.ErrorInstanceSourceInfoLoad, _instance_directory_id[source_index]), ex);
                            }

                            // Sleep for 3s, then retry.
                            if (Abort.Token.WaitHandle.WaitOne(TimeSpan.FromSeconds(3)))
                                break;
                        }
                    }));
                threads[i].Start(i);
            }

            // Spawn monitor thread to wait for initialization to complete.
            new Thread(new ThreadStart(
                () =>
                {
                    Dispatcher.Invoke(DispatcherPriority.Normal, (Action)(() => ChangeTaskCount(+1)));
                    try
                    {
                        // Wait for all threads.
                        foreach (var thread in threads)
                            thread.Join();

                        // Proceed to the "first" page.
                        Dispatcher.Invoke(DispatcherPriority.Normal, (Action)(() => Error = null));
                        CurrentPage = InstanceSourceSelectPage;
                    }
                    finally { Dispatcher.Invoke(DispatcherPriority.Normal, (Action)(() => ChangeTaskCount(-1))); }
                })).Start();
        }

        #endregion

        #region Methods

        /// <summary>
        /// Increments or decrements number of background tasks the wizard is performing
        /// </summary>
        /// <param name="increment">Positive to increment, negative to decrement</param>
        public void ChangeTaskCount(int increment)
        {
            lock (_task_count_lock)
                _task_count += increment;

            RaisePropertyChanged("TaskCount");
            RaisePropertyChanged("IsBusy");
        }

        /// <summary>
        /// Starts VPN session
        /// </summary>
        public void StartSession()
        {
            Session = new Models.OpenVPNSession(Configuration.ConnectingInstance, Configuration.ConnectingProfile, Configuration.AccessToken);

            // Save session configuration to history.
            var source_index = Array.IndexOf(InstanceSources, InstanceSource);
            if (source_index >= 0)
            {
                var hist = (Models.VPNConfigurationSettingsList)Properties.Settings.Default[_instance_directory_id[source_index] + "ConfigHistory"];
                Models.VPNConfigurationSettings el = null;
                if (_instance_sources[source_index] is Models.LocalInstanceSourceInfo)
                {
                    // Local authenticating instance source
                    el = new Models.LocalVPNConfigurationSettings()
                    {
                        Instance = Configuration.ConnectingInstance,
                        AccessToken = Configuration.AccessToken,
                        Profile = Configuration.ConnectingProfile.ID,
                    };
                }
                else if (_instance_sources[source_index] is Models.DistributedInstanceSourceInfo)
                {
                    // Distributed authenticating instance source
                    el = new Models.DistributedVPNConfigurationSettings()
                    {
                        AuthenticatingInstance = Configuration.AuthenticatingInstance.Base.AbsoluteUri,
                        AccessToken = Configuration.AccessToken,
                        LastInstance = Configuration.ConnectingInstance.Base.AbsoluteUri,
                    };
                }
                else if (_instance_sources[source_index] is Models.FederatedInstanceSourceInfo)
                {
                    // Federated authenticating instance source.
                    el = new Models.FederatedVPNConfigurationSettings()
                    {
                        AccessToken = Configuration.AccessToken,
                        LastInstance = Configuration.ConnectingInstance.Base.AbsoluteUri,
                    };
                }

                if (el != null)
                {
                    // Check for duplicates and update popularity.
                    int found = -1;
                    for (var i = hist.Count; i-- > 0;)
                    {
                        if (hist[i].AccessToken == null)
                        {
                            // Remove configurations with no access token.
                            hist.RemoveAt(i);
                            continue;
                        }

                        if (hist[i].Equals(el))
                        {
                            if (found < 0)
                            {
                                // Upvote popularity && refresh access token.
                                hist[i].Popularity *= 1.1f;
                                hist[i].AccessToken = el.AccessToken;
                                found = i;
                            }
                            else
                            {
                                // We found a match second time. This happened early in the Alpha stage when duplicate checking didn't work right.
                                // Clean the list. The victim is the entry with access token expiring sooner.
                                if (hist[i].AccessToken.Expires < hist[found].AccessToken.Expires)
                                {
                                    hist[found].Popularity = Math.Max(hist[i].Popularity, hist[found].Popularity);
                                    hist.RemoveAt(i);
                                    found--;
                                }
                                else
                                {
                                    hist[i].Popularity = Math.Max(hist[i].Popularity, hist[found].Popularity);
                                    hist.RemoveAt(found);
                                    found = i;
                                }
                            }
                        }
                        else
                        {
                            // Downvote popularity.
                            hist[i].Popularity /= 1.1f;
                        }
                    }
                    if (found < 0)
                        hist.Add(el);
                }
            }

            // Launch VPN session in the background.
            new Thread(new ThreadStart(
                () =>
                {
                    Dispatcher.Invoke(DispatcherPriority.Normal, (Action)(() => Error = null));
                    try
                    {
                        Session.Run(Abort.Token);
                    }
                    catch (OperationCanceledException) { }
                    catch (Exception ex) { Dispatcher.Invoke(DispatcherPriority.Normal, (Action)(() => { Error = ex; })); }
                })).Start();
        }

        #endregion

        #region IDisposable Support
        private bool disposedValue = false; // To detect redundant calls

        protected virtual void Dispose(bool disposing)
        {
            if (!disposedValue)
            {
                if (disposing)
                {
                    if (_session != null)
                    {
                        _session.Dispose();
                        _session = null;
                    }
                }

                disposedValue = true;
            }
        }

        // This code added to correctly implement the disposable pattern.
        public void Dispose()
        {
            // Do not change this code. Put cleanup code in Dispose(bool disposing) above.
            Dispose(true);
        }
        #endregion
    }
}
