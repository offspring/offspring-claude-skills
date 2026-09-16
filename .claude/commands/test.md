---
description: Run the plugin's static checks; add "eval" to also run the behavioral eval suite
argument-hint: [eval]
allowed-tools: ["Bash(./scripts/check.sh)", "Bash(./scripts/eval.sh *)"]
model: haiku
---

# Test the plugin

Run `./scripts/check.sh`. Report each FAIL line verbatim; if it passes, say so in one line.

If `$ARGUMENTS` contains `eval`, also run `./scripts/eval.sh` (calls the model, costs usage) and report its summary table and report path.
