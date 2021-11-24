#!/bin/bash

# -------------------------------------- Required environment variables -------------------------------------------
# -----------------------------------------------------------------------------------------------------------------
#
# - APP_ID                                   : App ID of the GitHub bot (needed to generate JWT)
# - APP_INSTALLATION                         : Installation number of the GitHub bot (needed to get access token)
# - PK                                       : PK
# - DRONE_PULL_REQUEST                       : GitHub Pull request number ({issue_number})
# - DRONE_REPO                               : Github {owner}/{repo}
# - DRONE_BUILD_NUMBER                       : Build number
# - DRONE_COMMIT_SHA                         : Git commit on which the tests are running
#
# -----------------------------------------------------------------------------------------------------------------
# -----------------------------------------------------------------------------------------------------------------


#$1 is URL, $2 is token, $3 is data
ghSend() {
    curl -s --trace - \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: Bearer $2" \
  $1 \
  --data "$3"
}

COMMIT_STATUS="error"
COMMIT_STATUS_CONTEXT="clang-format"
COMMIT_STATUS_DESCRIPTION=""

SCRIPT_PATH=$(dirname $(realpath $BASH_SOURCE))
REPO_PATH=$SCRIPT_PATH/..

cd $REPO_PATH #Clang operations need to run on the repo's root folder

wget https://raw.githubusercontent.com/llvm/llvm-project/main/clang/tools/clang-format/clang-format-diff.py

CHANGED_FILES=$(git diff --name-only origin/master | grep -E "(.+.)(h|hpp|c|cpp|cc)(\n|$)")

git diff -U0 --color=never origin/master -- ${CHANGED_FILES} | python3 clang-format-diff.py -p1 -style=file

CLANG_FORMAT_DIFF=$(git diff -U0 --color=never origin/master -- ${CHANGED_FILES} | python3 clang-format-diff.py -p1 -style=file | sed ' :a;N;$!ba; s/\\/\\\\/g; s/\n/\\n/g; s/\t/\\t/g; s/"/\\"/g')

cd $SCRIPT_PATH

printf %b $PK > 'pk.pem'

ACCESS_TOKEN=$(./get-access-token.sh)

if [[ -n $CLANG_FORMAT_DIFF ]]; then
    COMMIT_STATUS="failure"
    COMMIT_STATUS_DESCRIPTION="Changes formatted incorrectly"
    
    #Make comment with diff
   ghSend "https://api.github.com/repos/$DRONE_REPO/issues/$DRONE_PULL_REQUEST/comments" $ACCESS_TOKEN "{\"body\":\"\`\`\`diff\n${CLANG_FORMAT_DIFF}\n\`\`\`\"}"
else
    COMMIT_STATUS="success"
    COMMIT_STATUS_DESCRIPTION="Changes formatted properly"
fi

ghSend "https://api.github.com/repos/$DRONE_REPO/statuses/$DRONE_COMMIT_SHA" $ACCESS_TOKEN "{\"state\":\"$COMMIT_STATUS\",\"owner\":\"crow-clang-format\",\"description\":\"$COMMIT_STATUS_DESCRIPTION\",\"target_url\":\"https://cloud.drone.io/$DRONE_REPO/$DRONE_BUILD_NUMBER\",\"context\":\"crow-clang-format\"}"
