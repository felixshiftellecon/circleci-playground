#!/bin/bash

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

JOBS=$(curl https://circleci.com/api/v2/workflow/${WORKFLOW_ID}/job -H "Circle-Token: ${CIRCLE_TOKEN}")
JOB_NUMBERS=$(echo $JOBS | jq -r '.items[].job_number')

JSON_OUTPUT="[]"

echo "Accessing build data for job numbers: ${JOB_NUMBERS}"

for JOB_NUMBER in $JOB_NUMBERS
do
  echo "Gathering build logs for job: ${JOB_NUMBER}"

  JOB_OUTPUT=$(curl https://circleci.com/api/v1.1/project/${VCS_TYPE}/${USERNAME}/${PROJECT}/${JOB_NUMBER}/output -H "Circle-Token: ${CIRCLE_TOKEN}")
  
  STEPS=$(echo $JOB_OUTPUT | jq -c '.steps[]')

  for STEP in $STEPS
  do
    STEP_NAME=$(echo $STEP | jq -r '.name')
    OUTPUT_URL=$(echo $STEP | jq -r '.actions[].output_url')

    JSON_OUTPUT=$(echo $JSON_OUTPUT | jq --arg stepName "$STEP_NAME" --arg outputUrl "$OUTPUT_URL" '. + [{"stepName": $stepName, "outputUrl": $outputUrl}]')
  done

  echo "Gathered build logs for job: ${JOB_NUMBER}"
done

mkdir -p build_logs

echo $JSON_OUTPUT > build_logs/workflow_${CIRCLE_WORKFLOW_ID}_build_logs.json