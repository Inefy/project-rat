# Contributing to Project R.A.T.

Thanks for helping the rat survive another wave.

1. Fork the repository and branch from `main`.
2. Keep changes compatible with Godot 4.7.2 and the Compatibility renderer.
3. Avoid platform-specific APIs unless they are guarded with a web-safe fallback.
4. Run `godot --headless --path . --script tests/smoke_test.gd`.
5. If you change rendering or UI, also create a local web export and test it in a browser.
6. Open a pull request describing the player-facing result and how it was tested.

Bug reports should include the browser or operating system, reproduction steps, expected behavior, and any Godot console output.

