<#
The sample scripts are not supported under any Microsoft standard support 
program or service. The sample scripts are provided AS IS without warranty  
of any kind. Microsoft further disclaims all implied warranties including,  
without limitation, any implied warranties of merchantability or of fitness for 
a particular purpose. The entire risk arising out of the use or performance of  
the sample scripts and documentation remains with you. In no event shall 
Microsoft, its authors, or anyone else involved in the creation, production, or 
delivery of the scripts be liable for any damages whatsoever (including, 
without limitation, damages for loss of business profits, business interruption, 
loss of business information, or other pecuniary loss) arising out of the use 
of or inability to use the sample scripts or documentation, even if Microsoft 
has been advised of the possibility of such damages.
#> 

#requires -Version 2

Function Test-OSCWebService()
{ 
<#
	.SYNOPSIS
	Function Test-OSCWebService is an advanced function which can verify if the specified web service is running.
	.DESCRIPTION
	Function Test-OSCWebService is an advanced function which can verify if the specified web service is running.
	.PARAMETER SiteURL
	The url of the specified website.
	.PARAMETER Credential
	Gets a credential object based on a user name and password.
	.EXAMPLE
	Test-OSCWebService -SiteURL http://sp-server:13858/
	
	Verify if the web service is running.

	.EXAMPLE
	Test-OSCWebService -SiteURL http://sp-server:32938/sites/test2/default.aspx -Credential
	
	Verify if the web service is running with specified Credential.
	
#>
  	[CmdletBinding(SupportsShouldProcess=$true)]
	Param
	(
		#Define parameters
		[Parameter(Mandatory=$true,Position=0)]
		[String]$SiteURL,
		[Parameter(Mandatory=$false,Position=1)]
		[Switch]$Credential
	)
	If($Credential)
	{
		#Get the specified Credential 
		$Credentials = Get-Credential 
	}
	Else
	{	
		#If the the Credential not given,set as Default Credential
		$Credentials = [System.Net.CredentialCache]::DefaultCredentials
	}
	#Create Net.HttpWebRequest 
	$request = [Net.HttpWebRequest]::Create($SiteURL) 
	$request.Credentials = $Credentials 
	#Try to get the response from the specified site.If some errors occur, it means the service does not run or you don't have the Credential
	try
	{	
		#Get the response from the requst
		$response = [Net.HttpWebResponse]$request.GetResponse()
		Write-Host "The service is running."
		$request.Abort()
	}	
	Catch 
	{
		Write-Warning "The service of site does not run or maybe you don't have the Credential"
	}

}
