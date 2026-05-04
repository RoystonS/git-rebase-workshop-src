#!/usr/bin/env pwsh
#Requires -Version 7.0

$ErrorActionPreference = "Stop"

# --- Fake commit timestamps ---
$COMMIT_START_DATE = "2024-01-15 09:00:00"
$COMMIT_INTERVAL_SECONDS = 300   # seconds between commits

$_commit_ts = [DateTimeOffset]::new((Get-Date $COMMIT_START_DATE), [TimeSpan]::Zero).ToUnixTimeSeconds()

function Submit-Commit-With-Date {
    param(
        [string]$Message,
        [int]$Interval = $COMMIT_INTERVAL_SECONDS
    )
    $script:_commit_ts = $_commit_ts + $Interval
    $ts = (Get-Date -UnixTimeSeconds $_commit_ts).ToString("yyyy-MM-ddTHH:mm:ss")
    $env:GIT_AUTHOR_DATE = $ts
    $env:GIT_COMMITTER_DATE = $ts
    git commit -m $Message
}

$REPO_NAME = "git-rebase-workshop"

# Clean up and create repo directory
if (Test-Path $REPO_NAME) {
    Remove-Item -Recurse -Force $REPO_NAME
}

# Create output directory
New-Item -ItemType Directory -Name $REPO_NAME | Out-Null
Set-Location $REPO_NAME

git init --initial-branch=main

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
Submit-Commit-With-Date "Add Demo solution"

git tag forkpoint

# Fix the typo in README.md before committing
(Get-Content -Path README.md -Raw) -replace 'dottnet', 'dotnet' | Set-Content -Path README.md
git add README.md

Submit-Commit-With-Date "Fix README typo"

# Create a PR branch from an earlier point and do some PR work on it to create the TaskApp
git checkout -b pr/new-work forkpoint
git tag -d forkpoint

dotnet new console --name TaskApp
dotnet solution Demo.slnx add TaskApp/TaskApp.csproj

git add *.slnx TaskApp/Program.cs TaskApp/*.csproj

Submit-Commit-With-Date "Create TaskApp project" -60

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
Submit-Commit-With-Date "Add basic task list"

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
"Console.WriteLine(""DEBUG: starting app""); `r`n$content" | Set-Content -Path Program.cs

git add .
Submit-Commit-With-Date "Add debug startup log"

# 3 - Case-insensitive fix
(Get-Content -Path Program.cs -Raw) -replace 'Contains\(filter\)', 'ToLower().Contains(filter.ToLower())' | Set-Content -Path Program.cs

git add .
Submit-Commit-With-Date "Fix filter case handling"

# 4 - Add helper function (but not fully used yet)
@"
using System;
using System.Collections.Generic;
using System.Linq;

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

# 8 - Remove debug (but not all)
(Get-Content -Path Program.cs) | Where-Object { $_ -notmatch 'DEBUG' } | Set-Content -Path Program.cs
git add .
Submit-Commit-With-Date "Remove debug startup log"

# 9 - Formatting change mixed with logic
(Get-Content -Path Program.cs -Raw) -replace 'Console\.WriteLine\(task\);', 'Console.WriteLine("- " + task);' | Set-Content -Path Program.cs
git add .
Submit-Commit-With-Date "Prefix task output with dash"

# 10 - Bug: null filter crash fix
(Get-Content -Path Program.cs -Raw) -replace 'var filter = Console\.ReadLine\(\);', 'var filter = Console.ReadLine() ?? "";' | Set-Content -Path Program.cs

# Build, so we cause issues later, having changed the obj/ + bin/ files
dotnet build
git add .
Submit-Commit-With-Date "Handle null filter input"

# 11 - More debug added again
'Console.WriteLine("DEBUG: filter=" + filter);' | Add-Content -Path Program.cs
git add .
Submit-Commit-With-Date "Log filter value for debugging"

# 12 - Partial refactor (rename variable)
(Get-Content -Path Program.cs -Raw) -replace 'tasks', 'taskList' | Set-Content -Path Program.cs
git add .
Submit-Commit-With-Date "Rename tasks variable to taskList"

# 13 - Another tweak mixed in
"// small tweak" | Add-Content -Path Program.cs
git add .
Submit-Commit-With-Date "Add small tweak comment"

# 14 - Remove some debug again
(Get-Content -Path Program.cs) | Where-Object { $_ -notmatch 'DEBUG' } | Set-Content -Path Program.cs
git add .
Submit-Commit-With-Date "Remove debug log lines"

# 15 - Add minor feature (prefix numbering)
$content = Get-Content -Path Program.cs -Raw
$content = $content -replace 'foreach \(var task in filtered\)', 'int i=1; foreach (var task in filtered)'
$content = $content -replace 'Console\.WriteLine\("- " \+ task\);', 'Console.WriteLine($" { i++ }. { task }");'
$content | Set-Content -Path Program.cs

git add .
Submit-Commit-With-Date "Number filtered task output"

# 16 - Oops fix
"// fix later" | Add-Content -Path Program.cs
git add .
Submit-Commit-With-Date "Oops"

# 17 - Another unrelated change
"More notes" | Add-Content -Path notes.txt
git add .
Submit-Commit-With-Date "Update notes"

# 18 - Final messy state
git add .
Submit-Commit-With-Date "Apply final workshop changes"

Write-Host ""
Write-Host "Repo created!"
Write-Host "Go to: $REPO_NAME/TaskApp"
Write-Host ""
Write-Host "Run: git log --oneline"
