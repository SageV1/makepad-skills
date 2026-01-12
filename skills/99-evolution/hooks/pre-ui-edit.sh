#!/bin/bash
# Pre-UI-Edit Hook for makepad-evolution
# Author: TigerInYourDream
# Date: 2026-01-12
# Triggers: Only when UI code appears incomplete (missing critical properties)
# Purpose: Provide targeted reminders for incomplete UI specifications
# Related pattern: 04-patterns/community/TigerInYourDream-ui-complete-specification.md

TOOL_NAME="$1"
TOOL_INPUT="$2"

# Only trigger for Write/Edit operations
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
    exit 0
fi

# Check if this is UI-related code
if ! echo "$TOOL_INPUT" | grep -qE "(Button|Label|TextInput|RoundedView)\s*=\s*<|<(Button|Label|TextInput|RoundedView)>"; then
    exit 0
fi

# ============================================
# Smart Detection: Only trigger if incomplete
# ============================================

# Count completeness indicators
HAS_WIDTH=$(echo "$TOOL_INPUT" | grep -cE "width:\s*(Fit|Fill|[0-9]+)")
HAS_HEIGHT=$(echo "$TOOL_INPUT" | grep -cE "height:\s*(Fit|Fill|[0-9]+)")
HAS_PADDING=$(echo "$TOOL_INPUT" | grep -cE "padding:\s*\{|padding:\s*[0-9]+")
HAS_TEXT_STYLE=$(echo "$TOOL_INPUT" | grep -cE "draw_text:\s*\{|text_style:")
HAS_WRAP=$(echo "$TOOL_INPUT" | grep -c "wrap:")

# Calculate completeness score (0-5)
COMPLETENESS=$((HAS_WIDTH + HAS_HEIGHT + HAS_PADDING + HAS_TEXT_STYLE + HAS_WRAP))

# Threshold: Only warn if missing 3+ critical properties
if [ "$COMPLETENESS" -ge 3 ]; then
    # Code looks complete, don't interrupt
    exit 0
fi

# ============================================
# Triggered: Code appears incomplete
# ============================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📐 UI Specification Reminder (Completeness: $COMPLETENESS/5)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Detected UI code that may be missing critical properties."
echo ""

# Provide specific feedback on what's missing
MISSING=""
if [ "$HAS_WIDTH" -eq 0 ]; then
    echo "  ⚠️  Missing: width (Fit/Fill/number)"
    MISSING="$MISSING width,"
fi

if [ "$HAS_HEIGHT" -eq 0 ]; then
    echo "  ⚠️  Missing: height (Fit/Fill/number)"
    MISSING="$MISSING height,"
fi

if [ "$HAS_PADDING" -eq 0 ]; then
    echo "  ⚠️  Missing: padding (prevents text overlap)"
    MISSING="$MISSING padding,"
fi

if [ "$HAS_TEXT_STYLE" -eq 0 ]; then
    echo "  ⚠️  Missing: draw_text/text_style configuration"
    MISSING="$MISSING text_style,"
fi

if [ "$HAS_WRAP" -eq 0 ]; then
    echo "  ⚠️  Missing: wrap (Line/Word/Ellipsis)"
    MISSING="$MISSING wrap,"
fi

echo ""
echo "To prevent text overlap and layout issues, ensure:"
echo ""
echo "  ✓ Size:       width: Fit/Fill/N, height: N"
echo "  ✓ Padding:    padding: { left: N, right: N, top: N, bottom: N }"
echo "  ✓ Spacing:    spacing: N (parent) or margin: {} (self)"
echo "  ✓ Text:       draw_text: { text_style:, wrap: Line/Word/Ellipsis }"
echo "  ✓ Alignment:  align: { x: 0-1, y: 0-1 } (if mixing sizes)"
echo ""
echo "📚 Full guide: 04-patterns/community/TigerInYourDream-ui-complete-specification.md"
echo ""
echo "Complete specification prevents the 'edit loop' problem."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exit 0
