#!/usr/bin/env pwsh

$env:AzureSubscriptionId = '6d3acc75-039d-4a84-a0c2-883e492a72dd'
$env:NetworkSubscriptionId = '9ed6f940-4ca4-4512-a8f8-a08f8d151201'
$env:AZUREREGION = 'eastus'

$cheatSheet = ""
if ($env:CODESPACES -eq 'true') {
    # Start-Actions
    function global:sa {
        zsh -c "unset SKYRISEV3 && $env:ACTIONS_CODESPACES_PATH/script/server --scenario actions-larger-runners-e2e"
    }

    # New Codespace Setup
    function global:ncs {
        if (-not (Test-Path "$env:SKYRISE_PATH/../bin" -PathType Container)) {
            src
            b
        }
        if ($LastExitCode -eq 0) {
            zsh -c "cd '$env:GITHUB_PATH' && gh medic"
            if ($LastExitCode -eq 0) {
                zsh -c "unset SKYRISEV3 && cd '$env:SKYRISE_PATH' && script/setup-codespaces-runner.ps1"
                if ($LastExitCode -eq 0) {
                    zsh -c "cd '$env:LAUNCH_PATH' && script/setup --force"
                    if ($LastExitCode -eq 0) {
                        sa
                    }
                }
            }
        }
    }

    # runner job agent logs
    function global:rjl {
        kubectl logs $(kubectl get pods -o name | grep 'pod/runner-job-agent-') --follow
    }

    # runner api server logs
    function global:ral {
        kubectl logs $(kubectl get pods -o name | grep 'pod/runner-api-server-') --follow
    }

    # faults in the host to Actions and Runner services
    # https://github.com/github/actions-dotnet/blob/main/script/autopath/faultInOrg
    function global:fig { faultInOrg github }
    function global:fia { faultInOrg actions }
    
    # Rerun dotfiles install
    function global:di { 
        zsh -c "cd '$env:DOTFILESPATH' && git pull && ./install.sh"
    }

    # run L2s in parallel
    function global:l2p {
        run_tests_parallel.ps1 "$env:BINARIESDIR/Runner.Service/Debug" 'GitHub.Actions.Runner.Service.L2.Tests.dll' '' "$env:BUILDDIR/Runner/Runner.L2.runsettings" 'Priority=1' '' "$env:BUILDDIR/../temp/L2"
    }

    # deploy runner
    function global:depr {
        deploy runner -useexistingdatabases
    }

    # build, deploy runner
    function global:bdr {
        b
        if ($LastExitCode -eq 0) {
            depr
        }
    }

    # pull, build, deploy runner
    function global:pbdr {
        git pull
        if ($LastExitCode -eq 0) {
            bdr
        }
    }

    $cheatSheet += "
bdr     build, deploy runner
di      dotfiles install latest
dr      deploy runner
fia     faultInOrg actions
fig     faultInOrg github
l2p     run L2s in parallel
ncs     new codespace setup
pbdr    pull, build, deploy runner
ral     runner api server logs
rjl     runner job agent logs
sa      start actions
"
}

    $cheatSheet += "
k       kubectl
brl0    build and run l0
brl1    build and run l1"

# kubectl
function global:k {
    kubectl $args
}

# Build Run L0s
function global:brl0 {
    b
    if ($LastExitCode -eq 0) {
        l0
    }
}

# Build Run L1s
function global:brl1 {
    b
    if ($LastExitCode -eq 0) {
        l1
    }
}

function global:cheat {
    write-host $cheatSheet
}
