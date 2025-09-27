# Prompt Enhancer

A comprehensive prompt enhancement tool that transforms basic prompts into detailed, structured, and AI-optimized requests for better interactions with Large Language Models.

## Features

### 🎯 Core Enhancement Types
- **Text Expansion**: Converts brief prompts into detailed, structured ones
- **Context Injection**: Adds relevant background and environmental information
- **Role-Based Enhancement**: Applies specific professional personas and expertise
- **Template-Based Enhancement**: Uses predefined templates for common tasks
- **AI Optimization**: Applies LLM-specific patterns for better performance

### 🛠️ Key Capabilities
- **Interactive CLI**: User-friendly command-line interface
- **Batch Processing**: Process multiple prompts at once
- **Configuration Management**: Customizable settings and profiles
- **Multiple Output Formats**: Text, JSON, and Markdown support
- **Analysis Tools**: Prompt analysis and improvement suggestions
- **Template Management**: Create and manage custom templates
- **Role Library**: Extensive collection of professional roles

## Installation

### Local Installation
```bash
git clone <repository-url>
cd prompt-enhancer
npm install
```

### Global Installation
```bash
npm install -g prompt-enhancer
# or
npm link  # for development
```

## Quick Start

### Command Line Usage

#### Basic Enhancement
```bash
# Enhance a simple prompt
prompt-enhancer enhance -p "help me debug this code"

# Enhance from file
prompt-enhancer enhance -f input.txt -o output.txt

# Interactive mode
prompt-enhancer interactive
```

#### Specific Enhancements
```bash
# Apply specific role
prompt-enhancer enhance -p "review this code" --role developer

# Use specific template
prompt-enhancer enhance -p "fix this bug" --template debugging

# Add context
prompt-enhancer enhance -p "optimize performance" --context backend
```

#### Analysis and Templates
```bash
# Analyze a prompt
prompt-enhancer analyze -p "help me with this"

# List available templates
prompt-enhancer template list

# Show role details
prompt-enhancer role show developer

# Preview template
prompt-enhancer template preview debugging -p "my code is broken"
```

### Programmatic Usage

```javascript
const { PromptEnhancer } = require('prompt-enhancer');

const enhancer = new PromptEnhancer({
  enableTextExpansion: true,
  enableContextInjection: true,
  enableRoleBasedEnhancement: true,
  enableTemplateBasedEnhancement: true,
  enableAIOptimization: true
});

async function enhancePrompt() {
  const result = await enhancer.enhance('help me debug this code', {
    role: 'developer',
    context: 'backend'
  });
  
  console.log('Original:', result.original);
  console.log('Enhanced:', result.enhanced);
  console.log('Applied:', result.metadata.enhancementsApplied);
}

enhancePrompt();
```

## Enhancement Types

### 1. Text Expansion
Transforms brief, vague prompts into detailed, specific requests:

**Input:** `"help me"`
**Output:** `"Please provide detailed guidance on: help me. Include relevant details, examples, and context where appropriate."`

### 2. Context Injection
Adds environmental and domain-specific context:

**Features:**
- Temporal context (current date/time)
- Environmental context (platform, environment)
- Domain context (web, backend, security, etc.)
- Custom context injection

### 3. Role-Based Enhancement
Applies professional personas and expertise:

**Available Roles:**
- `developer` - Expert Software Developer
- `architect` - Software Architect  
- `devops` - DevOps Engineer
- `security` - Security Expert
- `designer` - UX/UI Designer
- `analyst` - Business Analyst
- `mentor` - Technical Mentor
- And many more...

### 4. Template-Based Enhancement
Applies structured templates for common tasks:

**Available Templates:**
- `codeReview` - Code review template
- `debugging` - Debugging template
- `architecture` - System architecture template
- `comparison` - Comparison analysis template
- `tutorial` - Tutorial creation template
- `troubleshooting` - Problem-solving template

### 5. AI Optimization
Applies LLM-specific optimization patterns:

**Optimizations:**
- Fixes vague language and anti-patterns
- Adds chain-of-thought prompting
- Improves clarity and specificity
- Optimizes token usage
- Structures complex requests

## Configuration

### Initialize Configuration
```bash
prompt-enhancer config init
```

### View Configuration
```bash
prompt-enhancer config show
```

### Update Settings
```bash
prompt-enhancer config set enableTextExpansion false
prompt-enhancer config set defaultRole developer
prompt-enhancer config set verboseOutput true
```

### Configuration File
Configuration is stored in `~/.prompt-enhancer/config.json`:

