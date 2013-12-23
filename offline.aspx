﻿<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="offline.aspx.cs" Inherits="Viewer.index" %>

<!DOCTYPE html>
    <html id="HtmlTag" runat="server">

    <head runat="server">
       <title></title>
       <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,minimum-scale=1,user-scalable=no"/>

        <!-- IE specifics -->
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
   
        <!--[if lte IE 8]>
            <link rel="stylesheet" type="text/css" href="Resources/Styles/IE.css" />
        <![endif]-->

        <script type="text/javascript"> // <![CDATA[

            var link = document.createElement('link');
            link.setAttribute('rel', 'stylesheet');
            link.setAttribute('href', document.location.protocol + '//js.arcgis.com/3.6/js/esri/css/esri.css');
            document.getElementsByTagName('head')[0].appendChild(link);

            // ]]>
        </script>

        <link rel="stylesheet" href="Resources/Styles/Common.css" />
        <link rel="stylesheet" href="Resources/Styles/Animations.css" />

        <link rel="shortcut icon" href="favicon.ico" />

        <script>
            // This is a function so that we can hook a callback to get called when the native app is ready for us to call it's JavaScript API 
            var addNativeReadyFunction = function (callback) {
                // If the gcxNativeReady flag is set, we're ready to call the callback now 
                if (typeof gcxNativeReady !== "undefined") {
                    if (callback)
                        callback();
                }
                    // Otherwise, wait until it's ready 
                else {
                    var oldNativeReadyCallback = window.gcxNativeReadyCallback;
                    window.gcxNativeReadyCallback = function () {
                        if (oldNativeReadyCallback)
                            oldNativeReadyCallback();
                        if (callback)
                            callback();
                    }
                }
            }

            if (navigator.userAgent.indexOf("GeocortexApp") > -1) {
                // If the file system already exists, Cordova is not needed 
                var _cordovaRequestFileSystem;
                if (!window.requestFileSystem) {
                    var _requestFileSystemPlaceholder = function () {
                        var _storedArguments = arguments;
                        var _storedThis = this;

                        addNativeReadyFunction(function () {
                            if (_cordovaRequestFileSystem && window.requestFileSystem != _cordovaRequestFileSystem)
                                window.requestFileSystem = _cordovaRequestFileSystem;
                            window.requestFileSystem.apply(_storedThis, _storedArguments);
                        });
                    }
                    window.requestFileSystem = _requestFileSystemPlaceholder;
                    if (typeof window.LocalFileSystem === "undefined")
                        window.LocalFileSystem = {};
                    window.LocalFileSystem.PERSISTENT = 1;
                    window.LocalFileSystem.TEMPORARY = 0;

                    var pollingToken;
                    var _pollForCordovaFileSystem = function () {
                        if (window.requestFileSystem != _requestFileSystemPlaceholder) {
                            _cordovaRequestFileSystem = window.requestFileSystem;
                            window.requestFileSystem = _requestFileSystemPlaceholder;
                            window.clearInterval(pollingToken);
                        }
                    }
                    pollingToken = window.setInterval(_pollForCordovaFileSystem, 10);
                }
            }
        </script> 
        <script type="text/javascript"> // <![CDATA[

            var uri = document.URL;
            var ua = navigator.userAgent.toLowerCase();

            var urlParams = null;
            var shellName = null;

            if (uri.indexOf("?") != -1) {
                urlParams = uri.substring(uri.indexOf("?") + 1, uri.length);
            }

            // Only do the redirect if we do not have a ViewerConfigUri specified.
            if (!urlParams || (urlParams && urlParams.toLowerCase().indexOf("viewerconfiguri") < 0)) {

                var userAgentContains = function (token) {
                    return ua.indexOf(token.toLowerCase()) > -1;
                };

                if ((userAgentContains("Android") && userAgentContains("mobile")) ||
                    (userAgentContains("Windows") && userAgentContains("Phone")) ||
                    (userAgentContains("iPhone") || userAgentContains("iPod")) ||
                    (userAgentContains("BlackBerry") || userAgentContains("BB10"))) {
                    shellName = "Handheld";
                }
                else if (userAgentContains("Android") ||
                         userAgentContains("iPad") ||
                         userAgentContains("Playbook") ||
                         userAgentContains("Touch")) {
                    shellName = "Tablet";
                }
                else {
                    shellName = "Desktop";
                }
            }
            // ]]>
        </script>

        <script type="text/javascript" src="online.js"></script>
        <script>
            var dojoConfig = {
                deps: [],
                callback: function () {
                    var originalDefine = define;
                    var ignoreCount = 0;
                    define = function () {
                        if (arguments.length >= 1 && arguments[0] == "esri/request") {
                            if (ignoreCount > 0) {
                                define = originalDefine;
                                originalDefine.apply(window, Array.prototype.slice.call(arguments, 1));
                                return;
                            } else {
                                ignoreCount = 1;
                            }
                        }
                        originalDefine.apply(window, arguments);
                    };

                    define("esri/request", ["//js.arcgis.com/3.6/js/esri/request.js"], function (requestBase) {
                        if (!esri.request) {
                            esri.request = requestBase;
                        }

                        return function esri_request_hooked() {
                            return esri.request.apply(this, arguments);
                        };
                    });
                }
            };
        </script>
        <script type="text/javascript" src="//js.arcgis.com/3.6/init.js"></script>
        <script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/1.8/jquery.min.js"></script>
        <script type="text/javascript" src="Resources/Scripts/jquery.ui.custom.js"></script>
        <script type="text/javascript" src="Resources/Scripts/modernizr.js"></script>

        <script type="text/javascript"> // <![CDATA[

            dojo.require("dojo.DeferredList");
            dojo.require("dojo.i18n");
            dojo.require("esri.map");
            dojo.require("esri.toolbars.draw");
            dojo.require("esri.toolbars.edit");

            geocortex = {};

            dojo.ready(function () {

                // Adds Fastclick to the page. Any elements which we don't want fastclick on should have the 
                // 'needsclick' class. ex. Map
                if (shellName !== "Handheld") {
                    new FastClick(document.body);
                }

                var viewerConfig = {
                    "configurations": {
                        "default": "Resources/Config/Default/" + shellName + ".json.js"
                    },

                    "viewerConfigUri": null
                };

                // Do we have a viewer specified?
                var uri = document.URL;
                var query = uri.substring(uri.indexOf("?") + 1, uri.length);
                var urlParams = dojo.queryToObject(query);

                // If a configuration base has been specified, use it to update the default configuration.
                if (urlParams.hasOwnProperty("configBase")) {
                    var configBase = urlParams["configBase"];

                    if (configBase.charAt(configBase.length - 1) !== "/") {
                        configBase = configBase + "/";
                    }

                    viewerConfig["configurations"]["default"] = configBase + shellName + ".json.js";
                }

                viewerConfig["viewerConfigUri"] = urlParams["viewerConfigUri"];

                // Grab the viewers configuration by viewer name.
                var viewerName = urlParams["viewer"] || "default";

                // If we don't have a viewerConfigUri param, use the viewerName param.
                if (!viewerConfig["viewerConfigUri"]) {
                    viewerConfig.viewerConfigUri = viewerConfig["configurations"][viewerName.toLocaleLowerCase()];
                }

                // Process the viewer URL. The path to config is used as a base path for certain resources.
                var viewerConfigPathPieces = viewerConfig.viewerConfigUri.split("/");
                var viewerConfigPath = viewerConfigPathPieces.slice(0, viewerConfigPathPieces.length - 1).join("/") + "/";

                // Create a viewer ID using the absolute path of this viewer's config folder. This ID is used to save offline resources for
                // a particular viewer.
                var absoluteViewerConfigPath = geocortex.framework.utils.makeUrlAbsolute(viewerConfigPath);
                var viewerId = String.quickHashCode(absoluteViewerConfigPath);

                // Go.
                var viewer = new geocortex.essentialsHtmlViewer.ViewerApplication(viewerConfig.viewerConfigUri, null, viewerId);
                viewer.shellName = shellName;
                viewer.viewerConfigPath = viewerConfigPath;
                viewer.isOffline.set(window.gcxBootOffline || (urlParams["offline"] != null && urlParams["offline"] != "false"));
                viewer.debugMode = (urlParams["debug"] != null && urlParams["debug"] != "false");
                viewer.urlParameters = urlParams;


                // Handle configuration load failed. This will occur when configuration cannot be loaded while offline.
                viewer.eventRegistry.event("ConfigurationLoadFailedEvent").subscribe(this, function () {
                    alert("An error occurred while fetching configuration, preventing the application from loading.");
                });

                viewer.initialize();
            });
            // ]]>
        </script>

        <script src="Resources/Compiled/Essentials.js" type="text/javascript"></script>
        <script src="Resources/Compiled/Framework.js" type="text/javascript"></script>
        <script src="Resources/Compiled/Framework.UI.js" type="text/javascript"></script>
        <script src="Resources/Compiled/Mapping.Infrastructure.js" type="text/javascript"></script>
        <script src="Resources/Scripts/fastclick.js" type="text/javascript"></script>
    </head>
    <body>
        <div class="shell-large" data-region-name="ApplicationRegion" data-region-adapter="geocortex.framework.ui.MultiDivRegionAdapter"></div>
    </body>
</html>