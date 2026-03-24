# Playtest Survey Specification

Use this questionnaire as the source for the Google Form linked from each `docs/playtest_{VERSION}.md` report.

## Setup

- Audience: cold players who have not played earlier Probabimals builds
- Response policy: one form submission per play session
- Live form title: `Probabimals. Playtest`
- Required fields: version, device/browser, prior exposure, session length, three ratings, and `Would you play another version of this game?`

## Questions

1. `Your version`
   Short answer. Helper text: `You can check a version from the main menu`.
2. `Device and browser`
   Short answer. Example: `MacBook Air, Chrome 135`.
3. `Had you played Probabimals before this session?`
   Multiple choice: `Yes`, `No`.
4. `How long did you play?`
   Multiple choice: `<5 minutes`, `5-10 minutes`, `10-20 minutes`, `20+ minutes`.
5. `How clear were the rules and goals?`
   Linear scale: `1-5`.
6. `How fun was the game?`
   Linear scale: `1-5`.
7. `How difficult did the game feel?`
   Linear scale: `1-5`.
8. `What was the most confusing or hard to understand thing?`
   Paragraph.
9. `What was your favorite moment or mechanic?`
    Paragraph.
10. `What problem would you prioritize addressing?`
    Paragraph.
11. `Would you play another version of this game?`
   Multiple choice: `Yes`, `No`, `Maybe`.
12. `Anything else you want to add?`
   Paragraph. Optional.

## Export Checklist

- Record the live Google Form URL in the matching playtest report
- Copy the same live URL into `project.godot` under `playtest/survey_url` so the in-game buttons open it
- Keep the docs aligned with the published form if question wording or order changes
- Export responses to a sheet or summary view before writing findings
- Preserve raw wording from players where it changes the interpretation of feedback
