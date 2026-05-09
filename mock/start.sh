#!/bin/bash
# json-serverを、安定版(0.17.4)、routesルール、およびミドルウェア付きでポート3000で起動します
npx json-server@0.17.4 mock/db.json --routes mock/routes.json --middlewares mock/middleware.js --port 3000
