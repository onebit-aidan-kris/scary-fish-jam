# godot-start

My rather opinionated Godot project template.

To start a project with this template, run:
```
./init-template.sh new_project_name
```

## AI Use

This project does not contain the output of Generative AI, and is tagged `no-ai` following the
[itch.io AI disclosure guidelines](https://itch.io/docs/creators/quality-guidelines#ai-disclosure)

This is to allow projects using this template to publish under a no-AI policy.
If AI is used in derivative projects, that project must remove this section.

## Features

Batteries included. Delete what you don't want.

- Safe serialization/deserialization framework
- Quicksave (hotkey `[`) and Quickload (hotkey `]`)
- Player input replay system
- Pause menu
- Palette and dither screen shaders
- Cross-platform nix build
- CI checks and release upload to itch.io

## Development

### Nix

A nix env is provided, but is optional.

Update dependencies
```
nix flake update
```

Start nix dev shell
```
nix develop
```

### Shell Utils

See
```
./scripts/bld --help
./scripts/format --help
./scripts/test-headless --help
```

### Git Hooks

Add recommended git hooks with:
```
./scripts/add-git-hooks
```

## Publish to itch.io

To enable butler uploads in CI:

1. [Login to butler and get your API key](https://itch.io/docs/butler/login.html)
2. Create a "butler" [environment](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets)
   and add your API key and TARGET. e.g.
  - secret: BUTLER_API_KEY=...
  - env var: BUTLER_TARGET=<itch-account>/godot-start

## TODO

- Detect mouse un-capture in browser so Escape key pauses game (requires html/js)
- Capture ctrl+key input in browser (to prevent ctrl+w from closing tab, requires html/js)
- Fix home-manager setup / support nixGL
  (see [1](https://github.com/NixOS/nixpkgs/issues/336400), [2](https://github.com/nix-community/home-manager/issues/3968))
