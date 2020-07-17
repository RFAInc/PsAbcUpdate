# Introduction 

PowerShell wrapper for the ABC-Update CLI tool.

# Getting Started
1.	Load module into session (Quick and Dirty)

        Invoke-Expression (( new-object Net.WebClient ).DownloadString( 'https://raw.githubusercontent.com/RFAInc/PsAbcUpdate/master/PsAbcUpdate.raw.ps1' ));

<br>

2.	Dependencies

        This module has the following PowerShell Dependancies:
        None

        This module has the following Software Dependancies:
        This module has no dependancies other than a supported Windows OS.

<br>

3.	Version History

	    - v0.1.0.1 - Initial Commit.

<br>



# Build, Test, and Publish

0.  Pester test. 

1.  Get next version number `v#.#.#.#` and a comment `[string]` for the change log.

2.  Add any new function names to the array under .raw.ps1 file.



# Contribute

1.  Add your changes to a new feature branch.

2.  Add Pester tests for your changes.

3.  Push your branch to origin.

4.  Submit a PR with description of changes.

5.  Follow up in 2 business days.




