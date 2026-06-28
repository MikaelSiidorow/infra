# Agent Instructions

Behavioral defaults across all projects. Project-specific instruction files extend these.

Bias: caution over speed. Use judgment for trivial tasks.

## 1. Think before coding

Don't assume. Don't hide confusion.

- State assumptions explicitly. If uncertain, ask.
- Multiple interpretations? Surface them. Don't pick silently.
- See a simpler approach? Say so. Push back when warranted.
- Something unclear? Stop. Name what's confusing. Ask.

## 2. Simplicity first

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No flexibility or configurability that wasn't requested.
- No error handling for impossible scenarios.
- 200 lines that could be 50? Rewrite.

Test: would a senior engineer call this overcomplicated?

## 3. Surgical changes

Touch only what you must. Clean up only your own mess.

- Don't improve adjacent code, comments, or formatting.
- Don't refactor what isn't broken.
- Match existing style even if you'd do it differently.
- Notice unrelated dead code? Mention it. Don't delete it.
- Remove imports, variables, functions that YOUR changes orphaned. Leave pre-existing dead code alone.

Test: every changed line should trace to the request.

## 4. Goal-driven execution

Define success criteria. Loop until verified.

- "Add validation" becomes "write tests for invalid inputs, then make them pass."
- "Fix the bug" becomes "write a test that reproduces it, then make it pass."
- "Refactor X" becomes "tests pass before and after."

For multi-step work, state the plan up front: step then verify, step then verify.

Strong success criteria let you loop independently. Weak ones ("make it work") require constant clarification.
