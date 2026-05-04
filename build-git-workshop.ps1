#!/usr/bin/env pwsh
#Requires -Version 7.0

$ErrorActionPreference = "Stop"

# --- Fake commit timestamps ---
$COMMIT_START_DATE = "2024-01-15 09:00:00"
$COMMIT_INTERVAL_SECONDS = 300   # seconds between commits

$_commit_ts = [DateTimeOffset]::new((Get-Date $COMMIT_START_DATE), [TimeSpan]::Zero).ToUnixTimeSeconds()

# Hashtable to map commit names to their SHA hashes and timestamps
$script:commitHashes = @{}
$script:commitTimes = @{}

function Submit-Commit-With-Date {
    param(
        [string]$Message,
        [int]$Interval = $COMMIT_INTERVAL_SECONDS,
        [string]$Name = ""
    )
    $script:_commit_ts = $_commit_ts + $Interval
    $ts = (Get-Date -UnixTimeSeconds $_commit_ts).ToString("yyyy-MM-ddTHH:mm:ss")
    $env:GIT_AUTHOR_DATE = $ts
    $env:GIT_COMMITTER_DATE = $ts
    git commit -m $Message
    $sha = git rev-parse HEAD
    if ($Name) {
        $script:commitHashes[$Name] = $sha
        $script:commitTimes[$Name] = (Get-Date -UnixTimeSeconds $_commit_ts).ToString("HH:mm")
    }
}

$OUTPUT_DIR = "output"
$REPO_NAME = "repo"
$SITE_NAME = "site"

# Store initial location for navigation
$script:initialLocation = Get-Location

# Clean up and create repo directory
$repoDir = Join-Path $OUTPUT_DIR $REPO_NAME
$siteDir = Join-Path $OUTPUT_DIR $SITE_NAME
if (Test-Path $repoDir) {
    Remove-Item -Recurse -Force $repoDir
}
if (Test-Path $siteDir) {
    Remove-Item -Recurse -Force $siteDir
}

# Create output directories
New-Item -ItemType Directory -Name $repoDir | Out-Null
New-Item -ItemType Directory -Name $siteDir | Out-Null

Set-Location $repoDir

git init --initial-branch=main

git config user.name "Other Developer 1"
git config user.email "developer1@example.com"

# Create a few basic commits on main

@"
# Demo

A .NET solution repository containing demonstration console applications for learning and experimentation.

## Projects

- * * TaskApp** — A console-based task list application with filtering capabilities, built to demonstrate various C# features.

## Getting Started

