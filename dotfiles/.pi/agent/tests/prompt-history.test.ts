import assert from "node:assert/strict";
import test from "node:test";
import { collapseExpandedSkillPrompt } from "../extensions/save-cleared-prompts.ts";

function skillBlock(name: string, body = `Instructions for ${name}.`): string {
  return `<skill name="${name}" location="/skills/${name}/SKILL.md">
References are relative to /skills/${name}.

${body}
</skill>`;
}

test("leaves ordinary prompts unchanged", () => {
  assert.equal(
    collapseExpandedSkillPrompt("fix the history"),
    "fix the history",
  );
});

test("restores a slash skill without arguments", () => {
  assert.equal(
    collapseExpandedSkillPrompt(skillBlock("research")),
    "/skill:research",
  );
});

test("restores a slash skill and its arguments", () => {
  assert.equal(
    collapseExpandedSkillPrompt(
      `${skillBlock("research")}\n\ncompare these APIs`,
    ),
    "/skill:research compare these APIs",
  );
});

test("removes expansion while preserving a dollar skill prompt", () => {
  assert.equal(
    collapseExpandedSkillPrompt(
      `${skillBlock("research")}\n\n$research compare these APIs`,
    ),
    "$research compare these APIs",
  );
});

test("preserves dollar mentions that occur later in the prompt", () => {
  assert.equal(
    collapseExpandedSkillPrompt(
      `${skillBlock("research")}\n\ncompare these APIs with $research`,
    ),
    "compare these APIs with $research",
  );
});

test("removes every expansion from a multi-skill dollar prompt", () => {
  const expanded = `${skillBlock("research")}\n\n${skillBlock("frontend-design")}\n\nuse $research and $frontend-design`;
  assert.equal(
    collapseExpandedSkillPrompt(expanded),
    "use $research and $frontend-design",
  );
});

test("leaves malformed expansion text unchanged", () => {
  const malformed =
    '<skill name="research" location="/skills/research/SKILL.md">\nbody';
  assert.equal(collapseExpandedSkillPrompt(malformed), malformed);
});
