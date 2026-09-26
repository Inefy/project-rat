# Game interface refresh

## Direction

A restrained survival-game interface: condensed display type, a readable sans-serif body, plain black menu backgrounds, neutral dark surfaces, warm off-white text, and a single amber action colour. The title keeps the original rat artwork against black.

## Hierarchy and interaction

- One primary action per menu. Secondary actions have visible surfaces and borders.
- Consistent 52 px buttons, 24 px HUD safe margins, and a limited type scale.
- Left-aligned upgrade descriptions, stable selection prompts, and clearly outlined keyboard/controller focus.
- Opaque-enough HUD panels separate text from moving scenery. Health uses a 24 px meter and large bold numbers. Its fill shifts from mint to amber below 60%, then red below 30%; low health also adds a red frame and a LOW HP label. Dash readiness is mint and wave progression is amber.
- Short notifications fade without overshoot. Temporary buffs use sentence case.
- Settings group sound/comfort and keyboard bindings. Scrollbars remain visible and follow keyboard focus.
- Demo presets show the selected wave; the reward summary explains the practice run without adding steps.

## References

- [Xbox Accessibility Guideline 101: Text display](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101)
- [Xbox Accessibility Guideline 102: Contrast](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/102)

These informed alignment, text backgrounds, contrast, and focus treatment; this refresh is not an accessibility certification.

## Fonts and artwork

Barlow Condensed SemiBold (headings), DM Sans (body), both under the bundled SIL Open Font License. `assets/ui/rat-portrait.png` copies the project's original Blender rat preview; no new external artwork is used.
