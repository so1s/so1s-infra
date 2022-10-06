#!/bin/bash

USER_MENTION="<@$SO1S_NOTI_USER_ID>"

START_MSG=$(echo '{"text":"Terraform 프로비저닝 시작 by USER"}' | sed "s/USER/$USER_MENTION/g")
END_MSG=$(echo '{"text":"USER 빌드 다됐어요~ sealed-secret bootstrap을 추가적으로 진행해 주세요~"}' | sed "s/USER/$USER_MENTION/g")

curl -X POST -H 'Content-type: application/json' --data "$START_MSG" $SO1S_NOTI_WEBHOOK

./bootstrap.sh

curl -X POST -H 'Content-type: application/json' --data "$END_MSG" $SO1S_NOTI_WEBHOOK

if [ "$(uname)" = "Darwin" ]; then
    afplay /System/Library/Sounds/Sosumi.aiff -v 15 &
fi

rm -f build.log