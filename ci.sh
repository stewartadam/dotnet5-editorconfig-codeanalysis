#!/bin/sh
set -e

# Perform a build to catch any code analysis or style rule violations
dotnet build **/*.csproj

# Microsoft.CodeAnalysis.NetAnalyzers does not include IDE* code style rules
if [[ $(dotnet --version | cut -d'.' -f1) -lt 5 ]];then
  # If using .NET Core SDKs, use dotnet-format as a workaround for detecting IDE violations
  dotnet tool install -g dotnet-format
  dotnet-format --fix-whitespace --fix-style error --check
fi

# Run unit tests and capture coverage - TODO: adjust coverage threshold as necessary
dotnet test **/*.UnitTests.csproj /p:CollectCoverage=true /p:threshold=70 /p:thresholdType=line /p:thresholdStat=total /p:CoverletOutputFormat=cobertura

# Merge code coverage from individual projects
mkdir -p reports/
dotnet tool install -g dotnet-reportgenerator-globaltool
~/.dotnet/tools/reportgenerator -reports:**/coverage.cobertura.xml -targetdir:./reports -reporttypes:"HtmlInline_AzurePipelines;Cobertura"

# TODO: Publish code coverage report - specific to your CI environment