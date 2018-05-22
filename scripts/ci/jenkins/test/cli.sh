# CLI tests

# Fail if any command exits non-zero
set -e

function execute {
  echo "$(tput setaf 6)EXEC: $1 $(tput sgr0)"
  $1
}

execute "$RBENV_EXEC bundle exec run-loop version"
execute "$RBENV_EXEC bundle exec run-loop help"
execute "$RBENV_EXEC bundle exec run-loop instruments help"
execute "$RBENV_EXEC bundle exec run-loop simctl help"
execute "$RBENV_EXEC bundle exec run-loop codesign help"
execute "$RBENV_EXEC bundle exec run-loop codesign info spec/resources/CalSmoke.ipa"
