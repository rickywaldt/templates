# Attach subscription instructions

## OCM token

Grab the OCM token from here: <https://console.redhat.com/openshift/token/show>
Then add it to project > settings > ci/cd > variables as OCM_TOKEN (masked & protected).

## GitLab CI stage

Add the following to .gitlab-ci.yaml:

```
stages:
  - register

attach-subscription:
  stage: register
  image: (needs oc, ocm, and jq)
  script:
    - ./scripts/attach-subscription.sh
  rules:
    - if: '$CI_COMMIT_BRANCH == "main" # your rule
  retry: 1
