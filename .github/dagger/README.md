# Readme

```bash
# Install powershell 7
Invoke-WebRequest -UseBasicParsing -Uri https://dl.dagger.io/dagger-cue/install.ps1 | Invoke-Expression
dagger-cue project update
dagger-cue project update
dagger-cue do build --cache-to type=local,mode=max,dest=storage --cache-from type=local,mode=max,src=storage
```