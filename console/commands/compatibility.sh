#!/usr/bin/env bash
set -euo pipefail

source "$COMPONENTS_DIR"/print_message.sh

print_table \
"
==============================================
|         SUPPORTED MAGENTO VERSIONS         |
==============================================
|         2.3.x       ||        2.4.x        |
----------------------------------------------
| 2.3.0    | 2.3.5    || 2.4.0    | 2.4.3-p1 |
| 2.3.1    | 2.3.5-p1 || 2.4.0-p1 | 2.4.3-p2 |
| 2.3.2    | 2.3.6    || 2.4.1    | 2.4.4    |
| 2.3.2-p2 | 2.3.6-p1 || 2.4.1-p1 | 2.4.5    |
| 2.3.3    | 2.3.7    || 2.4.2    | 2.4.5-p1 |
| 2.3.3-p1 | 2.3.7-p1 || 2.4.2-p1 |          |
| 2.3.4    | 2.3.7-p2 || 2.4.2-p2 |          |
| 2.3.4-p2 | 2.3.7-p3 || 2.4.3    |          |
----------------------------------------------
"