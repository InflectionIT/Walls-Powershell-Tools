---
title: Walls PowerShell Tools Installation
last_updated: December 20, 2018
keywords: install, download, run, configure
summary: "Covers the steps to download, configure, and run the PowerShell tools"
sidebar: mydoc_sidebar
permalink: mydoc_overview.html
folder: mydoc
---

## Preparing your Powershell Environment

The Walls PowerShell Tools require PowerShell v5 be installed on your machine. Follow these steps to determine which version you have installed:
1. Open a command prompt
2. Type "powershell" and press Enter
3. Type "Get-Host" and press Enter
4. Look for the "Version" value

{% include image.html file="GetPowerShellVersion.png" alt="PowerShell version" caption="Determining the PowerShell version" %}

## Installing PowerShell

If you need to install PowerShell or update your version, click 
[here](https://www.microsoft.com/en-us/download/details.aspx?id=54616){:target="_blank"} to download PowerShell. Follow the prompts to complete installation.

## Downloading Walls PowerShell Tools

The Walls PowerShell Tools package is stored on GitHub as an open-source project. Click [here](https://github.com/InflectionIT/Walls-Powershell-Tools){:target="_blank"} to access the repository.

In GitHub, click the **Clone or download** button, then click **Download ZIP**
{% include image.html file="GitHub.jpg" alt="Downloading files from GitHub" caption="Downloading the files from GitHub" %}

Download and unzip the files to a folder of your choosing.

## Configuring database connection

Before you can run the scripts, you need to configure the database connection information.

Using a text editor of you choice, open the **config.psd1** file and modify the connection information. If you would like to use integrated security, keep **UseSSP = 'true'** as is. If you'd like to specify a username/password, change the line to **UseSSP = 'false'** and set the username and password.  

{% include image.html file="ConfigFile.jpg" alt="Config file" caption="Configuring config.psd1 file" %}

## Running Walls PowerShell Tools

There are two ways to run the Walls PowerShell Tools - via command prompt or PowerShell ISE (Integrated Scripting Environment). 

### Running via Command Prompt
* Open an command prompt with 'run as administrator' privileges 
* Navigate to Walls PowerShell Tools folder where the scripts are located
* Enter the following command ***powershell.exe .\walls.ps1*** and press \<Enter>
* Follow menu prompts to use tools
{% include image.html file="ToolsMainMenu.jpg" alt="Main menu" caption="Running the script" %}
* When finished using the tools, press ***q*** to quit

### Running via PowerShell ISE
* In Windows Explorer, navigate to Walls PowerShell Tools folder where the scripts are located
* Right-click ***walls.ps1*** file, navigate to **Open with** submenu, click on **Windows PowerShell ISE**
* In the lower panel command prompt, change directory to the folder where the scripts are located. For example, if the scripts are located in *C:\Users\Administrator\Documents\WallsPowerShellTools*, type **cd "C:\Users\Administrator\Documents\WallsPowerShellTools"** and press \<Enter>. This step is necessary to ensure that information captured during Handover Guide generation and Auto-Escalation is stored in the correct folder.
{% include image.html file="PowerShellISE.png" alt="PowerShell ISE" caption="Changing directory in PowerShell ISE" %}
* Press **F5** to run script
* Follow menu prompts to use tools
{% include image.html file="PowerShellISERunning.png" alt="PowerShell ISE" caption="Running script in PowerShell ISE" %}
* When finished using the tools, press ***q*** to quit