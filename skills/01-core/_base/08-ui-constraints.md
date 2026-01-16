---
name: makepad-ui-constraints
author: robius
source: adapted from web UI skills
date: 2026-01-12
tags: [ui, design, constraints, best-practices, opinionated]
level: intermediate
---

# Makepad UI Constraints

Opinionated constraints for building better interfaces with Makepad and AI agents.

## Theme & Styling

| Rule | Constraint |
|------|------------|
| MUST | Use `link::theme::*` defaults before custom values |
| MUST | Use theme tokens (`THEME_COLOR_*`, `THEME_FONT_*`) before hardcoded values |
| SHOULD | Define custom colors in a centralized theme file, not inline |
| NEVER | Use hex colors ending with `e` (parsed as scientific notation) |
| MUST | Use `text_style: <THEME_FONT_*>{}` for fonts, never raw `font:` property |

```rust
// GOOD - use theme tokens
draw_bg: { color: (THEME_COLOR_BG_APP) }
draw_text: { text_style: <THEME_FONT_REGULAR>{} }

// BAD - hardcoded values
draw_bg: { color: #1a1a2e }
draw_text: { font: "my-font.ttf" }  // Error: no matching field
```

## Components

| Rule | Constraint |
|------|------------|
| MUST | Use project's existing widget primitives first |
| MUST | Use built-in widgets (`Button`, `Label`, `TextInput`) before custom implementations |
| NEVER | Rebuild focus/keyboard behavior by hand unless explicitly requested |
| MUST | Add `tooltip` or descriptive `text` for icon-only buttons |
| SHOULD | Prefer `RoundedView` over raw `View` when borders/radius needed |
| NEVER | Mix different widget systems in same interaction surface |

```rust
// GOOD - use built-in with customization
<Button> {
    text: ""
    draw_icon: { svg_file: (ICON_SETTINGS) }
    tooltip: "Settings"  // Accessibility
}

// BAD - rebuilding button behavior
<View> {
    // Manual click handling...
}
```

## Layout

| Rule | Constraint |
|------|------------|
| MUST | Use `flow: Down` or `flow: Right` for primary layout direction |
| MUST | Use `align: {x: 0.5, y: 0.5}` for centering, not manual padding |
| SHOULD | Use `spacing:` for consistent gaps instead of margin on each child |
| NEVER | Use `abs_pos` unless building overlays/popups |
| MUST | Use `Fill` or `Fit` sizing, avoid fixed pixel sizes when possible |
| SHOULD | Use `walk: {width: Fill, height: Fit}` as default starting point |

```rust
// GOOD - semantic layout
<View> {
    flow: Down
    spacing: 10
    align: {x: 0.5, y: 0.0}

    <Label> { text: "Title" }
    <Label> { text: "Subtitle" }
}

// BAD - manual positioning
<View> {
    <Label> { margin: {top: 10, bottom: 10} }
    <Label> { margin: {top: 10} }
}
```

## Animation

| Rule | Constraint |
|------|------------|
| NEVER | Add animation unless explicitly requested |
| MUST | Use `animator:` system, never manual state interpolation |
| MUST | Use `redraw: true` in animator for auto-refresh during animation |
| SHOULD | Use `ease: ExpDecay` for natural motion feel |
| NEVER | Exceed 300ms for interaction feedback animations |
| MUST | Animate only GPU-friendly properties (opacity, draw_bg colors) |
| NEVER | Animate layout properties (width, height, margin, padding) in tight loops |
| SHOULD | Use `Forward` timing for entrances, `Snap` for immediate state changes |

```rust
// GOOD - animator-driven
animator: {
    hover = {
        default: off
        on = {
            redraw: true
            from: {all: Forward {duration: 0.15}}
            apply: { draw_bg: {color: #3a3a4a} }
        }
        off = {
            from: {all: Forward {duration: 0.1}}
            apply: { draw_bg: {color: #2a2a38} }
        }
    }
}

// BAD - manual interpolation in handle_event
```

## Interaction

| Rule | Constraint |
|------|------------|
| MUST | Use `DefaultKey` action handling for keyboard shortcuts |
| MUST | Show errors adjacent to triggering element, not global toast |
| SHOULD | Use `FingerHoverIn` + `FingerHoverOver` together for tooltips |
| NEVER | Block paste in `TextInput` elements |
| MUST | Call `redraw(cx)` after any visual state change |
| MUST | Handle both `Hit::FingerDown` and `Hit::FingerUp` for button-like behavior |

```rust
// GOOD - complete interaction handling
match event.hits(cx, self.draw_bg.area()) {
    Hit::FingerHoverIn(_) | Hit::FingerHoverOver(_) => {
        self.animator_play(cx, ids!(hover.on));
    }
    Hit::FingerHoverOut(_) => {
        self.animator_play(cx, ids!(hover.off));
    }
    Hit::FingerDown(_) => {
        self.animator_play(cx, ids!(pressed.on));
    }
    Hit::FingerUp(f) => {
        if f.is_over {
            // Trigger action
        }
        self.animator_play(cx, ids!(pressed.off));
    }
    _ => {}
}
```

## Typography