```json
{
  "enableTextExpansion": true,
  "enableContextInjection": true,
  "enableRoleBasedEnhancement": true,
  "enableTemplateBasedEnhancement": true,
  "enableAIOptimization": true,
  "defaultRole": null,
  "defaultTemplate": null,
  "verboseOutput": false,
  "maxTokens": 4000
}
```

## Examples

### Basic Enhancement
```bash
$ prompt-enhancer enhance -p "create a function"

✨ Enhancement Complete!
==================================================

You are acting as a Expert Software Developer. You are an experienced software developer with deep knowledge of programming languages, frameworks, and best practices.

I need you to create a function. Please ensure the output is well-structured, follows best practices, and includes appropriate documentation or explanations.

Consider backend best practices including: REST APIs, databases, authentication.

Response guidance: Provide a comprehensive and well-reasoned response. Use clear formatting with headings and bullet points where appropriate.
```

### Role-Specific Enhancement
```bash
$ prompt-enhancer enhance -p "review security" --role security

✨ Enhancement Complete!
==================================================

You are acting as a Security Expert. You are a cybersecurity specialist with deep knowledge of security best practices and threat mitigation.

Please conduct a thorough analysis of: review security. Provide detailed insights, identify key points, and offer actionable recommendations.

Security Context: Prioritize security considerations and be thorough in risk assessment.

Communication Style: Prioritize security considerations and be thorough in risk assessment.
```

### Template Enhancement
```bash
$ prompt-enhancer enhance -p "debug login issue" --template debugging

✨ Enhancement Complete!
==================================================

I'm encountering an issue that needs debugging:

Problem: debug login issue

Please help me:
1. Identify the root cause
2. Provide step-by-step debugging approach
3. Suggest potential solutions
4. Recommend preventive measures

Include relevant debugging techniques and tools where applicable.

**Output Format Requirements:**
Use clear formatting with headings and bullet points where appropriate.
```

## API Reference

### PromptEnhancer Class

#### Constructor
```javascript
new PromptEnhancer(config)
```

#### Methods
- `enhance(prompt, options)` - Enhance a prompt with all configured enhancers
- `getAvailableEnhancers()` - Get list of available enhancers
- `updateConfig(newConfig)` - Update configuration

#### Options
- `skipTextExpansion` - Skip text expansion
- `skipContextInjection` - Skip context injection  
- `skipRoleEnhancement` - Skip role enhancement
- `skipTemplateEnhancement` - Skip template enhancement
- `skipAIOptimization` - Skip AI optimization
- `role` - Specific role to apply
- `template` - Specific template to apply
- `context` - Context type to inject

## Testing

Run the test suite:
```bash
npm test
```

Run specific tests:
```bash
node tests/test.js
```

The test suite includes:
- Unit tests for each enhancer
- Integration tests
- Performance tests
- Configuration tests

## Development

### Project Structure
```
prompt-enhancer/
├── src/
│   ├── core/
│   │   ├── PromptEnhancer.js     # Main enhancer engine
│   │   ├── ConfigManager.js      # Configuration management
│   │   └── enhancers/            # Individual enhancer modules
│   │       ├── TextExpander.js
│   │       ├── ContextInjector.js
│   │       ├── RoleEnhancer.js
│   │       ├── TemplateEnhancer.js
│   │       └── AIOptimizer.js
│   ├── cli/
│   │   └── cli.js                # Command-line interface
│   └── index.js                  # Main entry point
├── tests/
│   └── test.js                   # Test suite
└── package.json
```

### Adding Custom Enhancers

Create a new enhancer by extending the base pattern:

```javascript
class CustomEnhancer {
  static description = 'Description of what this enhancer does';

  constructor(config = {}) {
    this.config = config;
  }

  shouldApply(prompt, options = {}) {
    // Return true if this enhancer should be applied
    return true;
  }

  async enhance(prompt, options = {}) {
    // Apply enhancement logic
    const enhanced = this.transform(prompt);
    
    return {
      enhanced,
      description: 'Applied custom enhancement',
      changes: ['Custom change applied']
    };
  }

  transform(prompt) {
    // Your enhancement logic here
    return prompt;
  }
}

module.exports = CustomEnhancer;
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request

## License

ISC License - see LICENSE file for details

## Support

For issues, feature requests, or questions:
1. Check the documentation
2. Run `prompt-enhancer --help` for CLI help
3. File an issue on GitHub

---

**Prompt Enhancer** - Transform your prompts, enhance your AI interactions! 🚀