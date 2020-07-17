# Introduction 

PowerShell wrapper for the ABC-Update CLI tool.

# Getting Started
1.	Load module into session (Quick and Dirty)

        ```
        Invoke-Expression (( new-object Net.WebClient ).DownloadString( 'https://raw.githubusercontent.com/RFAInc/PsAbcUpdate/master/PsAbcUpdate.raw.ps1' ));
        ```

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

2.  Create a new Package folder as .\Package\v#.#.#.#\

3.  Copy the PSD1 files in as-is.

    Update the version number and copyright date if required.

	Update the Exported Function Name array with the basenames of the files under the .\ folder only.

4.  Create a new, blank PSM1 file in here. 

    Populate it with all of the PS1 files' content from the .\ and .\Private folders.

5.  Create a NUSPEC file and update the version and change log.

6.  Build the NuGet package.

7.  Push to private repo.



# Contribute

1.  Add your changes to a new feature branch.

2.  Add Pester tests for your changes.

3.  Push your branch to origin.

4.  Submit a PR with description of changes.

5.  Follow up in 2 business days.




