@echo off
REM Torbali Kurye Agi prototipini http ile acar (sekmeler arasi senkron icin onerilir)
cd /d "%~dp0"
echo Prototip aciliyor: http://localhost:8080/index.html
echo Kapatmak icin bu pencereyi kapatin.
python -m http.server 8080
