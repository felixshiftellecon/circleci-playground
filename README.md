# circleci-playground
for dummy commits 

command: |
                if [ -z "${$CIRCLE_PULL_REQUEST+x}" ]
                then 
                echo "no associated pull request"
                jq '. + {"run_branch_workflow": true}' > /tmp/temp.json
                else 
                echo "Pull request URL is ${CIRCLE_PULL_REQUEST}"
                jq '. + {"run_pr_workflow": true}' > /tmp/temp.json
                fi  