| Rule | Constraint |
|------|------------|
| MUST | Use `text_style:` with theme font inheritance |
| SHOULD | Use monospace (`THEME_FONT_CODE`) for data/numbers |
| SHOULD | Use `text_wrap: Word` for body text |
| NEVER | Modify `font_scale` unless explicitly requested |
| MUST | Set explicit `font_size` in `text_style` block |

```rust
// GOOD - theme-based typography
<Label> {
    draw_text: {
        text_style: <THEME_FONT_BOLD>{ font_size: 16.0 }
        color: #ffffff
    }
    text: "Heading"
}

// Data display
<Label> {
    draw_text: {
        text_style: <THEME_FONT_CODE>{ font_size: 14.0 }
    }
    text: "1,234.56"
}
```

## Shader / Graphics

| Rule | Constraint |
|------|------------|
| MUST | Use `Sdf2d` for custom shapes |
| MUST | Draw triangles clockwise from tip for correct fill |
| SHOULD | Use 1-2px overlap when joining shapes to avoid gaps |
| NEVER | Use `if` branches in shaders for visual logic; use `step()`/`mix()` |
| MUST | Use `apply_over()` for instance variables, not `set_uniform()` |
| SHOULD | Use `instance` for per-widget values, `uniform` for global values |
| NEVER | Animate large `blur()` or complex shader effects |

```rust
// GOOD - branchless shader logic
fn pixel(self) -> vec4 {
    let active = step(0.5, self.is_active);
    return mix(#333333, #00ff88, active);
}

// BAD - if branch in shader
fn pixel(self) -> vec4 {
    if self.is_active > 0.5 {
        return #00ff88;
    }
    return #333333;
}
```

## Performance

| Rule | Constraint |
|------|------------|
| MUST | Call `redraw()` on specific widget, not entire UI when possible |
| MUST | Batch multiple state updates before single `redraw()` |
| NEVER | Call `redraw()` unconditionally in `handle_event` |
| SHOULD | Use conditional redraw: only if visual state actually changed |
| MUST | Store previous state to compare before redrawing |
| NEVER | Use `apply_over()` in tight loops |

```rust
// GOOD - conditional redraw
pub fn set_active(&mut self, cx: &mut Cx, active: bool) {
    if self.is_active != active {
        self.is_active = active;
        self.redraw(cx);
    }
}

// BAD - unconditional redraw
pub fn set_active(&mut self, cx: &mut Cx, active: bool) {
    self.is_active = active;
    self.redraw(cx);  // Redraws even if unchanged
}
```

## Empty States & Errors

| Rule | Constraint |
|------|------------|
| MUST | Give empty states one clear call-to-action |
| MUST | Show loading states with structural placeholders, not spinners |
| SHOULD | Use inline error messages near the problematic field |
| NEVER | Show raw error messages to users; provide actionable guidance |

```rust
// GOOD - empty state with action
<View> {
    visible: false  // Show when list is empty
    <Icon> { icon: (ICON_INBOX) }
    <Label> { text: "No messages yet" }
    <Button> { text: "Compose" }
}
```

## Design Constraints

| Rule | Constraint |
|------|------------|
| NEVER | Use gradients unless explicitly requested |
| NEVER | Use glow effects (`shadow_offset`) as primary affordances |
| SHOULD | Limit accent color to one per view |
| MUST | Use theme shadow scale before custom shadows |
| SHOULD | Use consistent border-radius across related elements |
| NEVER | Mix rounded and sharp corners in same component group |

## Overlay & Popup

| Rule | Constraint |
|------|------------|
| MUST | Use `draw_list.begin_overlay_reuse()` for popups |
| MUST | Draw off-screen first to measure, then reposition |
| MUST | Use `cx.redraw_all()` for immediate repositioning |
| SHOULD | Implement edge detection to flip position if off-screen |
| MUST | Close overlays on `Escape` key and outside click |

## Widget Communication

| Rule | Constraint |
|------|------------|
| MUST | Use Actions for widget-to-parent communication |
| MUST | Define actions as enums with `DefaultNone` derive |
| NEVER | Use global mutable state for widget communication |
| SHOULD | Use `Scope` for parent-to-child data passing |
| MUST | Handle actions in parent's `handle_event`, not child |

```rust
// GOOD - action-based communication
#[derive(Clone, Debug, DefaultNone)]
pub enum MyWidgetAction {
    None,
    Clicked,
    ValueChanged(String),
}

// In child widget
cx.widget_action(uid, &scope.path, MyWidgetAction::Clicked);

// In parent
if let MyWidgetAction::Clicked = widget.as_widget_action().cast() {
    // Handle
}
```

## Quick Reference

| Category | Key Rule |
|----------|----------|
| Theme | Use `link::theme::*` tokens first |
| Components | Use built-in widgets before custom |
| Layout | Use `flow` + `spacing`, avoid `abs_pos` |
| Animation | Animator only, never manual interpolation |
| Interaction | Always call `redraw(cx)` after state change |
| Shader | Clockwise triangles, branchless logic |
| Performance | Conditional redraw, batch updates |
| Design | No gradients/glows unless requested |
