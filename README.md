<p align="center"><b>VERDICT DFIR Agent</b></p>

<p align="center"><b>Show Me the Evidence — a local-first, self-hostable agent for digital forensics & incident response.</b></p>

<p align="center">
  <img src="https://img.shields.io/badge/agent-opencode%20fork-4D5DFF.svg" alt="opencode fork">
  <img src="https://img.shields.io/badge/models-provider--agnostic-B8A8FF.svg" alt="provider agnostic">
  <img src="https://img.shields.io/badge/tools-46%20read--only%20forensic%20MCP-73D9C2.svg" alt="46 forensic tools">
  <img src="https://img.shields.io/badge/custody-verifiable%20offline-73D9C2.svg" alt="custody">
</p>

---

> **Trace it. Test it. Trust it.** This is "Claude Code for forensics": the
> [VERDICT](https://github.com/TimothyVang/verdict-opencode) agent driving the
> VERDICT forensic tool surface — on the model *you* choose, including fully
> local ones, so evidence never has to leave the box.

This repository is a **profile**, not an application. It is an `.opencode/`
bundle — DFIR agents, evidence-type slash commands, and an investigation skill —
that turns the branded [`verdict`](https://github.com/TimothyVang/verdict-opencode)
opencode fork into a forensic investigator wired to VERDICT's read-only,
audit-chained MCP tools. The forensic **brain** (roles, playbooks, artifact
doctrine) is ported from the [VERDICT DFIR
toolkit](https://github.com/TimothyVang/verdict-dfir-community)'s `agent-config/`.

## What you get

- **A DFIR primary agent** (`verdict`) plus subagents — persistence-biased
  `pool-a`, exfiltration-biased `pool-b`, a `verifier` that re-runs cited tool
  calls, a `judge` (Analysis of Competing Hypotheses), and a `correlator`.
- **Evidence-type commands** — `/triage`, `/disk`, `/memory`, `/evtx`,
  `/network`, `/velociraptor`, `/fleet`, and `/verdict` (reason + seal).
- **The forensic tools attached** — `findevil-mcp` (32 Rust DFIR primitives) and
  `findevil-agent-mcp` (14 Python crypto/custody/reasoning tools).
- **Chain of custody** — hash-chained `audit.jsonl` → Merkle root → signed
  `run.manifest.json`, verifiable offline.
- **Three verdict words, no more:** `SUSPICIOUS`, `INDETERMINATE`, `NO_EVIL`.

## Bring your own model (no default)

There is **no hardcoded model** — you pick one with opencode's `/models` picker.
The profile registers a provider-agnostic OpenAI-compatible local provider
(`verdict-local`) alongside opencode's full cloud catalog, so you can run:

| Endpoint | How |
| --- | --- |
| **Ollama** (local, offline) | `ollama serve` + `ollama pull <model>`; default `VERDICT_LLM_BASEURL=http://localhost:11434/v1` |
| **vLLM / LM Studio / llama.cpp** | point `VERDICT_LLM_BASEURL` at its `/v1` endpoint |
| **Cloud** (Anthropic/OpenAI/…) | authenticate in opencode and select via `/models` |

> **Model choice matters — a lot.** Local agentic DFIR needs a strong native
> **tool-calling** model. In testing on the `nitroba.pcap` fixture:
> a capable model (e.g. `gpt-5.5` / `gpt-5.4-mini`) drove the real chain
> `case_open` → `pcap_triage` and returned evidence-bound findings, correctly
> flagging them as *triage leads, not a verdict*. Small **CPU-only** local models
> did **not**: `qwen2.5-coder:7b` emitted the tool call as plain text (never
> executed) and `llama3.1:8b` fabricated findings. Until you have a GPU + vLLM
> serving a strong tool-caller, prefer a capable model via `/models` for real
> investigations; treat small local models as offline/triage-only.

## Prerequisites

1. The **`verdict`** binary on `PATH` — build the fork:
   [verdict-opencode](https://github.com/TimothyVang/verdict-opencode).
2. The **toolkit** (MCP servers) —
   [verdict-dfir-community](https://github.com/TimothyVang/verdict-dfir-community).
   Set `VERDICT_DFIR_HOME` to its checkout (auto-detected if it's a sibling
   directory). Prebuild the Rust MCP: `cargo build --release -p findevil-mcp`.
   `uv` is required for the Python MCP.
3. A **model endpoint** (local or cloud, per the table above).

Run `./install.sh` to check all of the above.

## Quickstart

```bash
./install.sh --link                     # verify prereqs, link `verdict-dfir` onto PATH
export VERDICT_DFIR_HOME=~/verdict-dfir-community   # if not auto-detected
ollama serve & ollama pull qwen2.5-coder:7b         # or any OpenAI-compatible endpoint

verdict-dfir /path/to/case               # launch the DFIR agent on a case directory
```

In the TUI: `/models` to pick your model, then `/triage` to scope the case (or
`/disk`, `/memory`, `/evtx`, … per evidence type), and `/verdict` to reason,
verify, and seal.

## How it loads

`bin/verdict-dfir` sets `OPENCODE_CONFIG` / `OPENCODE_CONFIG_DIR` to this repo's
`.opencode/` so the DFIR profile loads no matter which case directory you run in,
and exports `VERDICT_DFIR_HOME` so the MCP servers resolve. Nothing is written to
your case data — the agents run `edit`/`write` denied; the forensic tools are
read-only and hash every output.

## Layout

```
.opencode/
├── opencode.json          # provider (no default model) + MCP attach
├── agent/                 # verdict (primary) + pool-a/pool-b/verifier/judge/correlator
├── command/               # /triage /disk /memory /evtx /network /velociraptor /fleet /verdict
└── skill/verdict-dfir/    # investigation skill + reference doctrine (MEMORY/GROUNDING/JUDGING/EXPERT/TOOLS)
bin/verdict-dfir           # launcher
install.sh                 # prerequisite check
```

## Credits

The forensic doctrine and tool surface are VERDICT's
([verdict-dfir-community](https://github.com/TimothyVang/verdict-dfir-community),
Apache-2.0). The agent runtime is the
[verdict-opencode](https://github.com/TimothyVang/verdict-opencode) fork of
[opencode](https://github.com/sst/opencode) (MIT).
