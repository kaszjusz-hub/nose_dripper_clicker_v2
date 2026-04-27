# Local SearXNG Setup

This project uses a shared SearXNG setup located at `C:\Users\Gintakun\searxng`.

## Start local SearXNG
1. Open PowerShell and run:
   `powershell -ExecutionPolicy Bypass -File C:\Users\Gintakun\searxng\start_searxng.ps1`
2. Wait ~10 seconds for the container to start, then test with:
   `python C:\Users\Gintakun\searxng\searx_wrapper.py "test query"`

## Fallback
If the local container is not running, the wrapper will automatically fall back to https://searx.party.

## Stop
`docker compose down` from `C:\Users\Gintakun\searxng`