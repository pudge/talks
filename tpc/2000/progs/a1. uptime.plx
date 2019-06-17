#!perl -w
use Mac::Events;
$ticks   = TickCount();
$days    = $ticks / 5184000;
$hours   = ($days    - int($days))    * 24;
$minutes = ($hours   - int($hours))   * 60;
$seconds = ($minutes - int($minutes)) * 60;

printf "Computer (maybe) started up at %s\n",
  scalar localtime(time - ($ticks / 60));
printf "Computer has been running for %d days, %.2d:%.2d:%.2d\n",
  $days, $hours, $minutes, $seconds;
