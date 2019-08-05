#!/bin/sh

cd PoliticalDebateApp_iOSTests/PoliticalDebateApp_BackendStubs/
git pull
python3 UpdateStubs.py
cd ../..
