#!/usr/bin/env python3
"""Render inventory-selected Terraform caller overlays locally; never push or apply."""
import argparse
import json
import subprocess
import sys
from pathlib import Path


def main():
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--inventory", type=Path, default=root / "repositories.json")
    parser.add_argument("--repository", required=True, help="inventory map key")
    parser.add_argument("--destination", required=True, type=Path)
    parser.add_argument("--module-source", type=Path, default=root.parent / "github-module",
                        help="reviewed local github-module checkout containing the renderer")
    args = parser.parse_args()
    inventory = json.loads(args.inventory.read_text())
    if inventory.get("schema_version") != 1:
        parser.error("expected inventory schema 1")
    repo = inventory.get("repositories", {}).get(args.repository)
    if repo is None:
        parser.error("repository key is absent from inventory")
    starter = repo.get("terraform_starter")
    if not isinstance(starter, dict) or set(starter) != {"terraform_version", "workflow_ref", "working_directory"}:
        parser.error("opt in with terraform_starter: terraform_version, workflow_ref, working_directory")
    if not all(isinstance(value, str) for value in starter.values()):
        parser.error("terraform_starter values must be strings")
    renderer = args.module_source / "scripts/render-template.py"
    result = subprocess.run([
        sys.executable, "-I", str(renderer), "--workflows-only",
        "--destination", str(args.destination),
        "--terraform-version", starter["terraform_version"],
        "--terraform-workflow-ref", starter["workflow_ref"],
        "--terraform-directory", starter["working_directory"],
    ], check=False)
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
