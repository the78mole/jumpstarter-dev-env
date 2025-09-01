*** Settings ***
Documentation    Kubernetes-specific keywords for Jumpstarter testing
Library          KubernetesLibrary
Library          Process

*** Keywords ***
Verify Jumpstarter Deployment
    [Documentation]    Verify that all Jumpstarter components are deployed correctly
    ${controller_deployment}    Get Deployment    jumpstarter-controller    jumpstarter-system
    Should Be Equal As Numbers    ${controller_deployment.status.ready_replicas}    1
    
    ${router_deployment}    Get Deployment    jumpstarter-router    jumpstarter-system
    Should Be Equal As Numbers    ${router_deployment.status.ready_replicas}    2

Check Service Endpoints
    [Documentation]    Check if services have proper endpoints
    ${controller_service}    Get Service    jumpstarter-controller    jumpstarter-system
    Should Not Be Empty    ${controller_service.spec.ports}
    
    ${router_service}    Get Service    jumpstarter-router    jumpstarter-system
    Should Not Be Empty    ${router_service.spec.ports}

Restart Deployment
    [Documentation]    Restart a deployment by scaling down and up
    [Arguments]    ${deployment_name}    ${namespace}=${NAMESPACE}
    Scale Deployment    ${deployment_name}    ${namespace}    0
    Wait Until Keyword Succeeds    30s    5s
    ...    Check Deployment Replicas    ${deployment_name}    ${namespace}    0
    
    Scale Deployment    ${deployment_name}    ${namespace}    1
    Wait Until Keyword Succeeds    60s    5s
    ...    Check Deployment Replicas    ${deployment_name}    ${namespace}    1

Check Deployment Replicas
    [Documentation]    Check if deployment has expected number of replicas
    [Arguments]    ${deployment_name}    ${namespace}    ${expected_replicas}
    ${deployment}    Get Deployment    ${deployment_name}    ${namespace}
    Should Be Equal As Numbers    ${deployment.status.ready_replicas}    ${expected_replicas}

Get Pod Logs
    [Documentation]    Get logs from a pod
    [Arguments]    ${pod_name}    ${namespace}=${NAMESPACE}    ${lines}=50
    ${result}    Run Process    kubectl    logs    ${pod_name}    -n    ${namespace}    --tail\=${lines}
    [Return]    ${result.stdout}
