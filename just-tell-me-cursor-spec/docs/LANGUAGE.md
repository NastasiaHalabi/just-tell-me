# Lebanese / Arabic Language Requirements

## Goal
Understand intent, not perfect formal Arabic grammar.

## Supported forms

### Arabic script
- ذكرني بكرا عالخمسة
- ابعت لكريم إني رح إتأخر
- شو عندي بكرا؟

### Arabizi
- zakirne bokra 3al 5
- eb3at la Karim enne ra7 et2akhar
- shu 3ande bokra?

### Code switching
- bokra 3ande meeting at 3, remind me abla bi nos se3a
- ابعت email لـ Karim وقله the report is ready
- ba3d l meeting send Maya a message

## Normalization dictionary examples
This dictionary is a hint layer, not the only parser.

- bokra / بكرا -> tomorrow
- ba3d bokra / بعد بكرا -> day after tomorrow
- hala2 / هلق -> now
- ba3d shway / بعد شوي -> shortly
- 3al -> at/on depending on context
- zakirne / ذكرني -> remind me
- eb3at / ابعت -> send
- ell(o/a) / قلو/قلها -> tell him/her
- de2 / دق -> call
- soboh / صبح -> morning
- masa / مسا -> evening

## Planner context
Always provide:
- exact current local datetime
- timezone
- likely locale `ar-LB`

## Golden test corpus
Create a version-controlled JSON file containing at least:
- 25 English commands
- 25 Arabic script commands
- 50 Arabizi/code-switched commands

Each case includes expected action types and key extracted fields.

## Important rule
Do not translate the utterance first and then parse only the translation. Preserve original wording because aliases, names, and code-switched terms may be lost.
