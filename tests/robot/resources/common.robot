*** Settings ***
Documentation    Common resources for Jumpstarter tests
Library          RequestsLibrary
Library          KubernetesLibrary

*** Variables ***
${CONTROLLER_URL}    http://localhost:8080
${ROUTER_URL}        http://localhost:8081
${NAMESPACE}         jumpstarter-system
${TIMEOUT}           30s

*** Keywords ***
Setup Test Environment
    [Documentation]    Setup test environment
    Log    Setting up test environment
    Create Session    controller    ${CONTROLLER_URL}
    Create Session    router        ${ROUTER_URL}

    # Port-forwarding für Tests (falls nicht bereits aktiv)
    ${result}    Run Process    pgrep    -f    kubectl.*port-forward.*jumpstarter-controller
    Run Keyword If    '${result.rc}' != '0'    Start Controller Port Forward

    ${result}    Run Process    pgrep    -f    kubectl.*port-forward.*jumpstarter-router
    Run Keyword If    '${result.rc}' != '0'    Start Router Port Forward

    Sleep    5s    # Wait for port forwarding to be ready

Teardown Test Environment
    [Documentation]    Cleanup test environment
    Log    Cleaning up test environment
    Delete All Sessions

Start Controller Port Forward
    [Documentation]    Start port forwarding for controller
    Start Process    kubectl    port-forward    svc/jumpstarter-controller    8080:8080    -n    ${NAMESPACE}
    ...    alias=controller-pf    stdout=/tmp/controller-pf.log    stderr=STDOUT

Start Router Port Forward
    [Documentation]    Start port forwarding for router
    Start Process    kubectl    port-forward    svc/jumpstarter-router    8081:8081    -n    ${NAMESPACE}
    ...    alias=router-pf    stdout=/tmp/router-pf.log    stderr=STDOUT

Wait For Pod Ready
    [Documentation]    Wait for a specific pod to be ready
    [Arguments]    ${pod_name}    ${namespace}=${NAMESPACE}
    Wait Until Keyword Succeeds    ${TIMEOUT}    5s
    ...    Check Pod Status    ${pod_name}    ${namespace}    Running

Check Pod Status
    [Documentation]    Check if pod is in expected status
    [Arguments]    ${pod_name}    ${namespace}    ${expected_status}
    ${pod}    Get Pod    ${pod_name}    ${namespace}
    Should Be Equal    ${pod.status.phase}    ${expected_status}

Get Pods In Namespace
    [Documentation]    Get all pods in a namespace
    [Arguments]    ${namespace}
    ${pods}    List Pods In Namespace    ${namespace}
    [Return]    ${pods.items}
