#!/bin/bash
echo "> drive"
git pull
rm -rf ./out
chmod +x ./build.sh
npm install
npm run build