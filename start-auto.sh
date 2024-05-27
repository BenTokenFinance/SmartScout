#!/bin/sh

# ½øÈësonarÄ¿Â¼
cd blokcscout/SmartScout/ || exit

# ½øÈëdocker-composeÄ¿Â¼
cd docker-compose/ || exit

# ´ÓÔ¶³Ì²Ö¿âÀ­È¡×îÐÂµÄ¸ü¸Ä
git pull origin index

# ¹¹½¨blockscout¾µÏñ
FRONT_PROXY_PASS=http://host.docker.internal:3000 docker compose up -d

# ºóÌ¨Æô¶¯blockscout·þÎñ
docker run -p 3000:3000 --env-file .env -d  blockscout-frontend:local

echo "Blockscout has been successfully updated and started."