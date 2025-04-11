# spell_strike

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Hi

114/04/11 2:50PM 更新
在pubspec.yaml中新增了錄音和請求權限的插件
新增了lib\services\recording.dart
在main.dart中導入、創建、初始化錄音器(_audioRecorder)
android\app\build.gradle.kts中的 minSdk從flutter.minSdkVersion改為24，因為flutter_sound插件不支援原本的21版本
錄音檔位置：/data/user/0/com.example.spell_strike/cache/，recording.dart中有對應獲取位址的功能


114/04/11 9:12PM 更新
新增了lib\services\whisper.dart
在main.dart中導入、創建、初始化與語音轉文字的工具(_whisperService)
文字檔位置：/data/user/0/com.example.spell_strike/app_flutter/transcription.txt，whisper.dart中有對應獲取位址的功能
我有試試看時間戳記的功能，不過免費API好像沒此功能，所以就沒加了
我只有試過whisper large v3和其turbo版，感覺兩者跑起來速度差不多，但非turbo版的精準度比較高
使用前記得去whisper.dart更改apiKey，hugging face的金鑰獲取方法寫在最下面
我還有新增播放剛錄製的音檔的功能，主要是為了測試錄音功能正常，不需要刪掉就行

步驟 1：註冊或登錄 Hugging Face 帳戶
開啟瀏覽器，前往 Hugging Face 官方網站：https://huggingface.co。
註冊帳戶（如果尚未註冊）：
點擊右上角的 Sign Up（註冊）按鈕。
輸入你的電子郵件地址、設置密碼，或選擇使用 GitHub/Google 帳戶快速註冊。
完成電子郵件驗證（如果需要，檢查你的收件箱或垃圾郵件資料夾）。
登錄帳戶（如果已有帳戶）：
點擊右上角的 Log In（登錄），輸入你的電子郵件和密碼，或使用 GitHub/Google 登錄。
步驟 2：進入個人資料設置
登錄後，點擊右上角的個人頭像（通常是你的用戶名或頭像圖標）。
在下拉選單中，選擇 Settings（設置）。
步驟 3：訪問 API 密鑰頁面
在設置頁面中，找到側邊欄（或頁面選項）中的 Access Tokens（訪問令牌）選項，點擊進入。
如果你看不到這個選項，確保你已經登錄，並檢查是否在正確的設置頁面。
步驟 4：創建新的 API 密鑰
在 Access Tokens 頁面，你會看到一個名為 New Token（新建令牌）或 Create a token（創建令牌）的按鈕，點擊它。
設置密鑰名稱：
為你的密鑰取一個容易識別的名稱（例如 speech-to-text-test），這有助於你管理多個密鑰。
選擇權限：
選擇 Read（讀取）權限即可，這對於使用 Inference API 進行試用（如語音轉文字）已經足夠。
如果你計劃上傳模型或數據集，則可能需要 Write（寫入）權限，但目前試用語音轉文字不需要。
點擊 Create（創建）或確認按鈕。
步驟 5：複製 API 密鑰
創建成功後，你會看到一個新的 API 密鑰（一串以 hf_ 開頭的字串，例如 hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxx）。
立即複製密鑰：
點擊密鑰旁邊的「複製」圖標，或手動選中並複製。
注意：Hugging Face 可能只顯示一次完整密鑰，關閉頁面後你可能無法再次看到完整密鑰（但可以重新生成）。


使用前記得去whisper.dart更改apiKey