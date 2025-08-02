#!/bin/sh
cd "$(dirname "$0")/../../jslib"
npm install
npm run build
