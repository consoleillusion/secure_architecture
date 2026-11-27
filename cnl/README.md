# Controlled languages used by the course

Every Markdown source in `content/` declares its controlled language in YAML
frontmatter. The declaration is consumed by `tools/lint_cnl.py` in CI; it is not
printed in the book.

```yaml
---
cnl: ste                  # required
cnl-version: 1            # required
cnl-scope: narrative      # narrative | normative | hybrid
lexicon: core-v1          # required
lint: light               # light | strict
secondary-cnl: ace        # optional
vocabulary: mitre-attack  # optional
---
```

## Declared languages

| CNL | Chapters | What it means here |
| --- | --- | --- |
| `plain-language` | Introduction, Adversary Awareness, bibliography, Human Layer | Short, active sentences; no unexplained jargon. Adversary Awareness adds the MITRE ATT&CK vocabulary. |
| `ste` | Networking chapters and ports, Host Security, Observability, glossary, Samba practical | Simplified Technical English: short sentences, active voice, controlled terms, one idea per sentence. |
| `ace` | Foundations, Identity/PKI, Data Security, Resilience | Attempto Controlled English for the normative rules. Narrative prose remains readable; rule blocks use `shall`. |
| `sbvr` | Application/Supply Chain, Governance | SBVR Structured English for obligations and policy statements, using `shall`. |

`clce` and `special-english` are recognised by the linter but are not currently
assigned to a chapter. E-Prime was evaluated for the Human Layer and rejected:
the constraint removes forms of "to be" without adding formal verifiability and
makes causal claims harder to read.

## Enforcement levels

- `lint: light` validates the declaration and the shared lexicon version only.
  It is used for long narrative chapters where a full style check would not be
  meaningful without damaging readability.
- `lint: strict` additionally requires at least three `shall` rules for ACE and
  SBVR chapters. Those rules are collected under an **Architectural rules**
  heading so a reader can find them and a future parser can extract them.

The linter is a style check, not a formal ACE or SBVR parser. Full formal
validation would require an external tool such as APE for ACE; SBVR and RuleSpeak
have no comparable open validator.

## Shared lexicon

All chapters draw from `core-v1`. The controlling terms are: *architecture*,
*trust boundary*, *least privilege*, *default deny*, *complete mediation*,
*trusted computing base*, *identity*, *credential*, *attestation*, *provenance*,
*immutability*, *control*, *data class*, *recovery objective*, and *detection
surface*. Use these spellings consistently; introduce a new term only in the
chapter that defines it and add it to this list in the same commit.

Run the check from the project root:

```sh
python3 tools/lint_cnl.py
```
