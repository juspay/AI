{
  # Init script that symlinks bundled skills into ~/.claude/skills/
  mkSkillsInitScript = skillsSrc: ''
    skills_dir="$HOME/.claude/skills"
    mkdir -p "$skills_dir"
    for skill in ${skillsSrc}/skills/*/; do
      skill_name=$(basename "$skill")
      target="$skills_dir/$skill_name"
      # Always update symlink to point to current nix store path
      if [ -L "$target" ]; then
        rm "$target"
      fi
      if [ ! -e "$target" ]; then
        ln -s "$skill" "$target"
      fi
    done
  '';
}
