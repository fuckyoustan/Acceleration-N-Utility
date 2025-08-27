#!/system/bin/sh

while [ -z "$(getprop sys.boot_completed)" ]; do
    sleep 1
done


ANU() { [ -e "$1" ] && echo "$2" > "$1"; }
refresh_rate="$(dumpsys display | grep -Eo 'fps=[^.]+' | cut -f2 -d= | sort -n | uniq | tail -n1)"
[ -z "$refresh_rate" ] && refresh_rate=60
frame_time=$((1000000000/refresh_rate))
early_app_duration=$(awk -v ft="$frame_time" 'BEGIN {printf "%d", ft*1.968+1}')
early_sf_duration=$(awk -v ft="$frame_time" 'BEGIN {printf "%d", ft*1.512+1}')
early_gl_app_phase_offset=$(awk -v ft="$frame_time" 'BEGIN {printf "%d", -ft*1.968-1}')
early_phase_offset=$(awk -v ft="$frame_time" 'BEGIN {printf "%d", -ft*1.512-1}')
late_app_offset=$(awk -v ft="$frame_time" 'BEGIN {printf "%d", ft*0.1}')
late_sf_offset=$(awk -v ft="$frame_time" 'BEGIN {printf "%d", ft*0.2}')
total_ram="$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)"
cpu_cores=$(grep -c ^processor /proc/cpuinfo)

if [ "$total_ram" -le 3072 ]; then
    setprop dalvik.vm.heapstartsize 12m
    setprop dalvik.vm.heapgrowthlimit 128m
    setprop dalvik.vm.heapsize 384m
    setprop dalvik.vm.heapminfree 2m
    setprop dalvik.vm.heapmaxfree 8m
    setprop dalvik.vm.heaptargetutilization 0.75
elif [ "$total_ram" -le 4096 ]; then
    setprop dalvik.vm.heapstartsize 16m
    setprop dalvik.vm.heapgrowthlimit 192m
    setprop dalvik.vm.heapsize 512m
    setprop dalvik.vm.heapminfree 2m
    setprop dalvik.vm.heapmaxfree 8m
    setprop dalvik.vm.heaptargetutilization 0.75
elif [ "$total_ram" -le 6144 ]; then
    setprop dalvik.vm.heapstartsize 24m
    setprop dalvik.vm.heapgrowthlimit 256m
    setprop dalvik.vm.heapsize 768m
    setprop dalvik.vm.heapminfree 2m
    setprop dalvik.vm.heapmaxfree 8m
    setprop dalvik.vm.heaptargetutilization 0.8
elif [ "$total_ram" -le 8192 ]; then
    setprop dalvik.vm.heapstartsize 32m
    setprop dalvik.vm.heapgrowthlimit 384m
    setprop dalvik.vm.heapsize 1024m
    setprop dalvik.vm.heapminfree 2m
    setprop dalvik.vm.heapmaxfree 8m
    setprop dalvik.vm.heaptargetutilization 0.8
elif [ "$total_ram" -le 12288 ]; then
    setprop dalvik.vm.heapstartsize 48m
    setprop dalvik.vm.heapgrowthlimit 512m
    setprop dalvik.vm.heapsize 1536m
    setprop dalvik.vm.heapminfree 2m
    setprop dalvik.vm.heapmaxfree 8m
    setprop dalvik.vm.heaptargetutilization 0.85
else
    setprop dalvik.vm.heapstartsize 64m
    setprop dalvik.vm.heapgrowthlimit 768m
    setprop dalvik.vm.heapsize 2048m
    setprop dalvik.vm.heapminfree 2m
    setprop dalvik.vm.heapmaxfree 8m
    setprop dalvik.vm.heaptargetutilization 0.9
fi

if [ "$cpu_cores" -ge 8 ]; then
    setprop dalvik.vm.dex2oat-threads 8
    setprop dalvik.vm.image-dex2oat-threads 8
    setprop dalvik.vm.dex2oat-cpu-set 0-7
elif [ "$cpu_cores" -ge 6 ]; then
    setprop dalvik.vm.dex2oat-threads 6
    setprop dalvik.vm.image-dex2oat-threads 6
    setprop dalvik.vm.dex2oat-cpu-set 0-5
else
    setprop dalvik.vm.dex2oat-threads 4
    setprop dalvik.vm.image-dex2oat-threads 4
    setprop dalvik.vm.dex2oat-cpu-set 0-3
fi

