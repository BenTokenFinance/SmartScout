#!/bin/sh

# ????docker-composeĿ¼
sudo rm -f services/blockscout-db-data/
sudo rm -f services/logs/
sudo rm -f services/redis-data/
sudo rm -f services/stats-db-data/

echo "clean."