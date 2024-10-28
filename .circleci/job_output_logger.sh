#!/bin/bash

CIRCLECI_TOKEN=$CIRCLE_TOKEN
WORKFLOW_ID=$CIRCLE_WORKFLOW_ID
VCS_TYPE=$(echo $CIRCLE_BUILD_URL | cut -d'/' -f4)

if [[ "$VCS_TYPE" == "gh" ]]; then
  VCS_TYPE="github"
elif [[ "$VCS_TYPE" == "bb" ]]; then
  VCS_TYPE="bitbucket"
fi

USERNAME=$CIRCLE_PROJECT_USERNAME
PROJECT=$CIRCLE_PROJECT_REPONAME

echo "Gathering job_numbers for workflow: ${CIRCLE_WORKFLOW_ID}"

JOBS=$(curl -s -H "Circle-Token: $CIRCLECI_TOKEN" https://circleci.com/api/v2/workflow/${WORKFLOW_ID}/job)
JOB_NUMBERS=$(echo $JOBS | jq -r '.items[].job_number')

JSON_OUTPUT="[]"

echo "Accessing build data for job numbers: ${JOB_NUMBERS}"

for JOB_NUMBER in $JOB_NUMBERS
do

  echo "Gathering build outputs for job: ${JOB_NUMBER}"

  JOB_OUTPUT=$(curl -s -H "Circle-Token: $CIRCLECI_TOKEN" "https://circleci.com/api/v1.1/project/${VCS_TYPE}/${USERNAME}/${PROJECT}/${JOB_NUMBER}/output")
  JSON_OUTPUT=$(echo $JSON_OUTPUT | jq --arg jobOutput "$JOB_OUTPUT" '. + [{"type": "jobUrl", "content": $jobOutput}]')
  OUTPUT_URLS=$(echo $JOB_OUTPUT | jq -r '.[].url')
  STEP_NAMES=$(echo $JOB_OUTPUT | jq -r '.[].name')

  for OUTPUT_URL in $OUTPUT_URLS
  do
    LOGS=$(curl -s -H "Circle-Token: $CIRCLECI_TOKEN" "$OUTPUT_URL")
    JSON_OUTPUT=$(echo $JSON_OUTPUT | jq --arg logs "$LOGS" '. + [{"type": "stepLogs", "content": $logs}]')
    STEP_NAME=$(echo $STEP_NAMES | jq -r '.[]')
    echo "Processing step: ${STEP_NAME}"
  done
done

echo $JSON_OUTPUT > build_logs.json