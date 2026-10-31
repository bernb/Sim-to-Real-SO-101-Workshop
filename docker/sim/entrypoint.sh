#!/bin/bash
set -e

ISAAC_SIM=/workspace/isaaclab/_isaac_sim

export CARB_APP_PATH=$ISAAC_SIM/kit
export ISAAC_PATH=$ISAAC_SIM
export EXP_PATH=$ISAAC_SIM/apps
source ${ISAAC_SIM}/setup_python_env.sh
source /root/env 2>/dev/null

cat > /usr/local/bin/python << 'WRAPPER'
#!/bin/bash
exec /workspace/isaaclab/_isaac_sim/python.sh "$@"
WRAPPER
chmod +x /usr/local/bin/python

# Name host GIDs injected by the NVIDIA runtime (e.g. render) to silence "groups: cannot find name"
for gid in $(id -G); do
    getent group "$gid" >/dev/null || groupadd -g "$gid" "host_gid_$gid"
done

python -m pip install -q --root-user-action=ignore -e /workspace/Sim-to-Real-SO-101-Workshop/source/sim_to_real_so101/

exec "$@"