setprop debug.sf.early.app.duration "$early_app_duration"
setprop debug.sf.earlyGl.app.duration "$early_app_duration"
setprop debug.sf.late.app.duration "$early_app_duration"
setprop debug.sf.early.sf.duration "$early_sf_duration"
setprop debug.sf.earlyGl.sf.duration "$early_sf_duration"
setprop debug.sf.late.sf.duration "$early_sf_duration"
setprop debug.sf.early_app_phase_offset_ns "$early_gl_app_phase_offset"
setprop debug.sf.high_fps_early_app_phase_offset_ns "$early_gl_app_phase_offset"
setprop debug.sf.high_fps_late_app_phase_offset_ns "$late_app_offset"
setprop debug.sf.early_gl_app_phase_offset_ns "$early_gl_app_phase_offset"
setprop debug.sf.early_phase_offset_ns "$early_phase_offset"
setprop debug.sf.high_fps_early_phase_offset_ns "$early_phase_offset"
setprop debug.sf.early_gl_phase_offset_ns "$early_phase_offset"
setprop debug.sf.high_fps_early_sf_phase_offset_ns "$early_phase_offset"
setprop debug.sf.high_fps_late_sf_phase_offset_ns "$late_sf_offset"
setprop debug.sf.frame_rate_multiple_threshold "$refresh_rate"
setprop debug.sf.use_phase_offsets_as_durations 1
setprop debug.sf.disable_client_composition_cache 1
setprop debug.sf.predict_hwc_composition_strategy 1
setprop debug.sf.log_expensive_rendering false
setprop debug.sf.no_vsyncs_on_screen_off true
setprop debug.sf.multithreaded_present true
setprop debug.sf.showupdates 0
setprop debug.sf.luma_sampling 0

setprop dalvik.vm.usejit true
setprop dalvik.vm.usejitprofiles true
setprop dalvik.vm.appimageformat lz4
setprop dalvik.vm.dexopt-flags m=y,o=y,u=n
setprop dalvik.vm.dex2oat-swap true
setprop dalvik.vm.dex2oat-filter everything
setprop dalvik.vm.systemuicompilerfilter everything
setprop dalvik.vm.systemservercompilerfilter everything
setprop pm.dexopt.bg-dexopt everything
setprop pm.dexopt.install everything
setprop pm.dexopt.shared everything
setprop pm.dexopt.cmdline everything

setprop persist.sys.ui.hw true
setprop debug.rs.max-threads 8
setprop touch.pressure.scale 0.001
setprop touch.size.scale 1.0

resetprop -n ro.surface_flinger.game_default_frame_rate_override "$refresh_rate"
resetprop -n ro.surface_flinger.use_context_priority true
resetprop -n ro.surface_flinger.start_graphics_allocator_service true
resetprop -n ro.surface_flinger.support_kernel_idle_timer false
resetprop -n ro.surface_flinger.clear_slots_with_set_layer_buffer true
resetprop -n ro.surface_flinger.enable_adpf_cpu_hint true
resetprop -n ro.surface_flinger.enable_present_time_offset true
resetprop -n ro.surface_flinger.enable_layer_caching true
resetprop -n ro.surface_flinger.uclamp.min 328
resetprop -n ro.surface_flinger.set_idle_timer_ms 80
resetprop -n ro.surface_flinger.set_touch_timer_ms 200
resetprop -n ro.surface_flinger.set_display_power_timer_ms 1000

resetprop -n ro.vendor.qti.sys.fw.bg_apps_limit 60
resetprop -n ro.sys.fw.bg_apps_limit 60
resetprop -n ro.input.noresample 1
resetprop -n ro.min_pointer_dur 1

settings put system pointer_speed 7
settings put secure multi_press_timeout 150
settings put secure long_press_timeout 150
settings put global block_untrusted_touches 0
settings put global window_animation_scale 0
settings put global transition_animation_scale 0
settings put global animator_duration_scale 0.2

ANU /dev/stune/top-app/schedtune.boost 95
ANU /dev/stune/top-app/schedtune.prefer_idle 1
ANU /dev/stune/foreground/schedtune.boost 60
ANU /dev/stune/foreground/schedtune.prefer_idle 1
ANU /dev/stune/schedtune.boost 0
ANU /dev/stune/schedtune.prefer_idle 0

ANU /sys/module/ged/parameters/gx_dfps "$refresh_rate"
ANU /sys/module/ged/parameters/gx_game_mode 1
ANU /sys/module/ged/parameters/boost_gpu_enable 1
ANU /sys/module/ged/parameters/enable_gpu_boost 1
ANU /sys/module/ged/parameters/enable_cpu_boost 1
ANU /sys/module/ged/parameters/boost_amp 1
ANU /sys/module/ged/parameters/boost_extra 1
ANU /sys/module/ged/parameters/ged_boost_enable 1

ANU /proc/mali/always_on 1
ANU /sys/class/misc/mali0/device/power_policy always_on
ANU /sys/devices/platform/13040000.mali/power_policy always_on

ANU /proc/sys/kernel/sched_boost 1
ANU /proc/sys/kernel/random/write_wakeup_threshold 256

KGSL=/sys/class/kgsl/kgsl-3d0
ANU "$KGSL/force_bus_on" 1
ANU "$KGSL/force_clk_on" 1
ANU "$KGSL/force_rail_on" 1

if [ -e "$KGSL/num_pwrlevels" ] && [ -e "$KGSL/min_pwrlevel" ]; then
  NPL=$(cat "$KGSL/num_pwrlevels" 2>/dev/null)
  if [ -n "$NPL" ] && [ "$NPL" -ge 3 ]; then ANU "$KGSL/min_pwrlevel" 2; fi
fi