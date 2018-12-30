---
title: Generate Auto Escalation
last_updated: December 20, 2018
keywords: auto-escalation, escalation, issue, ticket, problem
sidebar: mydoc_sidebar
permalink: mydoc_autoescalation.html
folder: mydoc
toc: false
---

## Overview

This command gathers a variety of data (including logs) from the Walls installation and sends that data to Inflection IT to help resolve a problem or issue. 

## Data Gathered

The following information gathered during this process:
* Configuraton settings (no credentials are captured)
* Error Log information
* Extension Service jobs
* IIS Log files 
* Extension Service Log files
* Screenshot (*optional*)

## Running the script

When running the script, you will be prompted for some information needed to complete the Handover Guide. 

* **Email address**: Enter the email address of the user that should receive the escalation (usually you)
* **Description**: Enter a short description of the question or issue
* **Screenshot**: Indicate if you would like to include a screenshot. If you have multiple monitors, the screenshot will include captures from both monitors

{% include image.html file="AutoEscalation.png" alt="Command output" caption="Auto escalation questions" %}

## Output 

The information gathered is sent via email for escalation management. The email includes attachements of the necessary data, including a zip file of the logs, the configuration settings in CSV format, the error logs in CSV format, and the optional screenshot.

{% include image.html file="AutoEscalationDone.png" alt="Command output" caption="Results of command execution" %}
