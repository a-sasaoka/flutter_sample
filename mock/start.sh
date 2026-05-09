#!/bin/bash
# json-serverを、安定版(0.17.4)かつroutesルール付きでポート3000で起動します
npx json-server@0.17.4 mock/db.json --routes mock/routes.json --port 3000
