reg add "HKEY_CURRENT_USER\Environment" /v PATH /t REG_EXPAND_SZ /d "%path%;%cd%" /f
reg add "HKEY_CURRENT_USER\Environment" /v dvmPath /t REG_EXPAND_SZ /d "%cd%" /f