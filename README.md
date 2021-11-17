# Code analysis and EditorConfig in .NET 5

## What does this sample include?

This sample provides an example implementation for providing code style and code analysis within the Visual Studio IDEs and during builds using .NET 5 and later.

The reference is structured such that code analysis is added to all csproj files within your repository without having to edit each one individually.

It also documents the various caveats and constraints present in the current state of code analysis (as of writing, November 2021),
including challenges if you are using an older .NET SDK (such as .NET Core 3.1) in migrating to the modern `Microsoft.CodeAnalysis.NetAnalyzers` analyzers and away from FxCop or StyleCop.

| File  | Description |
| ------------- | ------------- |
| `.editorconfig` | Configures the enforced ruleset and defines code style |
| `Directory.Build.targets` | Enforce code quality on build, automatically included for all csproj files in a repo. See [Customize your build - Visual Studio](https://docs.microsoft.com/en-us/visualstudio/msbuild/customize-your-build?view=vs-2019) |
| `ci.sh` | Script demonstrating CI steps to build projects, capture any rule violations, and produce code coverage reports |
| `global.json` | Defines which .NET SDK version to use (e.g. see contents of `global.net5.json` and `global.core31.json`) for example content, use `dotnet --info` to find your installed SDK version |
| `CodeAnalysisDemo.csproj` | An otherwise untouched .NET Core 3.1 csproj file created via `dotnet new` |

To try out code analysis from this repo with .NET Core 3.1, .NET 5 or .NET 6, copy one of the `global.*.json` files with the as `global.json`, then run `dotnet build`.
If you do not create a `global.json`, the default is to use the highest SDK version installed (more details [here](https://docs.microsoft.com/en-us/dotnet/core/tools/global-json?tabs=netcore3x)).

## Background

### History

In the past, NuGet packages like StyleCop and FxCop could be added to perform static binary analysis or code quality analysis and produce build errors as necessary.
These packages used `.ruleset` files that detailed the enabled or disabled state for every rule available.

The release of .NET Core introduced [Roslyn analyzers](https://docs.microsoft.com/en-us/visualstudio/code-quality/roslyn-analyzers-overview?view=vs-2019),
centralizing the ability to perform code analysis on build right within the framework.
The legacy static binary analyzers like FxCop and standalone code analysis tools like StyleCop were rewritten into Roslyn code analyzers and distributed as NuGet packages `Microsoft.CodeAnalysis.FxCopAnalyzers`  and `StyleCop.Analyzers` respectively
(see [Migrate from FxCop analyzers to .NET analyzers](https://docs.microsoft.com/en-us/visualstudio/code-quality/migrate-from-fxcop-analyzers-to-net-analyzers?view=vs-2019)).

In parallel, starting with Visual Studio 2017 the EditorConfig format became the supported and recommended way to adjust code style rules and enable or disable code analysis rules for these Roslyn analyzers as well.

### EditorConfig and .NET 5

The .NET 5 SDK now includes
[code style](https://docs.microsoft.com/en-us/dotnet/fundamentals/code-analysis/code-style-rule-options)
and [code quality](https://docs.microsoft.com/en-us/dotnet/fundamentals/code-analysis/code-quality-rule-options)
in its code analysis capabilities built-in; FxCop and StyleCop are no longer necessary, even if targeting older framework versions like `netcoreapp3.1` - see more at
[Code analysis in .NET](https://docs.microsoft.com/en-us/dotnet/fundamentals/code-analysis/overview).

Since the code quality analysis embedded in the .NET 5 SDK is redundant with that from the NuGet package,
[only one method out of the two should be used at once](https://docs.microsoft.com/en-us/dotnet/core/project-sdk/msbuild-props#enablenetanalyzers).
This sample has a drop-in `Directory.Build.targets` file to help automatically toggle between the two as necessary, without further adjustments to any of your `.csproj` files.

Although the .NET 5 SDK did not incorporate the StyleCop analyzers directly,
it does support an extensive set of style and formatting rules which are customizable via EditorConfig files and compatible with
[dotnet-format](https://github.com/dotnet/format) to auto-fix many rule violations.
Many code style violations can be enforced at build, and this will improve in .NET 6;
see more [here](https://docs.microsoft.com/en-us/dotnet/fundamentals/code-analysis/overview#enable-on-build).

## Setting up code analysis for your next project

[EditorConfig files](https://docs.microsoft.com/en-us/dotnet/fundamentals/code-analysis/configuration-files)
are the recommended way to define your code style, enforce it in the Visual Studio family of IDEs or during build,
and configure severity of additional rules for code quality analysis.

1. Copy the `Directory.Build.targets` file into your repository root and choose a value for `AnalysisMode` to set your baseline ruleset using a predefined configuration.

   This sample uses `Recommended`, a moderately conservative set of default rules.
   You may instead opt to enable all, or enable none as your baseline.
   For details, see [Enable additional rules](https://docs.microsoft.com/en-us/dotnet/fundamentals/code-analysis/overview#enable-additional-rules).

   This file will automatically be included for in any csproj in the same folder or below in the directory structure,
   and automatically enable code analysis on it.

2. Create an `.editorconfig` file in the repository root to define your preferred code style - read more at
   [Code style rule options](https://docs.microsoft.com/en-us/dotnet/fundamentals/code-analysis/code-style-rule-options):

   ```EditorConfig
   root = true

   # All files
   [*]
   end_of_line = lf
   indent_style = space

   # Language-specific rules
   # ...

   [*.cs]
   # Organize usings
   dotnet_sort_system_directives_first = true
   dotnet_separate_import_directive_groups = false
   # ... more style rules
   ```

   Optionally; you can use the included `.editorconfig` from this repository as a starting point.

   Note that some documentation or samples will include severity inline, for example:

   ```EditorConfig
   dotnet_sort_system_directives_first = true:error
   ```

   It is **not** recommended to use that syntax at the present time; see below for details.

3. Configure code style violation severity by configuring IDE\* rule severity.
   Each code style rule rolls up into a particular IDE rule identifier, e.g. `dotnet_style_readonly_field` is
   [IDE0044](https://docs.microsoft.com/en-us/dotnet/fundamentals/code-analysis/style-rules/ide0044#dotnet_style_readonly_field):

   ```EditorConfig
   [*.{cs,vb}]
   dotnet_style_readonly_field = true
   # ...
   dotnet_diagnostic.IDE0044.severity = warning
   ```

   Severity for [each IDE\* rule](https://docs.microsoft.com/en-us/dotnet/fundamentals/code-analysis/style-rules/#index)
   **must** be explicitly configured, as only configured IDE rules are enforced at build;
   severity on the named code style rules will only be surfaced in IDEs.

   Furthermore, configuring an IDE rule severity will **override** the inline severity configured on any member named code style rules.
   In other words, in order to achieve build-time errors, all inline code style severities are discarded.

   The `.editorconfig` file in this repository includes a section that configures all IDE* rules, if you wish to use it as a reference.

4. Customize the code quality rules from the baseline configuration.
   Rules can be enabled, disabled, or have their severity adjusted by applying customizations for
   [the available CA\* rules](https://docs.microsoft.com/en-us/dotnet/fundamentals/code-analysis/quality-rules/#index-of-rules):

   ```EditorConfig
   [*.{cs,vb}]

   # Explicitly enable CA5397 as warning, even if not in the preset
   dotnet_analyzer_diagnostic.CA5397.severity = warning

   # Silence CA1303, even if it was enabled by default preset
   dotnet_analyzer_diagnostic.CA1303.severity = silent

   # Set any already-enabled 'Performance' rules to warning severity
   # This does not enable any new rules that were not explicitly configured above, or already enabled from the baseline.
   dotnet_analyzer_diagnostic.category-Performance.severity = warning
   ```

   See [Configuration options for code analysis](https://docs.microsoft.com/en-us/dotnet/fundamentals/code-analysis/configuration-options#severity-level)
   for more details on severity, including `none` vs `silent` as well as semantics for category-wide severity overrides.

## Recap of issues

### Customizing code analysis and style rules

* After applying a baseline configuration using AnalysisMode, rules can only be enabled one-by-one in editorconfig.
  Per above rules can be enabled or disabled by setting their severity, but unlike for individual rules, setting severity for a whole category only affects
  [already-enabled rules](https://docs.microsoft.com/en-us/dotnet/fundamentals/code-analysis/configuration-options#scope).

* EditorConfig has two ways to surface code style problems: setting the severity either inline on the named style rule (e.g. `dotnet_style_readonly_field = true:warning`),
  or on severity of the IDE\* rule controls a group of named style rules (e.g. `dotnet_diagnostic.IDE0044.severity = warning`).
  * Only the latter (IDE\* rule severity) is supported for build-time enforcement
  * IDE\* rules are disabled by default, and therefore their severity must be explicitly configured in EditorConfig files to enable them for use with build-time analysis
  * Configuring IDE\* rule severity overrides any inline named code style rule severities prior configured in EditorConfig

### Baseline predefined configurations

* [Predefined configuration files](https://docs.microsoft.com/en-us/dotnet/fundamentals/code-analysis/predefined-configurations)
  notes the existence of the bundled configuration files in `Microsoft.CodeAnalysis.NetAnalyzers` package,
  however the bundled configurations not map to any
  [documented values for AnalysisMode](https://docs.microsoft.com/en-us/dotnet/core/project-sdk/msbuild-props#analysismode)
  (see [dotnet/roslyn#49250](https://github.com/dotnet/roslyn/issues/49250#issuecomment-760416810),
  tracking at [dotnet/docs#24211](https://github.com/dotnet/docs/issues/24211)).
* These baseline presets for different categories provided in the NuGet package disable all other categories, `.editorconfig` files are monolithic and do not support drop-in configuration.
  Developers must manually comb through and merge the various presets into a single `.editorconfig` file.

### Build-time enforcement

[EnforceCodeStyleInBuild](https://docs.microsoft.com/en-us/dotnet/core/project-sdk/msbuild-props#enforcecodestyleinbuild) enables build-time enforcement of code analysis violations, however:

* `EnforceCodeStyleInBuild` does nothing out of the box even if error severity is configured on the code style rules and are surfaced within the IDEs, because the IDE\* rules are not enabled by default.
  Build enforcement only uses IDE\* rule severity: [dotnet/roslyn#53215](https://github.com/dotnet/roslyn/issues/53215#issuecomment-833251218)
  * IDE\* rules can be enabled by explicitly setting their severity in EditorConfig
  * Configuring IDE rule severity rules discards any inline code style rule severities that were prior configured.
  * Only [a handful of IDE rules](https://docs.microsoft.com/en-us/dotnet/fundamentals/code-analysis/overview#enable-on-build) are supported for build-time validation, others are surfaced only in Visual Studio family of IDEs but ignored at build.

### .NET 5 code analysis vs .NET Core 3.1 w/ NuGet

[Overview of .NET source code analysis](https://docs.microsoft.com/en-us/dotnet/fundamentals/code-analysis/overview)
covers the .NET 5 code analysis including code quality and code style rules.
It mentions the `Microsoft.CodeAnalysis.NetAnalyzers` NuGet package is available for code analysis on older SDKs, and is redundant with the .NET 5 code analysis.

* The NuGet package only includes code *quality* (CA\*) rules and **not** the code *style* (IDE\*) rules that form the code analysis built-in to the .NET 5 SDK:
  [dotnet/roslyn#53215](https://github.com/dotnet/roslyn/issues/53215#issuecomment-833701041)

* Due to the lack of IDE* rule enforcement on .NET Core 3 SDK, its users can install
  [dotnet-format](https://github.com/dotnet/format)
  to auto-fix issues or verify code style violations during CI pipelines using the same EditorConfig code style rulesets described above:

  ```sh
  dotnet tool install -g dotnet-format
  dotnet-format --fix-whitespace --fix-style error --check

      Formatting code files in workspace 'repro/CodeAnalysisDemo.csproj'.

      Program.cs(20,30): error WHITESPACE: Fix whitespace formatting. Replace 1 characters with '\n\s\s\s\s\s\s\s\s'. [CodeAnalysisDemo.csproj]
      Program.cs(29,21): error IDE0040: Accessibility modifiers required [CodeAnalysisDemo.csproj]
      # ...

      Formatted code file 'repro/Program.cs'.
      Format complete in 5577ms.
  ```

* Incremental builds may sometimes fail to trigger code analysis on build:
  [dotnet/roslyn-analyzers#5069](https://github.com/dotnet/roslyn-analyzers/issues/5069)
