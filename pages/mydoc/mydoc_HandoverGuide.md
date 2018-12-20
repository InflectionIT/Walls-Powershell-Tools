---
title: Generate Handover Guide
last_updated: December 20, 2018
keywords: handover, documentation, guide
sidebar: mydoc_sidebar
permalink: mydoc_HandoverGuide.html
folder: mydoc
toc: false
---

## Overview

This command gathers multiple data points from the Walls installation and sends that data to InflectionIT to generate a Handover Guide.

## Data Gathered

The following information gathered during this process:
* Application Version
* SQL Server version
* SQL Server IP address
* Extension Servers
* Extension Server user account
* Active Modules
* Active Extensions
* Enabled users
* Enabled libraries
* Job schedules
* Configuraton settings (no credentials are captured)
* IIS App Pools
* IIS Sites

## Running the script

When running the script, you will be prompted for a variety of information needed to complete the Handover Guide. 

* **Email address**: Enter the email address of the user that should receive the completed Handover Guide (usually you)
* **Client Name**: Enter the full name of the client
* **Integrate Version**: Enter the version of Integrate installed
* **User Source application**: Enter the name of the application where the users are being synced from
* **User Source server**: Enter the hostname of the server where the users are being synced from
* **User Source DB**: Enter the database name where the users are being synced from
* **Client/Matter Source application**: Enter the name of the application where the clients & matters are being synced from
* **Client/Matter Source server**: Enter the hostname of the server where the clients & matters are being synced from
* **Client/Matter Source DB**: Enter the database name where the clients & matters are being synced from
* **Customizations**: Enter a description of any customizations that have been implemented

## Output 

The information gathered is sent to InflectionIT via WebMerge (https://www.webmerge.me/) for Handover Guide creation.

Additionally, all of the data captured is stored in JSON format in the "body.txt" file saved in the script folder.

{% include image.html file="IISPrereqs.png" alt="Command output" caption="Results of command execution" %}
