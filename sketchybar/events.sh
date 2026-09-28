#!/usr/bin/env bash

# Register custom events before any item subscribes to them. Native events,
# including space_windows_change, must not be re-registered here.
sketchybar --add event yabai_window_change
sketchybar --add event alfred_trigger
sketchybar --add event update_yabai_icon
sketchybar --add event network_location_changed
sketchybar --add event focus_on  "_NSDoNotDisturbEnabledNotification"
sketchybar --add event focus_off "_NSDoNotDisturbDisabledNotification"
