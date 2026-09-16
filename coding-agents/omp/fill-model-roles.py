"""Add absent wrapper defaults without replacing the user's model choices."""

import os
from pathlib import Path
import stat
import sys
import tempfile
from collections.abc import MutableMapping

from ruamel.yaml import YAML
from ruamel.yaml.comments import CommentedMap


def fill_roles(config, defaults):
    # Follow a user's config symlink rather than replacing it.
    config = config.resolve()
    yaml = YAML()
    yaml.preserve_quotes = True
    exists = config.exists()
    original = config.read_text() if exists else ""
    data = yaml.load(original)
    preamble = ""
    if data is None:
        data = CommentedMap()
        # A comments-only document has no YAML node to retain its comments.
        if all(not line.strip() or line.lstrip().startswith("#") for line in original.splitlines()):
            preamble = original
            if preamble and not preamble.endswith("\n"):
                preamble += "\n"
    if not isinstance(data, MutableMapping):
        raise ValueError("config must be a YAML mapping")
    if "modelRoles" not in data:
        data["modelRoles"] = {}
    roles = data["modelRoles"]
    if not isinstance(roles, MutableMapping):
        raise ValueError("modelRoles must be a YAML mapping")
    missing = {key: value for key, value in defaults.items() if key not in roles}
    if not missing:
        return
    roles.update(missing)
    config.parent.mkdir(parents=True, exist_ok=True)
    mode = stat.S_IMODE(config.stat().st_mode) if exists else 0o600
    fd, temporary = tempfile.mkstemp(prefix=".config-", dir=config.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(preamble)
            yaml.dump(data, stream)
            stream.flush()
            os.fchmod(stream.fileno(), mode)
        os.replace(temporary, config)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


if __name__ == "__main__":
    try:
        defaults = YAML(typ="safe").load(Path(sys.argv[2]))["modelRoles"]
        fill_roles(Path(sys.argv[1]), defaults)
    except Exception as error:
        sys.exit(f"omp: cannot fill model roles in {sys.argv[1]}: {error}")
