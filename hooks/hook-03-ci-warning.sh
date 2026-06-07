#!/usr/bin/env bash
# Hook 3: CI file warning

echo "⚠️  You are editing a CI/CD configuration file. This affects all developers. Be conservative, verify the change won't break the pipeline, and confirm the target environment before proceeding."
exit 0
