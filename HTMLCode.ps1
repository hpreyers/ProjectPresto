[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# HTML Code

$HTML = @"
<!DOCTYPE html>
<head>
    <meta http-equiv="X-UA-Compatible" content="IE=11">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <script src="https://code.jquery.com/jquery-3.3.1.min.js" integrity="sha256-FgpCb/KJQlLNfOu91ta32o/NMZxltwRo8QtmkMRdAu8=" crossorigin="anonymous"></script>    
    <link rel="stylesheet" id="dark" title="dark" href="https://unpkg.com/@clr/ui/clr-ui-dark.min.css"/>
    <link rel="stylesheet alternate" id="light" title="light" href="https://unpkg.com/@clr/ui/clr-ui.min.css" disabled=true />
    <link rel="stylesheet" href="https://unpkg.com/@clr/icons/clr-icons.min.css" />
    <script src="https://unpkg.com/@webcomponents/custom-elements/custom-elements.min.js"></script>
    <script src="https://unpkg.com/@clr/icons/clr-icons.min.js"></script>
    <script type="text/powershell" id="PowerShellFunctions">
        # Global Variables

        `$global:vCenterSessionHeader=""
        `$global:Credentials
        `$global:vCenterSessionURL

        Function Connect-vCenter([string]`$PSvCenterName, [string]`$PSUserName, [string]`$PSPassword) {
            # Set parameters for REST API Session Credentials - with 256-key
            `$KeyFile = `$RunPath  + "\Presto.key"
            `$Key = Get-Content `$KeyFile
            `$SecurePassword = `$PSPassword | ConvertTo-SecureString -AsPlainText -Force
            `$SecurePassword = `$SecurePassword | ConvertFrom-SecureString -key `$Key
            `$global:Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList `$PSUserName, (`$SecurePassword | ConvertTo-SecureString -Key `$Key)

            # Prepare REST connection
            `$BaseAuthURL = "https://" + `$PSvCenterName + "/rest/com/vmware/cis/"
            `$BaseURL = "https://" + `$PSvCenterName + "/rest/vcenter/"
            `$global:vCenterSessionURL = `$BaseAuthURL + "session"
            `$Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(`$global:Credentials.UserName+":"+`$global:Credentials.GetNetworkCredential().password))}
            `$Type = "application/json"

            # Check vCenter URL availability
            Try{
                `$vCenterReq = [System.Net.WebRequest]::Create("https://" + `$PSvCenterName)
                `$vCenterRes = `$vCenterReq.GetResponse()
                if(`$vCenterRes.StatusCode -ne "OK"){
                    `$vCenterRes.Close()
                    return "Invalid vCenter"
                }
                `$vCenterRes.Close()
            }
            Catch {
                return "Unknown Error"
            }

            # Authenticating with API
            Try {
                `$vCenterSessionResponse = Invoke-RestMethod -Uri `$global:vCenterSessionURL -Headers `$Header -Method POST -ContentType `$Type
            }
            Catch {
                # Return the Error code
                return "Invalid Credentials"
            }

            # Create the vCenter Session Header with the Session ID and save it to global variable
            `$global:vCenterSessionHeader = @{'vmware-api-session-id' = `$vCenterSessionResponse.value}
            
            return `$vCenterSessionResponse.value
        }

        Function Disconnect-vCenter() {
            # Close REST API Session
            Try {
                `$CloseSession = Invoke-RestMethod -Method DELETE -Uri `$global:vCenterSessionURL -TimeoutSec 100 -Headers `$global:vCenterSessionHeader -ContentType `$Type
                return "Session Closed"
            }
            Catch {
                return "Close Session Failed"
            }
        }
    </script>
</head>
<body>
<div class="login-wrapper" id="loginpage" style="display:none">
    <form class="login">
        <section class="title">
            <h3 class="welcome">$($MsgTbl.LoginWelcome1)</h3>
            $($MsgTbl.LoginWelcome2)
            <h5 class="hint">$($MsgTbl.LoginCopyright)</h5>
            <h5 class="hint"><i>$($MsgTbl.LoginBanner)</i></h5>
        </section>
        <div class="login-group">
            <input class="username" type="text" id="login_vcenter" placeholder="$($MsgTbl.LoginvCenter)">
            <input class="username" type="text" id="login_username" placeholder="$($MsgTbl.LoginUser)">
            <input class="password" type="password" id="login_password" placeholder="$($MsgTbl.LoginPass)">
            <div class="error active" id="loginerror" style="display:none">
                $($MsgTbl.LoginError)
            </div>
            <button type="button" id="loginsubmit" class="btn btn-primary">$($MsgTbl.butNext)</button>
            <a href="https://github.com/Cloud-Concepts/ProjectPresto" class="signup" target="_new">Project Presto GitHub page</a>
        </div>
    </form>
</div>


<div class="main-container" id="mainpage" style="display:none">
    <div class="alert alert-app-level alert-warning" id="topwarning" style="display:none">
        <div class="alert-items">
            <div class="alert-item static">
                <div class="alert-icon-wrapper">
                    <clr-icon class="alert-icon" shape="exclamation-triangle"></clr-icon>
                </div>
                <div class="alert-text" id="topwarningtext">
                    &nbsp;
                </div>
            </div>
        </div>
        <button type="button" class="close" id="topwarningclose" aria-label="Close">
            <clr-icon aria-hidden="true" shape="close"></clr-icon>
        </button>
    </div>
    <div class="alert alert-app-level alert-info" id="topinfo" style="display:none">
        <div class="alert-items">
            <div class="alert-item static">
                <div class="alert-icon-wrapper">
                    <clr-icon class="alert-icon" shape="info-circle"></clr-icon>
                </div>
                <div class="alert-text" id="topinfotext">
                    &nbsp;
                </div>
            </div>
        </div>
        <button type="button" class="close" id="topinfoclose" aria-label="Close">
            <clr-icon aria-hidden="true" shape="close"></clr-icon>
        </button>
    </div>

    <header class="header-6">
        <div class="branding">
            <div class="nav-link">
                <clr-icon shape="vm-bug"></clr-icon>
                <span class="title">$($MsgTbl.AppTitle)</span>
            </div>
        </div>
        <div class="header-nav">
            <a href="javascript://" class="active nav-link nav-text">Dashboard</a>
            <a href="javascript://" class="nav-link nav-text">Datacenter</a>
            <a href="javascript://" class="nav-link nav-text">Cluster</a>
            <a href="javascript://" class="nav-link nav-text">Host</a>
            <a href="javascript://" class="nav-link nav-text">VM</a>
        </div>
        <div class="header-actions">
            <div class="dropdown bottom-left open" style="padding-right:10px">
                <button id="headermenu" type="button" class="dropdown-toggle">
                    <clr-icon shape="cog" size="24"></clr-icon>
                    <clr-icon shape="caret down"></clr-icon>
                </button>
                <div id="headersubmenu" class="dropdown-menu" style="display:none">
                    <h4 class="dropdown-header">$($MsgTbl.Settings)</h4>
                    <button type="button" class="dropdown-item">$($MsgTbl.butSwitch)</button>
                    <div class="dropdown-divider"></div>
                    <button type="button" class="dropdown-item">$($MsgTbl.butSignOut)</button>
                </div>
            </div>
        </div>
    </header>

    <div class="content-container">
        <div class="content-area">
            Main Content
        </div>
        <nav class="sidenav">
            <section class="sidenav-content">
                <a href="..." class="nav-link active">
                    Nav Element 1
                </a>
                <a href="..." class="nav-link">
                    Nav Element 2
                </a>
                <section class="nav-group collapsible">
                    <input id="tabexample1" type="checkbox">
                    <label for="tabexample1">Collapsible Nav Element</label>
                    <ul class="nav-list">
                        <li><a class="nav-link">Link 1</a></li>
                        <li><a class="nav-link">Link 2</a></li>
                    </ul>
                </section>
                <section class="nav-group">
                    <input id="tabexample2" type="checkbox">
                    <label for="tabexample2">Default Nav Element</label>
                    <ul class="nav-list">
                        <li><a class="nav-link">Link 1</a></li>
                        <li><a class="nav-link">Link 2</a></li>
                        <li><a class="nav-link active">Link 3</a></li>
                        <li><a class="nav-link">Link 4</a></li>
                        <li><a class="nav-link">Link 5</a></li>
                        <li><a class="nav-link">Link 6</a></li>
                    </ul>
                </section>
            </section>
        </nav>
    </div>
</div>
<script type="text/javascript">
    // Variables
    var activetoken = "";

    // Javascript return functions for PowerCLI functions
    returnFunction = function(result) {
      if (result != "PowerShell is busy.") {
        document.getElementById("loginpage").style.display = "block";
      }
    }

    verifyLogin = function(logintoken) {
      // Verify Initial Connection to vCenter
      if (logintoken == "Invalid vCenter") {
        // Show warning vCenter REST not available
        document.getElementById("loginerror").innerText = "$($MsgTbl.LoginNotResponding)";
        document.getElementById("loginerror").style.display = "block";
        return false;
      }
      if (logintoken == "Unknown Error") {
        // Show warning vCenter URL invalid
        document.getElementById("loginerror").innerText = "$($MsgTbl.LoginUnreachable)";
        document.getElementById("loginerror").style.display = "block";
        return false;
      }
      if (logintoken == "Invalid Credentials") {
        // Show warning vCenter Credentials error
        document.getElementById("loginerror").innerText = "$($MsgTbl.LoginInvalid)";
        document.getElementById("loginerror").style.display = "block";
        return false;
      }
      
      // Save token to javascript variable
      activetoken = logintoken;

      // Hide Login Page
      document.getElementById("loginerror").style.display = "none";
      
      // Show Main Dashboard
      document.getElementById("loginpage").style.display = "none";
      document.getElementById("mainpage").style.display = "block";

      // Close this session
      if(activetoken!=""){
          window.external.runPowerShell("Disconnect-vCenter", closeLogin);
      }
    }

    closeLogin = function(closeresult) {        
        if (closeresult == "Close Session Failed") {
            // Show alert Bar on top of window
            throwTopWarning("warning","$($MsgTbl.CloseSessionFailed)");
            return false;
        }
        activetoken = ""
        throwTopWarning("info","Alles OK");
    }

    // Loading PowerShell Functions
    var script = document.getElementById('PowerShellFunctions').innerHTML;
    window.external.runPowerShell(script, returnFunction);

    // Actions on application startup

    // Theme Changer
    `$('#alertButton').on('click', function(e) {
        if(`$('#light').prop('disabled')==true){
            `$('#dark').prop('disabled', true);
            `$('#light').prop('disabled', false);
        }else{
            `$('#light').prop('disabled', true);
            `$('#dark').prop('disabled', false);
        }
    });

    // Throw top warnings
    function throwTopWarning(type, text){
        switch(type){
            case "info":
                document.getElementById('topinfotext').innerHTML = text;
                `$('#topinfo').slideDown("slow");
                break;

            case "warning":
                document.getElementById('topwarningtext').innerHTML = text;
                `$('#topwarning').slideDown("slow");
                break;
        }
    }

    // Button clicks
    `$('#loginsubmit').on('click', function(e) {
        // Check form inputs not empty
        if(`$.trim(document.getElementById('login_vcenter').value) == ''){
            document.getElementById("loginerror").innerText = "$($MsgTbl.vCenterEmpty)";
            document.getElementById("loginerror").style.display = "block";
            return false;
        }
        if(`$.trim(document.getElementById('login_username').value) == ''){
            document.getElementById("loginerror").innerText = "$($MsgTbl.UserEmpty)";
            document.getElementById("loginerror").style.display = "block";
            return false;
        }
        if(`$.trim(document.getElementById('login_password').value) == ''){
            document.getElementById("loginerror").innerText = "$($MsgTbl.PassEmpty)";
            document.getElementById("loginerror").style.display = "block";
            return false;
        }

        // Form validation ok, try to log in
        document.getElementById("loginerror").style.display = "none";
        window.external.runPowerShell("Connect-vCenter('" + document.getElementById('login_vcenter').value + "') ('" + document.getElementById('login_username').value + "') ('" + document.getElementById('login_password').value + "')",verifyLogin);
    });

    `$('#topwarningclose').on('click', function(e) {
        `$('#topwarning').slideUp("slow");
    });

    `$('#topinfoclose').on('click', function(e) {
        `$('#topinfo').slideUp("slow");
    });

    `$('#headermenu').on('click', function(e){
        `$('#headersubmenu').toggle("slow");
    });
</script>
</body>
"@



# SIG # Begin signature block
# MIIItwYJKoZIhvcNAQcCoIIIqDCCCKQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUa8PbOjhBRDfDuGZyfZJsFjch
# tsmgggaqMIIGpjCCBI6gAwIBAgITNgAAxy77vOUmuFd2kAAHAADHLjANBgkqhkiG
# 9w0BAQUFADBAMRIwEAYKCZImiZPyLGQBGRYCYmUxEzARBgoJkiaJk/IsZAEZFgNE
# RzMxFTATBgNVBAMTDE1WRy1FV0JMLUFMVjAeFw0xODA4MDEwODE3MThaFw0xOTA4
# MDEwODE3MThaMIG8MQswCQYDVQQGEwJCRTETMBEGA1UECBMKVmxhYW5kZXJlbjEQ
# MA4GA1UEBxMHQnJ1c3NlbDEZMBcGA1UEChMQVkxBQU1TRSBPVkVSSEVJRDEpMCcG
# A1UECxMgRGVwYXJ0ZW1lbnQgTGFuZGJvdXcgZW4gVmlzc2VyaWoxHDAaBgNVBAMT
# E1dpbmRvd3MgU2VydmVyIFRlYW0xIjAgBgkqhkiG9w0BCQEWE0lUQGx2LnZsYWFu
# ZGVyZW4uYmUwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBANOiWWw/ZO+z25hS
# a8lc1oxKq1/HCi1hUgQZ6rKiZusV1kOsiNUQlg91YNmwRVRZXwHKOtZLA48FJrey
# YHVtVda2/X4YZCZOkHJ1RAHx80yWD5lPTwgYJLOcF3LZm/I77GcSDIljycdKmL4U
# WQUYz63irmf4+tYkqcytoW/AW/XlAgMBAAGjggKeMIICmjA+BgkrBgEEAYI3FQcE
# MTAvBicrBgEEAYI3FQiFyKsnhePIF4HJnTjq9hGoryuBO4TYuakKi+rH/QwCAWQC
# AQcwGwYJKwYBBAGCNxUKBA4wDDAKBggrBgEFBQcDAzALBgNVHQ8EBAMCB4AwEwYD
# VR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFA9wG7Jb9KzoBioRy4oW5ld79WzN
# MB8GA1UdIwQYMBaAFKvX7hnbiraRrGg+5LTPCkMJ6wjlMIIBGwYDVR0fBIIBEjCC
# AQ4wggEKoIIBBqCCAQKGQGh0dHA6Ly9hbHYtY2EtbXZnLWV3YmwtYWx2LmRnMy5i
# ZS9DZXJ0RW5yb2xsL01WRy1FV0JMLUFMVig3KS5jcmyGgb1sZGFwOi8vL0NOPU1W
# Ry1FV0JMLUFMVig3KSxDTj1hbHYtY2EtbXZnLWV3YmwtYWx2LENOPUNEUCxDTj1Q
# dWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0
# aW9uLERDPURHMyxEQz1iZT9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/
# b2JqZWN0Q2xhc3M9Y1JMRGlzdHJpYnV0aW9uUG9pbnQwgbkGCCsGAQUFBwEBBIGs
# MIGpMIGmBggrBgEFBQcwAoaBmWxkYXA6Ly8vQ049TVZHLUVXQkwtQUxWLENOPUFJ
# QSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25m
# aWd1cmF0aW9uLERDPURHMyxEQz1iZT9jQUNlcnRpZmljYXRlP2Jhc2U/b2JqZWN0
# Q2xhc3M9Y2VydGlmaWNhdGlvbkF1dGhvcml0eTANBgkqhkiG9w0BAQUFAAOCAgEA
# w22DGVIbtZvLm5mR3ky44ibZFPureW1p5zzr5zdZYynDAsLM0y2fFM5TzdhfvMTd
# fpeTuKPXJI5RypbEB1tDuGpKR/A3yGLZdrYYiiVIV5gUIPcePFDV5yvAmsoDEqkX
# bH1HFDwJPMjZGduidScIEktLnkeV9LK+XIzuWDxfVYBZrtbb+ygNPYldM4VUk0uj
# ab+u525U2I9f9p7fbfN2cL5G9RzJM0hx/HLK13XnlCaPcZAK5iOK+Z3ec74K2qRA
# OpFdfsydNPK7cbrmntddhrF8PMTTnrf0ZFzRaeEWb16kKfgSQ5H7QmFoTC4yWUbV
# bMBSwqbwDScir5VAPrNjgwmpjFdJJ5SpMojVpAeELUMoRY/rliiXohZpMYRioD+e
# kzRzxA28Fr91M4FFY+2WRS9glwXXIZKLnK3uih52LxPDd68m7w10FKA8vF1MOltx
# 7GVcmnRGMYWj1lfjr02Zi5skLzUsG7CTDCOBBZM2wpVgQZZUdk8tLPemrl3WOdlx
# 0Urx4ip84pIazOjwGAaJLS2FBa+ry2opWDixmDnql/Kog3wZK1R8HDYWBMSNfEz5
# H8WC3P6RQMwkYzwqWb7Q4XVrcIPz9+mfpZLUdRVD4eeWcrIKUBjtpBhYJQflOv3g
# Pxfxb0wDnIhPF7fjCVdKDl+qRhDsX+4bgalDD1qKbRwxggF3MIIBcwIBATBXMEAx
# EjAQBgoJkiaJk/IsZAEZFgJiZTETMBEGCgmSJomT8ixkARkWA0RHMzEVMBMGA1UE
# AxMMTVZHLUVXQkwtQUxWAhM2AADHLvu85Sa4V3aQAAcAAMcuMAkGBSsOAwIaBQCg
# eDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEE
# AYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJ
# BDEWBBQx0rFYiJ0fsLpma1IUt+xrCTJ+HDANBgkqhkiG9w0BAQEFAASBgK+mlKf7
# P3VyEpzeuIMQdnU7cDQo2LsiYUZUcMoXWKG01Epsw63lt0XScaApWKc6RMQIEwdT
# qtjynz1SanwopZDk335o9yT9vcG+ytSZ/6RYorkRWU+r+XaIlho17U3Qk9BG7Gph
# 15HBqvecX7uzlAkSJmTs3D0NSYUIaoDakzv/
# SIG # End signature block
