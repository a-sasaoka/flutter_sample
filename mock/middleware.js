const fs = require('fs');
const path = require('path');

/**
 * json-server用のミドルウェア
 * 
 * mock/fail というファイルが存在する場合、すべてのリクエストに対して
 * 500 Internal Server Error を返します。
 */
module.exports = (req, res, next) => {
  const failFilePath = path.join(__dirname, 'fail');

  if (fs.existsSync(failFilePath)) {
    // スイッチファイルが存在する場合は500エラーを返す
    console.log('⚠️ [Mock Server] Error switch is ON. Returning 500 error.');
    return res.status(500).jsonp({
      error: "サーバー内部でエラーが発生しました（ファイルスイッチによる擬似エラー）",
      method: req.method,
      path: req.url
    });
  }

  // それ以外は通常の処理を続行
  next();
};
