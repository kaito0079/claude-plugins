# Skill/Agent Authoring Guide

## Language Rules

**Skills and Agents may be authored in either Japanese or English. Pick one per file and stay consistent.**

### Scope
- `SKILL.md`: Japanese or English (consistent within file)
- `agents/*.md`: Japanese or English (frontmatter + system prompt, consistent within file)
- `scripts/*.py`: Comments and docstrings in **English** (technical artifacts)
- `references/*.md`: Japanese or English
- Error messages: English (or English + Japanese bilingual)
- `README.md` (user-facing): Japanese

### Tradeoffs to consider when choosing a language

Either language works at runtime — Claude reads `description` to decide skill invocation and handles Japanese and English with comparable accuracy. Differences worth knowing:

- **Token usage**: Japanese is slightly denser in tokens per character, but for short fields like `description` the difference is negligible.
- **Translation direction (older studies)**: Claude historically performed better when translating *to* English than *from* it. For modern Claude versions and for non-translation tasks (instruction following, classification), this gap has largely closed.
- **Audience**: If a skill might be shared with non-Japanese readers, English is more portable. For personal/internal tooling, Japanese is fine and improves Japanese-speaking author's ability to scan and maintain the file.
- **Mixing**: Don't mix mid-file. A `description` in Japanese with English body is OK as long as each section is internally consistent.

### Exceptions
- Japan-specific domain knowledge (e.g., Japanese tax regulations)
  → Japanese is preferable to preserve domain terms; annotate English equivalents where useful.

## Priority Notation Guidelines

### Core Principle (WCAG Compliant)

- **Never rely on color alone**: Combine shape + text
- **Grayscale compatible**: Must be distinguishable with color vision deficiency or when printed
- **Text labels required**: Never use symbols without text

### Recommended Pattern: MoSCoW + Shape

```markdown
⬛ MUST - Critical requirement
◆ SHOULD - Strongly recommended
○ NICE TO HAVE - Optional enhancement
```

**Rationale:**

- Distinguishable in grayscale (■ > ◆ > ○)
- Screen reader compatible (text labels included)
- Text labels follow the internationally recognized MoSCoW method

### Prohibited Patterns

**Color-only differentiation:**
```markdown
🔴 MUST
🟡 SHOULD
🟢 NICE TO HAVE
```
Reason: Indistinguishable with color vision deficiency or in grayscale

**Symbol-only (no text):**
```markdown
⬛
◆
○
```
Reason: Meaningless to screen readers

### Usage Example

```markdown
## Requirements

⬛ MUST
1. SKILL.md must be written in English
2. No prompt injection patterns

◆ SHOULD
1. Include README.md with usage examples
2. Add references/ for detailed info

○ NICE TO HAVE
1. Automated tests
2. Multiple language examples
```

## Quality Checklist

After creating a Skill or Agent, verify the following:
- [ ] SKILL.md uses Japanese or English consistently
- [ ] Agent .md uses Japanese or English consistently (frontmatter + system prompt)
- [ ] references/*.md uses Japanese or English consistently
- [ ] Script comments and docstrings are in English
- [ ] Grammatically correct, complete sentences in the chosen language
- [ ] Well-structured (clear sections, bullet points, tables)

## References

### Anthropic Official Documentation
- **Multilingual Support**: https://platform.claude.com/docs/en/build-with-claude/multilingual-support
  - Claude's performance across languages
  - "Claude excels at tasks across multiple languages, maintaining strong cross-lingual performance relative to English"

- **Claude 3 Model Card (PDF)**: https://www-cdn.anthropic.com/de8ba9b01c9ab7cbabf5c33b80b7bbc618857627/Model_Card_Claude_3.pdf
  - Page 10-11: Multilingual benchmarks showing Japanese 90%+ accuracy
  - Primary training language: English

- **Skill Authoring Best Practices**: https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices
  - "Use consistent naming patterns"
  - "Always use forward slashes in file paths, even on Windows"
  - Progressive disclosure patterns

### Language Performance Research
- **Claude Translation Performance Study**: https://www.transphere.com/claude-translation/
  - Into English: 56.9% outperformance vs traditional MT
  - From English: Only 9.65% outperformance
  - **Key insight**: Claude processes English→Output better than Input→English

- **Japanese Performance Analysis**: https://medium.com/@kappei/ai-language-models-ace-japanese-recruitment-test-claude-outperforms-gpt-4-and-googles-gemini-22218532f49c
  - Claude 3 Opus: 62% accuracy in Japanese (vs GPT-4's 55%)
  - 98% accuracy in English
  - English prompts improve non-language task performance

### Token Efficiency and Prompt Engineering
- **Token Efficiency Guide**: https://portkey.ai/blog/optimize-token-efficiency-in-prompts
  - Concise prompting best practices
  - "Eliminate unnecessary words and focus on essential information"

- **Prompt Engineering Guide**: https://www.promptingguide.ai/
  - Comprehensive prompt engineering techniques
  - Token optimization strategies

- **LLM Token Cost Reduction**: https://prateekvishwakarma.tech/blog/how-can-prompt-engineers-reduce-llm-token-costs-in-complex-applications
  - Example: Verbose → Concise reduces tokens by 40%
  - "Every unnecessary word or phrase is a wasted token"

### Reference Implementations
- **GitHub Prompt Engineering Guide**: https://github.blog/ai-and-ml/generative-ai/prompt-engineering-guide-generative-ai-llms/
  - Best practices from GitHub's experience
  - Document domain mapping strategies

## Summary

**Choosing a language**
- Both Japanese and English work; pick what is easier for the file's primary audience to read and maintain.
- Author-facing readability (`description` shown in the skill picker) is often the dominant factor — if scanning English descriptions is slow, write them in Japanese.
- For broadly-shared or open-sourced skills, prefer English for portability.
- Within a single file, do not mix languages by sentence; sectional consistency is required.
