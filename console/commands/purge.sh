#!/usr/bin/env bash
set -euo pipefail

"$COMMANDS_DIR"/exec.sh sh -c "rm -rf \
    var/cache/* \
    generated/* \
    pub/static/* \
    var/view_preprocessed/* \
    var/page_cache/* \
    var/generation/* \
    dev/tests/integration/tmp/*"