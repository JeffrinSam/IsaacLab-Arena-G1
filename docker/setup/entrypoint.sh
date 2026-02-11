#!/bin/bash

# This script is used as entrypoint for the docker container.
# It will setup an user account for the host user inside the docker
# s.t. created files will have correct ownership.

# Exit on error
set -euo pipefail

# Make sure that all shared libs are found. This should normally not be needed, but resolves a
# problem with the opencv installation. For unknown reasons, the command doesn't bite if placed
# at the end of the dockerfile
ldconfig

# Add the group of the user. User/group ID of the host user are set through env variables when calling docker run further down.
groupadd --force --gid "$DOCKER_RUN_GROUP_ID" "$DOCKER_RUN_GROUP_NAME"

# Re-add the user
userdel "$DOCKER_RUN_USER_NAME" 2>/dev/null || true
userdel ubuntu || true
useradd --no-log-init \
        --uid "$DOCKER_RUN_USER_ID" \
        --gid "$DOCKER_RUN_GROUP_NAME" \
        --groups sudo \
        --shell /bin/bash \
        $DOCKER_RUN_USER_NAME
chown $DOCKER_RUN_USER_NAME:$DOCKER_RUN_GROUP_NAME /home/$DOCKER_RUN_USER_NAME
chown $DOCKER_RUN_USER_NAME:$DOCKER_RUN_GROUP_NAME $WORKDIR

# Change the root user password (so we can su root)
echo 'root:root' | chpasswd
echo "$DOCKER_RUN_USER_NAME:root" | chpasswd

# Allow sudo without password
echo "$DOCKER_RUN_USER_NAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Suppress sudo hint message
touch /home/$DOCKER_RUN_USER_NAME/.sudo_as_admin_successful

cp /etc/bash.bashrc /home/$DOCKER_RUN_USER_NAME/.bashrc
chown $DOCKER_RUN_USER_NAME:$DOCKER_RUN_GROUP_NAME /home/$DOCKER_RUN_USER_NAME/.bashrc

# Ensure PYTHONPATH is set for IsaacLab modules in user's bashrc
if [ -n "${ISAACLAB_PATH:-}" ]; then
    echo "" >> /home/$DOCKER_RUN_USER_NAME/.bashrc
    echo "# IsaacLab Python path setup" >> /home/$DOCKER_RUN_USER_NAME/.bashrc
    echo "export ISAACLAB_PATH=${ISAACLAB_PATH}" >> /home/$DOCKER_RUN_USER_NAME/.bashrc
    echo "export PYTHONPATH=\${ISAACLAB_PATH}/source/isaaclab:\${ISAACLAB_PATH}/source/isaaclab_assets:\${ISAACLAB_PATH}/source/isaaclab_mimic:\${ISAACLAB_PATH}/source/isaaclab_rl:\${ISAACLAB_PATH}/source/isaaclab_tasks:\${PYTHONPATH:-}" >> /home/$DOCKER_RUN_USER_NAME/.bashrc
fi

# Add the models, datasets, and eval folders if they don't exist
mkdir -p /datasets /models /eval
chown $DOCKER_RUN_USER_NAME:$DOCKER_RUN_GROUP_NAME /datasets /models /eval

# Run the passed command or just start the shell as the created user
if [ $# -ge 1 ]; then
    # Fix typo: was /etc/aliasess.bashrc, should be /etc/bash.bashrc
    echo "alias pytest='/isaac-sim/python.sh -m pytest'" >> /etc/bash.bashrc
    # Ensure ISAACLAB_PATH is set for the user
    echo "export ISAACLAB_PATH=${ISAACLAB_PATH}" >> /home/$DOCKER_RUN_USER_NAME/.bashrc
    # Add IsaacLab source directories to PYTHONPATH so packages are found
    echo "export PYTHONPATH=\${PYTHONPATH:+\${PYTHONPATH}:}\${ISAACLAB_PATH}/source/isaaclab:\${ISAACLAB_PATH}/source/isaaclab_assets:\${ISAACLAB_PATH}/source/isaaclab_mimic:\${ISAACLAB_PATH}/source/isaaclab_rl:\${ISAACLAB_PATH}/source/isaaclab_tasks" >> /home/$DOCKER_RUN_USER_NAME/.bashrc
    # Use bash -c with proper environment setup for non-interactive mode
    # Source bashrc to get aliases and environment variables
    # Note: We use exec to replace the current process, but we need to ensure
    # the command is properly executed. For non-interactive shells, we use -c instead of -ic
    exec sudo --preserve-env -u $DOCKER_RUN_USER_NAME \
        -- env HOME=/home/$DOCKER_RUN_USER_NAME \
           ISAACLAB_PATH=${ISAACLAB_PATH} \
           WORKDIR=${WORKDIR} \
           PYTHONPATH=${ISAACLAB_PATH}/source/isaaclab:${ISAACLAB_PATH}/source/isaaclab_assets:${ISAACLAB_PATH}/source/isaaclab_mimic:${ISAACLAB_PATH}/source/isaaclab_rl:${ISAACLAB_PATH}/source/isaaclab_tasks:${PYTHONPATH:-} \
           bash -c "source /etc/bash.bashrc 2>/dev/null || true; source /home/$DOCKER_RUN_USER_NAME/.bashrc 2>/dev/null || true; $@"
else
    su $DOCKER_RUN_USER_NAME
fi

exit
