Describe 'PsAbcUpdate Tests' {

    Import-Module "PsAbcUpdate" -ea 0

    Context 'Test Module import' {

        It 'Module is imported' {
            $Valid = Get-Module -Name 'PsAbcUpdate'
            $Valid.Name | Should -Be 'PsAbcUpdate'
        }

    }

    Context 'Test PsAbcUpdate Functions' {

        It 'Valid Value (sample test)' {
            $Valid = 'Valid'
            $Valid | Should -Be $Valid
        }

    }

}


