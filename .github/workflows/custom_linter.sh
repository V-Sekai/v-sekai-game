#!/bin/bash
set -e

# Exclude files/directories with regex
EXCLUDE="./addons/vrm/.*
"

# Start
PATTERNS=''
while IFS= read -r line; do
    PATTERNS="${PATTERNS}${line}|"
done <<< ${EXCLUDE:0:-1}
PATTERNS="${PATTERNS:0:-1}"

echo "Linter: Starting custom linter...";
match_error=false;

echo -e "Exclusion Pattern: $PATTERNS\n"

# Decision https://github.com/V-Sekai/v-sekai-game/issues/474#issuecomment-2603661420
# Forbid assert() for game code. Usage in third-party addons is allowed after review of side-effects.
matches=$( bash -c "find . -type f -regextype egrep -name '*.gd' -and -not -regex \"${PATTERNS}\" -exec grep -nH 'assert(' {} \;" )
if [ -n "$matches" ]; then
    echo 'Linter: "assert()" usage is forbidden (assert checks are skipped in release versions causing potential undefined behaviour)';
    echo 'Linter: use constructs like "if not ...: push_error(...); return" instead';
    echo -e "$matches\n\n";
    match_error=true;
fi

# Decision https://github.com/V-Sekai/v-sekai-game/issues/475#issue-2802564439
# Forbid printerr()
matches=$( bash -c "find . -type f -regextype egrep -name '*.gd' -and -not -regex \"${PATTERNS}\" -exec grep -nH 'printerr(' {} \;" )
if [ -n "$matches" ]; then
    echo 'Linter: "printerr()" usage is forbidden (error output won'\''t be shown in Godot Debug panel)';
    echo 'Linter: use "push_error()" instead';
    echo -e "$matches\n\n";
    match_error=true;
fi

if [ "$match_error" == 'true' ]; then
    echo 'Linter: Solve errors and run again';
    exit 1;
else
    echo "Linter: All checks passed!"
fi
