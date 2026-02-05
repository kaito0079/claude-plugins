# Skill/Agent Authoring Guide

## Language Rules

**CRITICAL: All Claude Skills and Agent definitions MUST be written in English.**

### Rationale
1. **Claude's primary training language**: English
2. **Token efficiency**: Claude processes English more efficiently than Japanese
3. **Translation direction**: Claude excels at "to English" translation (56.9% advantage), struggles with "from English" (9.65%)
4. **International sharing**: Skills can be shared globally
5. **Maintenance**: Easier to maintain and update

### Scope
- `SKILL.md`: **Must be English**
- `agents/*.md`: **Must be English** (frontmatter + system prompt)
- `scripts/*.py`: Comments and docstrings in English
- `references/*.md`: **Must be English**
- Error messages: English (or English + Japanese bilingual)
- `README.md` (user-facing): Japanese is OK

### Exceptions
- Japan-specific domain knowledge (e.g., Japanese tax regulations)
  → Write in English, with Japanese technical terms annotated where necessary
- User-facing documentation
  → Japanese is OK (but SKILL.md and Agent .md must be English)

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
- [ ] SKILL.md is written in English
- [ ] Agent .md is written in English (frontmatter + system prompt)
- [ ] references/*.md are written in English
- [ ] Script comments and docstrings are in English
- [ ] Grammatically correct, complete English sentences
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

**Why English?**
1. Claude's primary training language
2. 56.9% better performance when translating TO English
3. Better token efficiency with proper English structure
4. International compatibility
