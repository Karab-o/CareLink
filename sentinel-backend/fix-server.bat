@echo off
echo Fixing Sentinel Backend Server...

echo Checking Node.js...
node --version
if errorlevel 1 (
    echo Node.js not found! Please install Node.js first.
    pause
    exit /b 1
)

echo Killing any existing servers on port 3000...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000') do taskkill /PID %%a /F 2>nul

echo Installing express...
npm install express

echo Creating test server...
echo const express = require('express'); > test-server.js
echo const app = express(); >> test-server.js
echo app.get('/health', (req, res) =^> res.json({status: 'OK', message: 'Working!'})); >> test-server.js
echo app.listen(3000, () =^> console.log('Server: http://localhost:3000/health')); >> test-server.js

echo Starting server...
node test-server.js