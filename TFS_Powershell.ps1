Param(
      [String]$TFSBox =$(Read-Host -Prompt "What's the TFS URI?")
      )
Function Import-TFSAssembly {
        Add-Type -AssemblyName "Microsoft.TeamFoundation.Client, Version= 11.0.0.0, Culture = neutral, PublicKeyToken=b03f5f7f11d50a3a",
        "Micorosft.TeamFouncation.Common, Version = 11.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a",
        "Microsoft.TeamFoundation, Version= 11.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a"
        }

$TFS = [Microsoft.TeamFoundation.Client.TfsTeamprojectCollectionFactory]::GetTeamprojectCollection($TFSBox)
$TFS.EnsureAuthenticated()
if(!$TFS.HasAuthenticated)
    {
  Write-Host "Authentication Failed, Can't Proceed !"
  exit
    }
else
    {
 Write-Host "Authenticated Successfully !"   
    }