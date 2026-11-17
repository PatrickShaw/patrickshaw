#!/bin/bash
set -euo pipefail

battery_display_sleep_minutes=2
ac_display_sleep_minutes=60

pmset -b displaysleep "$battery_display_sleep_minutes"
pmset -c displaysleep "$ac_display_sleep_minutes"
