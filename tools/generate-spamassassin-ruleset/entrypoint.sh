#!/usr/bin/env bash
set -euo pipefail
/usr/bin/vendor_perl/sa-update --allowplugins
/usr/bin/vendor_perl/sa-compile
