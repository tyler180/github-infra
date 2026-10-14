#!/usr/bin/env python3
"""Run pilot Terraform with existing CLI credentials, without printing tokens."""
import os
from pathlib import Path
import subprocess
import sys

if len(sys.argv) < 2 or sys.argv[1] not in {"init", "validate", "plan", "apply", "test", "output", "fmt", "show"}:
    raise SystemExit("Supply a Terraform command: init, validate, plan, apply, test, output, fmt, show")
environment = os.environ.copy()
if not environment.get("GITHUB_TOKEN"):
    environment["GITHUB_TOKEN"] = subprocess.check_output(["gh", "auth", "token"], text=True).strip()
result = subprocess.run(["terraform", *sys.argv[1:]],
    cwd=Path(__file__).resolve().parent / "example-go-pilot", env=environment, check=False)
raise SystemExit(result.returncode)
