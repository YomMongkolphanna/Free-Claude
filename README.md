# Claude Code + NVIDIA NIM

Run Claude Code backed by NVIDIA NIM models (free tier: 40 req/min).

## Folder structure

```
nim-claude-code/
├── setup.sh          ← Run once: installs everything + creates config
├── start.sh          ← Start proxy + launch Claude Code
├── stop.sh           ← Stop the proxy
├── switch-model.sh   ← Change NIM model
├── status.sh         ← Check if everything is running
├── config/
│   ├── .env          ← Your API key + model (created by setup.sh)
│   └── .env.example  ← Template
└── logs/
    ├── proxy.log     ← LiteLLM proxy output
    └── proxy.pid     ← Proxy process ID
```

## First time

```bash
cd nim-claude-code
chmod +x *.sh
./setup.sh
```

Get your free API key at build.nvidia.com → any model → "Get API Key".

## Every day

```bash
./start.sh
```

Starts the proxy, waits for it, launches Claude Code.
When you exit Claude Code the proxy stops automatically.

On first launch, Claude Code will ask how to log in — pick:
> 2. Anthropic Console account · API usage billing

When asked for an API key enter anything (e.g. `not-used`).

## Other commands

| Script | What it does |
|---|---|
| `./stop.sh` | Kill the proxy if it's still running |
| `./switch-model.sh` | Pick a different NIM model |
| `./status.sh` | Check proxy health + see recent logs |

## Edit config

```bash
nano config/.env
```

Change `MODEL_NAME` or `NIM_API_KEY` any time. Restart with `./start.sh`.

## Good models for coding

| Model | Best for |
|---|---|
| `meta/llama-3.1-70b-instruct` | General coding, reliable tool use |
| `qwen/qwen2.5-coder-32b-instruct` | Code-focused tasks |
| `mistralai/mistral-large-2` | Complex reasoning |
| `mistralai/devstral-small` | Fast, lightweight |

All models require tool-calling support for Claude Code to work properly.

## Troubleshooting

**Proxy won't start / ImportError apscheduler**
```bash
pip3 install 'litellm[proxy]'
rm -f logs/proxy.pid
./start.sh
```

**400 UnsupportedParamsError reasoning_effort**
Already fixed in this version via `--drop_params` flag in start.sh.

**404 model not found**
Model name in `.env` may be wrong. Check exact ID on build.nvidia.com.

**Port already in use**
```bash
./stop.sh
./start.sh
```
Or change `PROXY_PORT=4001` in `config/.env`.

**See full proxy output**
```bash
cat logs/proxy.log
```
