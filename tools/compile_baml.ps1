param(
    [Parameter(Mandatory=$true)]
    [string]$InputXaml,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputBaml = "",
    
    [switch]$Quiet
)

<#
.SYNOPSIS
    Compiles a WPF XAML file to BAML (Binary Application Markup Language).

.DESCRIPTION
    Uses MSBuild to compile a XAML file into its pre-tokenized binary BAML form.
    BAML loads ~30x faster than text XAML because WPF skips XML parsing entirely.
    
    Writes a status log to <OutputBaml>.log with detailed diagnostics on success or failure.

.PARAMETER InputXaml
    Path to the input XAML file to compile.

.PARAMETER OutputBaml
    Path for the output BAML file. Defaults to <InputName>.baml in the same directory.

.PARAMETER Quiet
    Suppress console output (log file is always written).

.EXAMPLE
    .\compile_baml.ps1 -InputXaml "my_ui.xaml"
    .\compile_baml.ps1 -InputXaml "my_ui.xaml" -OutputBaml "dist\my_ui.baml"
#>

$ErrorActionPreference = "Stop"

# ============================================================================
# Helpers
# ============================================================================

function Write-Log {
    param([string]$Message)
    $script:logLines += $Message
    if (-not $Quiet) { Write-Host $Message }
}

function Write-LogError {
    param([string]$Message)
    $script:logLines += "ERROR: $Message"
    if (-not $Quiet) { Write-Host $Message -ForegroundColor Red }
}

function Flush-Log {
    if ($script:logPath -and $script:logLines.Count -gt 0) {
        [System.IO.File]::WriteAllText($script:logPath, ($script:logLines -join "`n"), [System.Text.Encoding]::UTF8)
    }
}

$script:logLines = @()
$script:logPath = ""

# ============================================================================
# Validate input
# ============================================================================

if (-not (Test-Path $InputXaml)) {
    $script:logLines += "ERROR: Input file not found: $InputXaml"
    Write-Error "Input file not found: $InputXaml"
    exit 1
}

$InputXaml = Resolve-Path $InputXaml
$inputName = [System.IO.Path]::GetFileNameWithoutExtension($InputXaml)

if ($OutputBaml -eq "") {
    $OutputBaml = Join-Path (Split-Path $InputXaml) "$inputName.baml"
}

# Log file lives next to the output BAML - always persisted for AHK to read
$script:logPath = "$OutputBaml.log"

# ============================================================================
# Find MSBuild
# ============================================================================

$msbuildPaths = @(
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin\MSBuild.exe",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\*\MSBuild\Current\Bin\MSBuild.exe",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\*\MSBuild\Current\Bin\MSBuild.exe"
)

$msbuild = $null
foreach ($p in $msbuildPaths) {
    $found = Get-Item $p -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $msbuild = $found.FullName; break }
}

if (-not $msbuild) {
    Write-LogError "MSBuild not found."
    Write-LogError "Install Visual Studio Build Tools 2022 from:"
    Write-LogError "https://visualstudio.microsoft.com/visual-cpp-build-tools/"
    Write-LogError "Ensure the '.NET desktop build tools' workload is selected."
    Flush-Log
    exit 1
}

Write-Log "MSBuild: $msbuild"

# ============================================================================
# Create temp build directory
# ============================================================================

$buildDir = Join-Path $env:TEMP "AhkWpf\baml_build_$(Get-Random)"
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

