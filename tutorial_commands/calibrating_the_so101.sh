#!/usr/bin/env bash
# Tutorial section: "# Calibrating the SO-101"
#
# Starts the Teleop & Simulation container (teleop-docker:latest).
# Build it first from the repo root:  docker build -t teleop-docker -f docker/sim/Dockerfile .
#
# Usage (from anywhere):
#   ./tutorial_commands/calibrating_the_so101.sh            # interactive shell
#   ./tutorial_commands/calibrating_the_so101.sh <command>  # run a command instead
#
# Inside the container (ports/IDs come from docker/env):
#   lerobot-calibrate --teleop.type=so101_leader --teleop.port=$TELEOP_PORT --teleop.id=$TELEOP_ID
#   lerobot-calibrate --robot.type=so101_follower --robot.port=$ROBOT_PORT --robot.id=$ROBOT_ID
#   lerobot-teleoperate \
#       --robot.type=so101_follower --robot.port=$ROBOT_PORT --robot.id=$ROBOT_ID \
#       --teleop.type=so101_leader --teleop.port=$TELEOP_PORT --teleop.id=$TELEOP_ID
#
# Requires the NVIDIA Container Toolkit with the "nvidia" Docker runtime registered
# (`sudo nvidia-ctk runtime configure --runtime=docker`; already done by the Docker snap).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WS=/workspace/Sim-to-Real-SO-101-Workshop
CACHE="$HOME/docker/isaac-sim"
CALIB="$HOME/.cache/huggingface/lerobot/calibration"

# Pre-create host dirs so Docker doesn't create them as root-owned.
mkdir -p "$CACHE"/cache/{kit,ov,pip,glcache,computecache} "$CACHE"/{logs,data,documents} \
         "$CALIB" "$REPO_ROOT"/{outputs,datasets}

X11_ARGS=()
if [[ -n "${DISPLAY:-}" ]]; then
    # Allow only local root (the container user) to connect, instead of `xhost +`.
    xhost +SI:localuser:root >/dev/null 2>&1 || echo "warning: xhost failed; GUI apps may not open" >&2
    X11_ARGS+=(-e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix:rw)
    XAUTH="${XAUTHORITY:-$HOME/.Xauthority}"
    if [[ -f "$XAUTH" ]]; then
        X11_ARGS+=(-e XAUTHORITY=/root/.Xauthority -v "$XAUTH":/root/.Xauthority:ro)
    fi
fi

TTY_ARGS=(-i)
[[ -t 0 && -t 1 ]] && TTY_ARGS+=(-t)

exec docker run --name teleop "${TTY_ARGS[@]}" --rm \
    --privileged --network=host \
    --runtime=nvidia --gpus all \
    -e "ACCEPT_EULA=Y" -e "PRIVACY_CONSENT=Y" \
    "${X11_ARGS[@]}" \
    -v /dev:/dev \
    -v /run/udev:/run/udev:ro \
    -v "$CACHE"/cache/kit:/isaac-sim/kit/cache:rw \
    -v "$CACHE"/cache/ov:/root/.cache/ov:rw \
    -v "$CACHE"/cache/pip:/root/.cache/pip:rw \
    -v "$CACHE"/cache/glcache:/root/.cache/nvidia/GLCache:rw \
    -v "$CACHE"/cache/computecache:/root/.nv/ComputeCache:rw \
    -v "$CACHE"/logs:/root/.nvidia-omniverse/logs:rw \
    -v "$CACHE"/data:/root/.local/share/ov/data:rw \
    -v "$CACHE"/documents:/root/Documents:rw \
    -v "$CALIB":/root/.cache/huggingface/lerobot/calibration:rw \
    -v "$REPO_ROOT"/docker/env:/root/env:ro \
    -v "$REPO_ROOT"/source:$WS/source \
    -v "$REPO_ROOT"/outputs:$WS/outputs \
    -v "$REPO_ROOT"/datasets:$WS/datasets \
    -v "$REPO_ROOT"/docker/real/scripts:$WS/docker/real/scripts \
    teleop-docker:latest "${@:-bash}"
