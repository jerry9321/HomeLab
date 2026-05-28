<#
register-providers.ps1
Registers a list of Azure resource providers and polls until they are 'Registered'.
Run as a user or SP that has permission to register providers (Owner or User Access Administrator + ability to register providers).
#>
param(
  [int]$TimeoutMinutes = 10,
  [int]$PollIntervalSeconds = 10
)

# Default provider list (from user). Edit as needed.
$providers = @(
  'Microsoft.AppConfiguration','Microsoft.EventHub','microsoft.insights','Microsoft.DataFactory','Microsoft.StreamAnalytics','Microsoft.DataProtection',
  'Microsoft.Cdn','Microsoft.MachineLearningServices','Microsoft.Maintenance','Microsoft.CognitiveServices','Microsoft.SignalRService','Microsoft.Maps',
  'Microsoft.RecoveryServices','Microsoft.ManagedServices','Microsoft.NotificationHubs','Microsoft.DBforMariaDB','Microsoft.AppPlatform','Microsoft.Automation',
  'Microsoft.OperationsManagement','Microsoft.Databricks','Microsoft.Cache','Microsoft.Search','Microsoft.EventGrid','Microsoft.DevTestLab','Microsoft.DBforMySQL',
  'Microsoft.SecurityInsights','Microsoft.ServiceFabric','Microsoft.PowerBIDedicated','Microsoft.Kusto','Microsoft.PolicyInsights','Microsoft.ContainerInstance',
  'Microsoft.OperationalInsights','Microsoft.ContainerService','Microsoft.ServiceBus','Microsoft.Sql','Microsoft.Network','Microsoft.Security','Microsoft.CustomProviders',
  'Microsoft.ManagedIdentity','Microsoft.Logic','Microsoft.Management','Microsoft.Devices','Microsoft.AVS','Microsoft.HealthcareApis','Microsoft.Compute','Microsoft.Web',
  'Microsoft.DataLakeStore','Microsoft.DataLakeAnalytics','Microsoft.DocumentDB','Microsoft.DBforPostgreSQL','Microsoft.HDInsight','Microsoft.DesktopVirtualization',
  'Microsoft.Relay','Microsoft.ApiManagement','Microsoft.BotService','Microsoft.DataMigration','Microsoft.ContainerRegistry','Microsoft.GuestConfiguration'
)

# Ensure az available
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  Write-Error "Azure CLI 'az' not found in PATH. Install Azure CLI and run 'az login' before executing this script."
  exit 2
}

# Ensure login
try {
  $sub = az account show --query id -o tsv 2>$null
} catch {
  Write-Error "Failed to read subscription. Run 'az login' first."
  exit 2
}

Write-Host "Using subscription: $sub"

# Attempt to register each provider
foreach ($p in $providers) {
  Write-Host "Registering provider: $p"
  $reg = az provider register --namespace $p --subscription $sub 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "Register request for $p returned non-zero exit. Output: $reg`
If you see AuthorizationFailed (403), the identity you're using needs permission to register providers (typically Owner at subscription scope)."
  } else {
    Write-Host "Register request submitted for $p"
  }
}

# Poll loop
$deadline = (Get-Date).AddMinutes($TimeoutMinutes)
$notReady = $providers.Clone()

while ((Get-Date) -lt $deadline -and $notReady.Count -gt 0) {
  Write-Host "Checking provider registration status... Remaining: $($notReady.Count)"
  foreach ($p in $notReady.ToArray()) {
    $state = az provider show --namespace $p --subscription $sub --query registrationState -o tsv 2>$null
    if ($?) {
      if ($state -eq 'Registered') {
        Write-Host "  $p -> Registered"
        $notReady = $notReady | Where-Object { $_ -ne $p }
      } else {
        Write-Host "  $p -> $state"
      }
    } else {
      Write-Warning "  Could not query $p (permission or transient error)."
    }
  }
  if ($notReady.Count -gt 0) {
    Start-Sleep -Seconds $PollIntervalSeconds
  }
}

if ($notReady.Count -eq 0) {
  Write-Host "All providers registered."
  exit 0
} else {
  Write-Warning "Timed out waiting for: $($notReady -join ', ')"
  Write-Warning "If you received AuthorizationFailed errors earlier, ensure the account/SP has Owner role on the subscription or ask your subscription admin to register these providers."
  exit 3
}
