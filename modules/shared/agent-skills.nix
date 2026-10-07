# Agent skills, pinned through flake inputs and built into one store path
# with agent-skills-nix. Bump them with `nix flake update mattpocock-skills`.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.agentSkills;
  skillsLib = inputs.agent-skills.lib.agent-skills;

  sources = {
    mattpocock = {
      path = inputs.mattpocock-skills;
      subdir = "skills";
    };
    cursor = {
      path = inputs.cursor-plugins;
      subdir = "cursor-team-kit/skills";
    };
    impeccable-rust = {
      path = inputs.impeccable-rust;
      subdir = ".";
    };
  };

  fromDir =
    from: dir: names:
    lib.genAttrs names (name: {
      inherit from;
      path = "${dir}/${name}";
    });

  skills =
    fromDir "mattpocock" "engineering" [
      "ask-matt"
      "code-review"
      "codebase-design"
      "diagnosing-bugs"
      "domain-modeling"
      "grill-with-docs"
      "implement"
      "implement-spec"
      "improve-codebase-architecture"
      "pr"
      "prototype"
      "research"
      "retro"
      "setup-matt-pocock-skills"
      "tdd"
      "to-spec"
      "to-tickets"
      "triage"
      "wayfinder"
      "wizard"
    ]
    // fromDir "mattpocock" "productivity" [
      "grill-me"
      "grilling"
      "handoff"
      "teach"
      "to-questionnaire"
      "wait-what"
      "writing-for-agents"
    ]
    // fromDir "mattpocock" "in-progress" [
      "writing-beats"
      "writing-fragments"
      "writing-shape"
    ]
    // fromDir "cursor" "." [ "deslop" ]
    // {
      impeccable-rust = {
        from = "impeccable-rust";
        path = "skill";
      };
    };

  bundle = skillsLib.mkBundle {
    inherit pkgs;
    selection = skillsLib.selectSkills {
      catalog = skillsLib.discoverCatalog sources;
      inherit sources skills;
    };
  };
in
{
  options.agentSkills = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "User whose home receives the agent skills.";
    };
    home = lib.mkOption {
      type = lib.types.str;
      description = "Home directory of agentSkills.user.";
    };
  };

  config.systemd.tmpfiles.rules = [
    # Parents may not exist on a fresh install; keep them owned by the user.
    "d ${cfg.home}/.agents - ${cfg.user} - -"
    "d ${cfg.home}/.claude - ${cfg.user} - -"
    "d ${cfg.home}/.claude/skills - ${cfg.user} - -"
    "L+ ${cfg.home}/.agents/skills - - - - ${bundle}"
  ]
  # Claude Code writes its own synced skills into ~/.claude/skills, so link
  # each skill instead of replacing the directory.
  ++ map (name: "L+ ${cfg.home}/.claude/skills/${name} - - - - ${bundle}/${name}") (
    lib.attrNames skills
  );
}