try {
    # ========================================================================
    # Read and transform XAML
    # ========================================================================
    
    $xamlContent = Get-Content -Path $InputXaml -Raw -Encoding UTF8
    Write-Log "Input: $InputXaml ($((Get-Item $InputXaml).Length) bytes)"

    if ($xamlContent -match "^\s*<Window[\s>]") {
        Write-Log "Type: Window XAML - applying BAML-safe transforms..."
        
        # Remove x:Class (we load dynamically, no code-behind)
        $xamlContent = $xamlContent -replace 'x:Class="[^"]*"\s*', ''

        # Strip WindowChrome block - re-applied by C# engine at runtime
        $xamlContent = $xamlContent -replace '(?s)<WindowChrome\.WindowChrome>.*?</WindowChrome\.WindowChrome>', ''
        $xamlContent = $xamlContent -replace '\s*WindowChrome\.IsHitTestVisibleInChrome="[^"]*"', ''

        # Strip AHK source line tracing comments
        $xamlContent = $xamlContent -replace '<!--\s*\[ahk:[^\]]*\]\s*-->', ''

        # Remove empty Window.Resources blocks
        $xamlContent = $xamlContent -replace '<Window\.Resources>\s*</Window\.Resources>', ''
    }
    elseif ($xamlContent -match "^\s*<Window\.Resources>") {
        Write-Log "Type: ResourceDictionary (component styles)"
        $xamlContent = $xamlContent -replace '<Window\.Resources>', '<ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" xmlns:sys="clr-namespace:System;assembly=mscorlib" xmlns:primitives="clr-namespace:System.Windows.Controls.Primitives;assembly=PresentationFramework">'
        $xamlContent = $xamlContent -replace '</Window\.Resources>', '</ResourceDictionary>'
    }
    else {
        Write-Log "Type: Generic XAML"
    }

    # Write transformed XAML to build directory
    $buildXamlPath = Join-Path $buildDir "$inputName.xaml"
    [System.IO.File]::WriteAllText($buildXamlPath, $xamlContent, [System.Text.Encoding]::UTF8)

    # ========================================================================
    # Locate .NET Framework runtime assemblies
    # ========================================================================

    $fwRuntime = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
    $wpfDir = "$fwRuntime\WPF"
    if (-not (Test-Path $wpfDir)) {
        $fwRuntime = "C:\Windows\Microsoft.NET\Framework\v4.0.30319"
        $wpfDir = "$fwRuntime\WPF"
    }

    if (-not (Test-Path $wpfDir)) {
        Write-LogError ".NET Framework WPF runtime not found at:"
        Write-LogError "  $wpfDir"
        Write-LogError "Ensure .NET Framework 4.x is installed."
        Flush-Log
        exit 1
    }

    # ========================================================================
    # Generate .csproj
    # ========================================================================

    $csproj = @"
<Project DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <Configuration>Release</Configuration>
    <Platform>AnyCPU</Platform>
    <OutputType>Library</OutputType>
    <RootNamespace>AhkXamlBaml</RootNamespace>
    <AssemblyName>$inputName</AssemblyName>
    <TargetFrameworkVersion>v4.0</TargetFrameworkVersion>
    <OutputPath>bin\Release\</OutputPath>
    <IntermediateOutputPath>obj\Release\</IntermediateOutputPath>
    <FrameworkPathOverride>$fwRuntime</FrameworkPathOverride>
    <NoStdLib>false</NoStdLib>
  </PropertyGroup>
  <ItemGroup>
    <Reference Include="PresentationCore">
      <HintPath>$wpfDir\PresentationCore.dll</HintPath>
    </Reference>
    <Reference Include="PresentationFramework">
      <HintPath>$wpfDir\PresentationFramework.dll</HintPath>
    </Reference>
    <Reference Include="WindowsBase">
      <HintPath>$wpfDir\WindowsBase.dll</HintPath>
    </Reference>
    <Reference Include="System.Xaml">
      <HintPath>$fwRuntime\System.Xaml.dll</HintPath>
    </Reference>
    <Reference Include="System">
      <HintPath>$fwRuntime\System.dll</HintPath>
    </Reference>
  </ItemGroup>
  <ItemGroup>
    <Page Include="$inputName.xaml">
      <Generator>MSBuild:Compile</Generator>
      <SubType>Designer</SubType>
    </Page>
  </ItemGroup>
  <Import Project="`$(MSBuildToolsPath)\Microsoft.CSharp.targets" />
</Project>
"@

    $csprojPath = Join-Path $buildDir "$inputName.csproj"
    [System.IO.File]::WriteAllText($csprojPath, $csproj, [System.Text.Encoding]::UTF8)

    # ========================================================================
    # Run MSBuild
    # ========================================================================

    $msbuildArgsStr = "/t:Build /p:Configuration=Release /v:normal `"$csprojPath`""
    
    Write-Log "Compiling XAML to BAML..."
    
    $stdoutPath = Join-Path $buildDir "stdout.txt"
    $stderrPath = Join-Path $buildDir "stderr.txt"
    
    cmd.exe /c "`"$msbuild`" $msbuildArgsStr > `"$stdoutPath`" 2> `"$stderrPath`""
    $exitCode = $LASTEXITCODE
    
    $msbuildStdout = Get-Content $stdoutPath -Raw -ErrorAction SilentlyContinue
    $msbuildStderr = Get-Content $stderrPath -Raw -ErrorAction SilentlyContinue

    if ($exitCode -ne 0) {
        Write-LogError "MSBuild failed (exit code $($exitCode))"
        Write-Log ""
        Write-Log "=== MSBuild Output ==="
        
        # Parse and display the error details
        $allOutput = "$msbuildStdout`n$msbuildStderr"
        $errorLines = ($allOutput -split "`n") | Where-Object { $_ -match "error\s+(MC|CS)\d+" }
        $warningLines = ($allOutput -split "`n") | Where-Object { $_ -match "warning\s+(MC|CS)\d+" }
        
        if ($errorLines) {
            Write-Log ""
            Write-Log "--- ERRORS ---"
            foreach ($e in $errorLines) {
                $clean = $e.Trim()
                # Extract file:line:col and error message
                if ($clean -match '\.xaml\((\d+),(\d+)\):\s*error\s+(\w+):\s*(.+?)(?:\s*\[|$)') {
                    $errLine = $Matches[1]
                    $errCol = $Matches[2]
                    $errCode = $Matches[3]
                    $errMsg = $Matches[4]
                    Write-Log "  Line $errLine, Col $errCol [$errCode]:"
                    Write-Log "    $errMsg"
                    
                    # Show XAML snippet around the error
                    $xamlLines = $xamlContent -split "`n"
                    $lineIdx = [int]$errLine - 1
                    $startIdx = [Math]::Max(0, $lineIdx - 3)
                    $endIdx = [Math]::Min($xamlLines.Length - 1, $lineIdx + 3)
                    Write-Log ""
                    Write-Log "  XAML Snippet:"
                    for ($i = $startIdx; $i -le $endIdx; $i++) {
                        $prefix = if ($i -eq $lineIdx) { "  >> " } else { "     " }
                        $lineNum = ($i + 1).ToString().PadLeft(5)
                        Write-Log "$prefix$lineNum| $($xamlLines[$i].TrimEnd())"
                    }
                    Write-Log ""
                } else {
                    Write-Log "  $clean"
                }
            }
        }
        
        if ($warningLines) {
            Write-Log ""
            Write-Log "--- WARNINGS ---"
            foreach ($w in $warningLines) { Write-Log "  $($w.Trim())" }
        }
        
        if (-not $errorLines -and -not $warningLines) {
            # No parsed errors - dump raw output
            Write-Log $allOutput
        }
        
        Write-Log ""
        Write-Log "Build directory (preserved for inspection): $buildDir"
        
        Flush-Log
        # Don't clean up on failure - preserve build dir for manual inspection
        exit 1
    }

    # ========================================================================
    # Extract BAML from build output
    # ========================================================================

    $bamlFile = Get-ChildItem -Path $buildDir -Recurse -Filter "$inputName.baml" | Select-Object -First 1
    
    if (-not $bamlFile) {
        Write-LogError "BAML file not found in build output."
        Write-LogError "MSBuild reported success but no .baml was generated."
        Write-Log ""
        Write-Log "=== MSBuild Output ==="
        Write-Log $msbuildStdout
        Write-Log ""
        Write-Log "Build directory (preserved): $buildDir"
        Flush-Log
        exit 1
    }

    # ========================================================================
    # Copy to output location
    # ========================================================================

    Copy-Item -Path $bamlFile.FullName -Destination $OutputBaml -Force

    $inputSize = (Get-Item $InputXaml).Length
    $outputSize = (Get-Item $OutputBaml).Length
    $reduction = [math]::Round((1 - $outputSize / $inputSize) * 100, 1)

    Write-Log ""
    Write-Log "BAML compiled successfully!"
    Write-Log "  Input:  $InputXaml ($inputSize bytes)"
    Write-Log "  Output: $OutputBaml ($outputSize bytes, ${reduction}% smaller)"
}
catch {
    Write-LogError "Unexpected error: $_"
    Write-LogError $_.ScriptStackTrace
    Flush-Log
    exit 1
}
finally {
    # Always flush the log
    Flush-Log
    # Only clean up build directory on SUCCESS
    if ($null -ne $exitCode -and $exitCode -eq 0) {
        Remove-Item -Path $buildDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
