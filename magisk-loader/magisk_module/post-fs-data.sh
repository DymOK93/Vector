#
# This file is part of LSPosed.
#
# LSPosed is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# LSPosed is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with LSPosed.  If not, see <https://www.gnu.org/licenses/>.
#
# Copyright (C) 2021 LSPosed Contributors
#

MODDIR=${0%/*}

cd "$MODDIR"

klog() { echo "LSPosed-barrier: $1" > /dev/kmsg 2>/dev/null; }
t0=$(cut -d' ' -f1 /proc/uptime)

# @JingMatrix: To avoid delaying the normal mount timing of zygote, we start LSPosed service daemon in late_start service mode instead of post-fs-data mode
# @DymOK: To prevent a race condition with zygote-start trigger, we start LSPosed service daemon in post-fs-data mode instead of late_start service mode 
# https://source.android.com/docs/core/perf/boot-times#starting-zygote-early
unshare --propagation slave -m sh -c "$MODDIR/daemon --system-server-max-retry=3 $@&"

# @DymOK: Wait for "serial" service start
i=0
while [ $i -lt 75 ]; do
    case "$(service check serial 2>/dev/null)" in
        *"not found"*) ;;
        "Service serial:"*) break ;;
    esac
    sleep 0.1
    i=$((i + 1))
done
t1=$(cut -d' ' -f1 /proc/uptime)

if [ $i -ge 75 ]; then
    klog "TIMEOUT waiting for lspd, uptime ${t0} -> ${t1}, continuing unbarriered"
else
    klog "lspd ready, uptime ${t0} -> ${t1} (${i} polls)"
fi
