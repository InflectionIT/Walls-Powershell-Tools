---
title: Troubleshooting
keywords: questions, troubleshooting, issue, warning, error
last_updated: January 2nd, 2019
sidebar: mydoc_sidebar
permalink: mydoc_troubleshooting.html
folder: mydoc
topnav: topnav
toc: true
---

## Troubleshooting

This page covers some issues that you may experience when running the PowerShell scripts.

### Not digitally signed / Unauthorized Access

{% include image.html file="PowerShell-NotDigitallySigned.png" alt="UnauthorizedAccess error" caption="Not digitally signed error" %}

To bypass this error, run the scripts using the following command from the folder where the scripts are located:

<pre>
PowerShell.exe -ExecutionPolicy Bypass -File .\walls.ps1
</pre>

{% include note.html content="The Bypass command only affects running the specified script. It does not change the settings for any other scripts or alter your PowerShell configuraiton" %}

### Script Warning

You may see the following message when attempting to run the script:

<pre>
Security warning
Run only scripts that you trust. While scripts from the internet can be useful, this script can potentially harm your computer. If you trust this script, use the Unblock-File cmdlet to allow the script to run without this warning message. Do you want to run C:\foo.ps1?
[D] Do not run [R] Run once [S] Suspend [?] Help (default is "D"):
</pre>

There are several ways to resolve this problem:

* Press **R** to run the script (You will need to do this every time you run the script)
* Run the following command instead to bypass the issue
<pre>
PowerShell.exe -ExecutionPolicy Bypass -File .\walls.ps1
</pre>
* Unblock the file in Explorer. In Windows Explorer, right-click the **walls.ps1** file, select **Properties**, and click the **Unblock** button. 

For additional information, please see this [blog post](https://kencenerelli.wordpress.com/2017/07/17/unblock-downloaded-powershell-scripts/){:target="_blank"}