1. Open the solution in Visual Studio, VS Code, or your preferred .NET IDE.
2. Build the solution: \`dottnet build\`
3. Navigate to a project directory and run: \`dotnet run\`

"@ | Out-File -FilePath README.md

git add README.md
Submit-Commit-With-Date "Initialize repo"

# Create the solution
dotnet new solution --format slnx --name Demo
git add *.slnx
Submit-Commit-With-Date "Add Demo solution" -Name "prefork"

dotnet new console --name OtherApp
dotnet solution Demo.slnx add OtherApp/OtherApp.csproj

Set-Location OtherApp

# Add a vulnerable package

git config user.name "Other Developer 2"
git config user.email "developer2@example.com"

dotnet package add OpenTelemetry.Api -v 1.15.2

@"
var loggerType = typeof(OpenTelemetry.BaseProvider);
var assemblyName = loggerType.Assembly.GetName();
Console.WriteLine($"OpenTelemetry: {assemblyName}");
"@ | Set-Content -Path Program.cs
Set-Location ..

git add OtherApp/OtherApp.csproj OtherApp/Program.cs

Submit-Commit-With-Date "Add OpenTelemetry consumer"

git tag forkpoint

git config user.name "Other Developer 3"
git config user.email "developer3@example.com"

# Fix the typo in README.md before committing
(Get-Content -Path README.md -Raw) -replace 'dottnet', 'dotnet' | Set-Content -Path README.md
git add README.md

Submit-Commit-With-Date "Fix README typo" -Interval 600

# Create a PR branch from an earlier point and do some PR work on it to create the TaskApp
git checkout -b pr/new-work forkpoint
git tag -d forkpoint

git config user.name "You"
git config user.email "you@example.com"

dotnet new console --name TaskApp
dotnet solution Demo.slnx add TaskApp/TaskApp.csproj

git add *.slnx TaskApp/Program.cs TaskApp/*.csproj

Submit-Commit-With-Date "Create TaskApp project" -Interval "-60" -Name "postfork"

Set-Location TaskApp

# ---- Base functionality ----

@"
using System;
using System.Collections.Generic;
using System.Linq;

var tasks = new List<string>
{
    "Buy milk",
    "Write report",
    "Call Alice",
    "Fix bug"
};

Console.WriteLine("Tasks:");
foreach (var task in tasks)
{
    Console.WriteLine(task);
}
"@ | Set-Content -Path Program.cs

dotnet build
git add .
Submit-Commit-With-Date "Add basic task list" -60 -Name "first_bad_bin_obj"

# ---- Start messy history ----

# 1 - Add filtering (rough)
@"
using System;
using System.Collections.Generic;
using System.Linq;

var tasks = new List<string>
{
    "Buy milk",
    "Write report",
    "Call Alice",
    "Fix bug"
};

Console.WriteLine("Enter filter:");
var filter = Console.ReadLine();

var filtered = tasks.Where(t => t.Contains(filter)).ToList();

Console.WriteLine("Tasks:");
foreach (var task in filtered)
{
    Console.WriteLine(task);
}
"@ | Set-Content -Path Program.cs

git add .
Submit-Commit-With-Date "Add task filtering"

# 2 - Debug logging added
$content = Get-Content -Path Program.cs -Raw
$content = $content -replace "using System.Linq;", "using System.Linq;`r`n`r`nConsole.WriteLine(""DEBUG: starting app"");"
[System.IO.File]::WriteAllText((Resolve-Path Program.cs), $content)

git add .
Submit-Commit-With-Date "DEBUG: add startup log" -Name debug1

# 3 - Case-insensitive fix
$content = Get-Content -Path Program.cs -Raw
$content = $content -replace 'Contains\(filter\)', 'ToLower().Contains(filter.ToLower())'
[System.IO.File]::WriteAllText((Resolve-Path Program.cs), $content)

git add .
Submit-Commit-With-Date "Fix filter case handling"

# 4 - Add helper function (but not fully used yet)
@"
using System;
using System.Collections.Generic;
using System.Linq;

Console.WriteLine("DEBUG: starting app");

bool Matches(string task, string filter)
{
    return task.ToLower().Contains(filter.ToLower());
}

var tasks = new List<string>
{
    "Buy milk",
    "Write report",
    "Call Alice",
    "Fix bug"
};

Console.WriteLine("Enter filter:");
var filter = Console.ReadLine();

var filtered = tasks.Where(t => t.Contains(filter)).ToList();

Console.WriteLine("Tasks:");
foreach (var task in filtered)
{
    Console.WriteLine(task);
}
"@ | Set-Content -Path Program.cs

git add .
Submit-Commit-With-Date "Add Matches helper function"

# 5 - Start using helper (mixed change)
(Get-Content -Path Program.cs -Raw) -replace 't\.Contains\(filter\)', 'Matches(t, filter)' | Set-Content -Path Program.cs

git add .
Submit-Commit-With-Date "Use Matches helper in filter"

# 6 - Add new feature: exclude completed (fake)
"// TODO: exclude completed tasks" | Add-Content -Path Program.cs
git add .
Submit-Commit-With-Date "Add TODO for completed tasks"

# 7 - Add unrelated file in same commit
"Temporary notes" | Out-File -FilePath notes.txt
git add .
Submit-Commit-With-Date "Add temporary notes file"

# 9 - Formatting change mixed with logic
(Get-Content -Path Program.cs -Raw) -replace 'Console\.WriteLine\(task\);', 'Console.WriteLine("- " + task);' | Set-Content -Path Program.cs
git add .
Submit-Commit-With-Date "Prefix task output with dash"

# 10 - Bug: null filter crash fix
(Get-Content -Path Program.cs -Raw) -replace 'var filter = Console\.ReadLine\(\);', 'var filter = Console.ReadLine() ?? "";' | Set-Content -Path Program.cs

# Build, so we cause issues later, having changed the obj/ + bin/ files
dotnet build
git add .
Submit-Commit-With-Date "Handle null filter input" -Name "second_bad_bin_obj"

# 11 - More debug added again
'Console.WriteLine("DEBUG: filter=" + filter);' | Add-Content -Path Program.cs
git add .
Submit-Commit-With-Date "DEBUG: Log filter value" -Name debug2

# 12 - Partial refactor (rename variable)
$content = Get-Content -Path Program.cs -Raw
$content = $content -replace 'tasks', 'taskList'
[System.IO.File]::WriteAllText((Resolve-Path Program.cs), $content)
git add .
Submit-Commit-With-Date "Rename tasks variable to taskList"

# 13 - Another tweak mixed in
"// small tweak" | Add-Content -Path Program.cs
git add .
Submit-Commit-With-Date "Add small tweak comment"

# 15 - Add minor feature (prefix numbering)
$content = Get-Content -Path Program.cs -Raw
$content = $content -replace 'foreach \(var task in filtered\)', 'int i=1; foreach (var task in filtered)'
$content = $content -replace 'Console\.WriteLine\("- " \+ task\);', 'Console.WriteLine($" { i++ }. { task }");'
$content | Set-Content -Path Program.cs

git add .
Submit-Commit-With-Date "Number filtered task output"

# Fix OpenTelemetry.Api vulnerability
Set-Location ..
Set-Location OtherApp
dotnet package update OpenTelemetry.Api
git add OtherApp.csproj
Submit-Commit-With-Date "Fix OpenTelemetry.Api vulnerability" -Name fixvulnerability
Set-Location ..
Set-Location TaskApp

# 16 - Oops fix
"// fix later" | Add-Content -Path Program.cs
git add .
Submit-Commit-With-Date "Oops"

# 17 - Another unrelated change
"More notes" | Add-Content -Path notes.txt
git add .
Submit-Commit-With-Date "Update notes"

# Create a .gitignore. A bit too late
Set-Location ..
@"
bin/
obj/
"@ | Set-Content -Path .gitignore
git add .gitignore
Submit-Commit-With-Date "Add .gitignore" -Name "addgitignore"

# Generate WORKSHOP.md from template, replacing placeholders with actual values
Set-Location $script:initialLocation
$template = Get-Content -Path WORKSHOP.template.md -Raw
foreach ($key in $script:commitHashes.Keys) {
    $template = $template -replace "<COMMIT_SHA:$key>", $script:commitHashes[$key]
    $template = $template -replace "<COMMIT_TIME:$key>", $script:commitTimes[$key]
}

# Check for any unresolved <COMMIT_XXX:name> references
if ($template -match '<COMMIT_\w+:\w+>') {
    $unresolved = [regex]::Matches($template, '<COMMIT_\w+:\w+>') | ForEach-Object { $_.Value }
    Write-Warning "Unresolved commit placeholders found in template: $($unresolved -join ', ')"
}

$workshopPath = Join-Path $siteDir "WORKSHOP.md"
$template | Out-File -FilePath $workshopPath

Write-Host ""
Write-Host "Repo created!"
Write-Host ""
