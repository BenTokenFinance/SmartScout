#!/bin/sh

# ????docker-composeĿ¼
sudo rm -rf services/blockscout-db-data/
sudo rm -rf services/logs/
sudo rm -rf services/redis-data/
sudo rm -rf services/stats-db-data/

echo "clean."