set shell := ["bash", "-euo", "pipefail", "-c"]

# Full model is the SMP repair default. Override both parameters only for a
# bounded diagnostic, for example: just grok grok-4.7-build-fast low
# Routine edits need fewer prompts; terminal and protected-path requests still
# require supervision. Never type a new prompt into an active permission UI.
grok model="grok-4.7" effort="medium":
    grok --model "{{model}}" \
      --reasoning-effort "{{effort}}" \
      --permission-mode acceptEdits \
      --no-subagents --no-alt-screen --minimal

# Resume an exact conversation; --continue could select a different one.
grok-resume session model="grok-4.7" effort="medium":
    grok --resume "{{session}}" \
      --model "{{model}}" \
      --reasoning-effort "{{effort}}" \
      --permission-mode acceptEdits \
      --no-subagents --no-alt-screen --minimal

grok-sessions:
    grok sessions list

# Advisory wake-up only: no timeout here stops or changes the Grok process.
grok-wait session quiet_seconds="90":
    python3 src/gambit_smp/grok_event_wait.py "{{session}}" \
      --quiet-seconds "{{quiet_seconds}}"
