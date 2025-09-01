*** Settings ***
Documentation    Jumpstarter Server Test Suite
Library          RequestsLibrary
Library          KubernetesLibrary
Resource         resources/common.robot
Suite Setup      Setup Test Environment
Suite Teardown   Teardown Test Environment

*** Test Cases ***
Controller Health Check
    [Documentation]    Test if the Jumpstarter Controller is healthy
    [Tags]    health    controller
    ${response}    GET    ${CONTROLLER_URL}/health
    Should Be Equal As Strings    ${response.status_code}    200
    Log    Controller health check passed

Router Health Check
    [Documentation]    Test if the Jumpstarter Router is healthy
    [Tags]    health    router
    ${response}    GET    ${ROUTER_URL}/health
    Should Be Equal As Strings    ${response.status_code}    200
    Log    Router health check passed

Kubernetes Pods Running
    [Documentation]    Verify all Jumpstarter pods are running
    [Tags]    kubernetes    pods
    @{pods}    Get Pods In Namespace    jumpstarter-system
    FOR    ${pod}    IN    @{pods}
        Should Be Equal    ${pod.status.phase}    Running
        Log    Pod ${pod.metadata.name} is running
    END

Controller Metrics Available
    [Documentation]    Test if Controller metrics endpoint is accessible
    [Tags]    metrics    controller
    ${response}    GET    ${CONTROLLER_URL}/metrics
    Should Be Equal As Strings    ${response.status_code}    200
    Should Contain    ${response.text}    # HELP
    Log    Controller metrics are available

Router Metrics Available
    [Documentation]    Test if Router metrics endpoint is accessible
    [Tags]    metrics    router
    ${response}    GET    ${ROUTER_URL}/metrics
    Should Be Equal As Strings    ${response.status_code}    200
    Should Contain    ${response.text}    # HELP
    Log    Router metrics are available
