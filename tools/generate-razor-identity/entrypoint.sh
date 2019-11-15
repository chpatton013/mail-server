#!/usr/bin/env bash
set -euo pipefail
/usr/bin/vendor_perl/razor-admin -home=/var/lib/spamassassin/razor -register
/usr/bin/vendor_perl/razor-admin -home=/var/lib/spamassassin/razor -create
/usr/bin/vendor_perl/razor-admin -home=/var/lib/spamassassin/razor -discover
