#!/bin/sh

# ????docker-composeĿ¼
cd docker-compose/ || exit

# ??Զ?ֿ̲???ȡ???µĸ???
git pull origin sbch

# ????blockscout????
# docker compose -f external-frontend.yml build

# ??̨????blockscout????
FRONT_PROXY_PASS=http://host.docker.internal:3000 docker compose -f external-frontend.yml up -d

echo "Blockscout has been successfully updated and started."