---
name: add-dialogue-entry
description: Add dialogue entry to a character or event in a scene. Guides through questionnaire to gather naming conventions, character references, and state management, then wires up JSON file, scene node, and state script together. Use when adding new dialogue to a character, setting up dialogue for an NPC, or when asked to "add dialogue to [character]".
---

# Add Dialogue Entry to Character

Complete workflow for adding dialogue to a character in a level scene. This skill ensures all three components (JSON file, scene node, state script) are wired together correctly without naming collisions or missing dependencies.

## Quick Start

When you want to add dialogue:

1. **Explicitly invoke** this skill:
   ```
   /add-dialogue-entry
   ```

2. **Or use naturally** while working with dialogue files — the rule will trigger automatically.

## Questionnaire

Before making any changes, I'll ask:

1. **Character name** — Code identifier (e.g. `brad`, `walsh`, `jeff`)
2. **Character node** — Scene tree node name (e.g. `HumanC`, `CapnWalsh`)
3. **Level and state script** — Which level? Which state script? (e.g. `town_level.tscn` / `town_state.gd`)
4. **Trigger type** — `"interacted"` (player clicks character) or `auto_start` (fires automatically)?
5. **After-callback method** — Method name called after intro event (e.g. `met_brad`) — **NOT a condition property name**
6. **Condition variable** — Bool property for "already seen" check (e.g. `has_met_brad`) — **NOT a method name**

### Naming Conventions

Follow existing patterns in the state script. Compare Walsh:
- After callback: `met_walsh()` (method)
- Condition: `has_met_walsh` (property, `@export var ... := false`)

Brad should follow the same:
- After callback: `met_brad()` (method)
- Condition: `has_met_brad` (property, `@export var ... := false`)

**Critical**: Condition names and callback method names MUST be distinct. The dialogue system checks `has_method()` first — if both exist, it calls the method instead of reading the property.

## Implementation Steps

Once answers are gathered, I'll:

### 1. Create/update dialogue JSON
- Ensure `"events"` top-level wrapper
- Create `"start"` event (entry point)
- Add `"intro"` with sequence and after-callback
- Add `"has_met"` with condition variable
- Wire callback args like `["$character", "$player"]`

### 2. Add/wire DialogueEntry in scene
- Create `DialogueEntry` node under character
- Set `json_path`, `parent_signal_trigger` (or `auto_start`)
- Set `state` export to point to level state node
- Add character name to state node's `node_paths` array

### 3. Update level state script
- Add `@export var <character>: HumanCharacter`
- Add `assert(<character>)` in `_ready()`
- Add `@export var <condition_var> := false`
- Add `func <after_callback>():` method
- Wire `NodePath` in scene file

### 4. Verify (MANDATORY — do not skip)

After all changes, cross-reference the JSON against the state script:

1. Every `"name"` in `"before"`/`"callback"`/`"after"` objects -> must have a **method** in state script
2. Every string in `"conds"` arrays -> must have a **bool property** (not method) in state script
3. Every `$arg` in callback args -> must have an `@export var` in state script
4. No method name matches any condition property name

Read both files and verify all four before considering the task done.

## Common Mistakes

- Forgetting `"events"` wrapper in JSON (deserialization error)
- Forgetting `state` export on DialogueEntry (null callback error)
- Using `$name` in JSON args without state script property (null error)
- **Naming method same as condition variable** (condition silently calls method instead of reading bool)
- Forgetting to add condition bool property to state script
- **Adding the condition property but not the after-callback method, or vice versa**

## How to Invoke

**Option 1 — Slash command (explicit):**
```
/add-dialogue-entry
```

Invoke anytime, regardless of which files are open.

**Option 2 — Natural request (automatic rule):**
While you have dialogue JSON, scene `.tscn`, or state script open:
```
Add dialogue to Brad
```

The rule triggers automatically and I'll follow this workflow.

## References

For detailed setup requirements, see `.cursor/rules/dialogue-entry-setup.mdc` in this project.
