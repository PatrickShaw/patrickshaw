#!/usr/bin/env fish

function runExecute
  set DATA $(upower --show-info $(upower -e | grep battery))
  set ICON $(echo $DATA | grep icon-name | sd '^[^\']+' '' | sd '\'' '')
  set PERCENTAGE $(upower --show-info $(upower -e | grep battery) | grep percentage | sd '[^\d]+' '$1')

  echo "{ \"icon\": \"$ICON\", \"percentage\": $PERCENTAGE }"
end

if type -q upower
  runExecute
  upower --monitor-detail $(upower -e | grep battery) | while read -r line
    runExecute
  end
end

