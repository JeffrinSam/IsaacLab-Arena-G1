# Copyright (c) 2025, The Isaac Lab Arena Project Developers (https://github.com/isaac-sim/IsaacLab-Arena/blob/main/CONTRIBUTORS.md).
# All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0

# Import pinocchio from pin-pink BEFORE any other imports
# pin-pink installs pinocchio to cmeel.prefix, which has the Model attribute
# This must happen at module level to ensure it's loaded before Isaac Sim can interfere
import sys
pin_pink_pinocchio_path = "/isaac-sim/kit/python/lib/python3.11/site-packages/cmeel.prefix/lib/python3.11/site-packages"
# Remove from sys.path if already there, then insert at position 0 to ensure it's first
if pin_pink_pinocchio_path in sys.path:
    sys.path.remove(pin_pink_pinocchio_path)
sys.path.insert(0, pin_pink_pinocchio_path)
# Remove any existing pinocchio from sys.modules
modules_to_remove = [k for k in list(sys.modules.keys()) if k.startswith('pinocchio') or k == 'pin']
for mod_name in modules_to_remove:
    if mod_name in sys.modules:
        del sys.modules[mod_name]
# Now import pinocchio - it will use the pin-pink version with Model attribute
import pinocchio  # noqa: F401
pin = pinocchio
sys.modules['pinocchio'] = pinocchio
sys.modules['pin'] = pinocchio
# Verify immediately that we have the correct version
if not hasattr(pinocchio, 'Model'):
    raise RuntimeError(f"pinocchio does not have Model attribute! File: {pinocchio.__file__}, sys.path[0]: {sys.path[0]}")

import numpy as np
import random
import torch
import tqdm

from isaaclab_arena.cli.isaaclab_arena_cli import get_isaaclab_arena_cli_parser
from isaaclab_arena.examples.example_environments.cli import get_arena_builder_from_cli
from isaaclab_arena.examples.policy_runner_cli import create_policy, setup_policy_argument_parser
from isaaclab_arena.utils.isaaclab_utils.simulation_app import SimulationAppContext


def main():
    """Script to run an IsaacLab Arena environment with a zero-action agent."""
    args_parser = get_isaaclab_arena_cli_parser()
    # We do this as the parser is shared between the example environment and policy runner
    args_cli, unknown = args_parser.parse_known_args()

    # pinocchio is already imported at module level above
    # Verify we have the correct version before entering SimulationAppContext
    if not hasattr(pinocchio, 'Model'):
        raise RuntimeError(f"pinocchio does not have Model attribute! File: {pinocchio.__file__}")

    # Start the simulation app
    with SimulationAppContext(args_cli):
        # Add policy-related arguments to the parser
        args_parser = setup_policy_argument_parser(args_parser)
        args_cli = args_parser.parse_args()
        # Build scene
        arena_builder = get_arena_builder_from_cli(args_cli)
        env = arena_builder.make_registered()

        if args_cli.seed is not None:
            env.seed(args_cli.seed)
            torch.manual_seed(args_cli.seed)
            np.random.seed(args_cli.seed)
            random.seed(args_cli.seed)

        obs, _ = env.reset()

        # NOTE(xinjieyao, 2025-09-29): General rule of thumb is to have as many non-standard python
        # library imports after app launcher as possible, otherwise they will likely stall the sim
        # app. Given current SimulationAppContext setup, use lazy import to handle policy-related
        # deps inside create_policy() function to bringup sim app.
        policy, num_steps = create_policy(args_cli)
        # NOTE(xinjieyao, 2025-10-07): lazy import to prevent app stalling caused by omni.kit
        from isaaclab_arena.metrics.metrics import compute_metrics

        for _ in tqdm.tqdm(range(num_steps)):
            with torch.inference_mode():
                actions = policy.get_action(env, obs)
                obs, _, terminated, truncated, _ = env.step(actions)

                if terminated.any() or truncated.any():
                    # only reset policy for those envs that are terminated or truncated
                    print(
                        f"Resetting policy for terminated env_ids: {terminated.nonzero().flatten()}"
                        f" and truncated env_ids: {truncated.nonzero().flatten()}"
                    )
                    env_ids = (terminated | truncated).nonzero().flatten()
                    policy.reset(env_ids=env_ids)

        metrics = compute_metrics(env)
        print(f"Metrics: {metrics}")

        # Close the environment.
        env.close()


if __name__ == "__main__":
    main()
