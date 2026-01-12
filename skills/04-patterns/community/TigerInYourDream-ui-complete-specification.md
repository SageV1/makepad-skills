---
name: ui-complete-specification
author: TigerInYourDream
source: real-world-ai-assisted-ui-development
date: 2026-01-12
tags: [ui, layout, button, spacing, best-practices]
level: beginner
---

# UI Complete Specification Pattern

Provide complete layout specifications upfront to prevent common UI issues like text overlap, misalignment, and spacing problems.

## Problem

A common pattern in AI-assisted UI development:

1. User asks to add a button
2. AI adds button with approximate positioning
3. Button appears but text overlaps with adjacent elements ("text fighting")
4. User asks to fix it
5. AI struggles with iterative adjustments, often missing properties

This happens because **partial specifications** leave too many layout properties undefined, leading to unexpected behavior. The AI enters an "edit loop" where each fix introduces new issues.

## Solution

Always provide **complete specifications** with all layout properties defined upfront. This includes size, padding, margin, text configuration, and alignment—even if some seem obvious.

The pattern follows a checklist approach: before writing any UI code, ensure all critical properties are explicitly set.

## Implementation

### Complete Button Specification

```rust
live_design! {
    MyButton = <Button> {
        // ✅ Size: Explicit width/height
        width: Fit           // or Fill, or fixed number
        height: 40           // fixed height recommended for buttons

        // ✅ Internal spacing: Padding INSIDE the element
        padding: { left: 16, right: 16, top: 8, bottom: 8 }

        // ✅ External spacing: Margin between elements
        margin: { left: 8, right: 8 }

        // ✅ Text configuration
        text: "Button Label"
        draw_text: {
            text_style: <THEME_FONT_BOLD>{ font_size: 14.0 }
            color: #ffffff
            wrap: Line       // Prevent unexpected wrapping
        }

        // ✅ Background and styling
        draw_bg: {
            color: #2196F3
            color_hover: #1976D2
            border_radius: 4.0
        }
    }
}
```

### Horizontal Button Row

```rust
live_design! {
    ButtonRow = <View> {
        width: Fill
        height: Fit
        flow: Right        // Horizontal layout
        spacing: 12        // Gap between buttons
        align: { y: 0.5 }  // Vertically center
        padding: 16        // Outer padding

        cancel_btn = <Button> {
            width: Fit
            height: 40
            padding: { left: 16, right: 16 }
            text: "Cancel"
            draw_bg: { color: #666, border_radius: 4.0 }
            draw_text: {
                text_style: <THEME_FONT_BOLD>{ font_size: 14.0 }
                wrap: Line
            }
        }

        confirm_btn = <Button> {
            width: Fit
            height: 40
            padding: { left: 16, right: 16 }
            text: "Confirm"
            draw_bg: { color: #2196F3, border_radius: 4.0 }
            draw_text: {
                text_style: <THEME_FONT_BOLD>{ font_size: 14.0 }
                wrap: Line
            }
        }
    }
}
```

### Button with Icon and Text

```rust
live_design! {
    IconButton = <Button> {
        width: Fit
        height: 40
        flow: Right        // Icon + text horizontally
        spacing: 8         // Gap between icon and text
        padding: { left: 12, right: 16 }
        align: { y: 0.5 }  // Center icon and text vertically

        icon = <Icon> {
            width: 20, height: 20
            draw_icon: { svg_file: dep("crate://self/resources/save.svg") }
        }

        label = <Label> {
            text: "Save"
            draw_text: {
                text_style: <THEME_FONT_BOLD>{ font_size: 14.0 }
                wrap: Line
            }
        }
    }
}
```

## Usage

### Self-Check Checklist

Before applying any UI changes, verify:

- [ ] **Size specified**: width and height defined (Fit/Fill/fixed)
- [ ] **Padding added**: Internal spacing prevents text from touching edges
- [ ] **Spacing/margin set**: External spacing prevents collision with neighbors
- [ ] **Alignment configured**: Parent has `align: { x, y }` if needed
- [ ] **Text wrapping defined**: `wrap:` property set explicitly
- [ ] **Minimum dimensions**: Button width accommodates longest expected text
- [ ] **Parent flow**: Parent View has `flow: Right/Down` matching intent

### Screenshot-Driven Debugging

When user reports layout issues:

1. **Request screenshot** with problem areas circled/marked
2. **Ask for expected result** (sketch, reference app, or description)
3. **Provide complete code replacement** (not "change X to Y" instructions)
4. **Explain each property's role** in fixing the issue

Example response pattern:

```
I see the text overlap issue. The problem is missing padding inside the button
and insufficient spacing between buttons. Here's the complete fixed code:

[Full button definition with all properties]

Changes made:
- Added padding: { left: 16, right: 16 } to give text breathing room
- Added margin: { left: 8, right: 8 } to space from adjacent buttons
- Set explicit width: Fit to size to content
- Added wrap: Line to prevent text wrapping
```

## When to Use

This comprehensive specification approach is essential when:

- Adding new buttons or interactive elements
- Modifying existing UI that has layout issues
- Creating forms with multiple aligned fields
- Mixing different UI element types (icons, text, buttons)
- User reports text overlap or spacing problems
- Working with AI assistance for UI development

## When NOT to Use

- Prototyping where exact spacing doesn't matter yet
- Copying exact code from working examples (already complete)
- Simple single-element tests

## Common Text Collision Causes

| Problem | Root Cause | Fix |
|---------|------------|-----|
| Text overlaps next button | No spacing/margin between siblings | Add `spacing: 8` to parent or `margin: { left: 8, right: 8 }` |
| Text touches button edge | No padding inside button | Add `padding: { left: 16, right: 16 }` |
| Buttons not aligned | Different heights, no parent alignment | Add `align: { y: 0.5 }` to parent View |
| Text wraps unexpectedly | No wrap setting | Set `draw_text: { wrap: Line }` |
| Button too narrow | width: Fit but text longer than expected | Use fixed width or increase padding |
| Vertical misalignment | Mixed element sizes in horizontal layout | Add `align: { y: 0.5 }` to parent |

## Anti-Patterns

### ❌ Bad: Partial Specification

```rust
// Missing padding, margin, explicit size
<Button> {
    text: "Click Me"
}
```

### ✅ Good: Complete Specification

```rust
<Button> {
    width: Fit
    height: 40
    padding: { left: 16, right: 16 }
    margin: { left: 8, right: 8 }
    text: "Click Me"
    draw_text: {
        text_style: <THEME_FONT_BOLD>{ font_size: 14.0 }
        wrap: Line
    }
}
```

### ❌ Bad: Incremental Fixes

```
"Try adding some padding"
[User applies, still broken]
"Maybe increase the margin"
[User applies, still broken]
"Let's adjust the spacing"
```

### ✅ Good: Complete Solution

```
"Here's the complete corrected button definition with all layout properties:

[Full code block]

This fixes the issue by:
1. Adding padding for internal spacing
2. Setting margin for external spacing
3. Defining explicit dimensions
"
```

## Related Patterns

- [Layout System](../../01-core/layout.md) - Flow, sizing, spacing fundamentals
- [Widgets](../../01-core/widgets.md) - Button, Label, TextInput reference

## References

- Emerged from real-world AI-assisted Makepad UI development
- Addresses the "edit loop" problem where iterative fixes fail
- Based on Makepad layout system best practices
