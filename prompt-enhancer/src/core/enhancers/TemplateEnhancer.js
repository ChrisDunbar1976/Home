class TemplateEnhancer {
  static description = 'Applies predefined templates to structure and improve prompt clarity and effectiveness';

  constructor(config = {}) {
    this.config = config;
    this.templates = {
      // Task-based templates
      codeReview: {
        name: 'Code Review Template',
        trigger: /review|check|audit|examine.*code/i,
        template: `Please conduct a comprehensive code review of the following:

{original}

Focus on:
- Code quality and maintainability
- Performance implications
- Security considerations
- Best practices adherence
- Potential bugs or issues
- Documentation and comments

Provide specific recommendations for improvement.`
      },

      debugging: {
        name: 'Debugging Template',
        trigger: /debug|fix|error|bug|problem|issue/i,
        template: `I'm encountering an issue that needs debugging:

Problem: {original}

Please help me:
1. Identify the root cause
2. Provide step-by-step debugging approach
3. Suggest potential solutions
4. Recommend preventive measures

Include relevant debugging techniques and tools where applicable.`
      },

      architecture: {
        name: 'Architecture Design Template',
        trigger: /architect|design.*system|structure|framework/i,
        template: `I need help designing a system architecture:

Requirements: {original}

Please provide:
- High-level architecture overview
- Component breakdown and responsibilities
- Data flow and interactions
- Technology stack recommendations
- Scalability considerations
- Security architecture
- Deployment strategy

Include diagrams or structured descriptions where helpful.`
      },

      // Analysis templates
      comparison: {
        name: 'Comparison Analysis Template',
        trigger: /compare|versus|vs|difference|choose between/i,
        template: `Please provide a detailed comparison analysis:

Subject: {original}

Structure your response as:

## Overview
Brief introduction to what's being compared

## Comparison Matrix
| Criteria | Option A | Option B | Option C |
|----------|----------|----------|----------|
| [Key factors to compare]

## Detailed Analysis
- Strengths and weaknesses of each option
- Use cases where each excels
- Performance considerations
- Cost implications

## Recommendation
Based on the analysis, provide a clear recommendation with reasoning.`
      },

      evaluation: {
        name: 'Technology Evaluation Template',
        trigger: /evaluate|assess|analyze.*technology|pros.*cons/i,
        template: `Technology Evaluation Request:

Focus: {original}

Please provide a structured evaluation:

## Technology Overview
- Purpose and core functionality
- Key features and capabilities

## Technical Analysis
- Architecture and design principles
- Performance characteristics
- Scalability potential
- Security features

## Practical Considerations
- Learning curve and adoption complexity
- Community and ecosystem support
- Documentation quality
- Licensing and cost factors

## Use Case Fit
- Ideal scenarios for adoption
- Potential limitations or constraints
- Integration considerations

## Final Assessment
Overall recommendation with reasoning.`
      },

      // Planning templates
      projectPlan: {
        name: 'Project Planning Template',
        trigger: /plan|roadmap|timeline|project|implementation/i,
        template: `Project Planning Request:

Project: {original}

Please create a structured plan including:

## Project Overview
- Objectives and deliverables
- Success criteria
- Constraints and assumptions

## Work Breakdown Structure
1. Phase 1: [Planning & Analysis]
   - Task breakdown
   - Deliverables
   - Timeline estimates

2. Phase 2: [Implementation]
   - Development tasks
   - Testing activities
   - Integration points

3. Phase 3: [Deployment & Maintenance]
   - Deployment strategy
   - Monitoring setup
   - Maintenance procedures

## Resource Requirements
- Team skills needed
- Technology requirements
- Timeline estimates

## Risk Assessment
- Potential risks and mitigation strategies`
      },

      // Learning templates
      tutorial: {
        name: 'Tutorial Template',
        trigger: /tutorial|guide|how.*to|step.*by.*step|learn/i,
        template: `Tutorial Request: {original}

Please create a comprehensive tutorial with:

## Prerequisites
- Required knowledge
- Tools and setup needed

## Learning Objectives
By the end of this tutorial, you will be able to:
- [List specific learning outcomes]

## Step-by-Step Guide

### Step 1: [Foundation]
[Detailed instructions with examples]

### Step 2: [Building]
[Progressive complexity with clear explanations]

### Step 3: [Advanced Concepts]
[More complex scenarios and best practices]

## Practical Examples
- Real-world use cases
- Code samples with explanations
- Common pitfalls to avoid

## Next Steps
- Additional resources for deeper learning
- Related topics to explore

## Summary
Key takeaways and review of concepts covered.`
      },

      // Documentation templates
      apiDoc: {
        name: 'API Documentation Template',
        trigger: /api.*document|document.*api|api.*spec/i,
        template: `API Documentation Request:

API: {original}

Please create comprehensive API documentation:

## Overview
- API purpose and functionality
- Base URL and versioning
- Authentication requirements

## Endpoints

### Endpoint Name
- **Method**: GET/POST/PUT/DELETE
- **URL**: /api/endpoint
- **Description**: What this endpoint does

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| param1 | string | Yes | Parameter description |

**Request Example:**
\`\`\`json
{
  "example": "request"
}
\`\`\`

**Response Example:**
\`\`\`json
{
  "example": "response"
}
\`\`\`

**Status Codes:**
- 200: Success
- 400: Bad Request
- 401: Unauthorized
- 500: Internal Server Error

## Error Handling
Common error scenarios and responses

## Rate Limiting
Rate limiting policies and headers

## SDK Examples
Code examples in popular languages`
      },

      // Problem-solving templates
      troubleshooting: {
        name: 'Troubleshooting Template',
        trigger: /troubleshoot|diagnose|solve.*problem/i,
        template: `Troubleshooting Request:

Issue: {original}

## Problem Analysis

### Symptoms
- What exactly is happening?
- When does the issue occur?
- What error messages appear?

### Environment Details
- System/platform information
- Relevant configuration
- Recent changes made

### Diagnostic Steps
1. **Initial Assessment**
   - Basic checks and validations
   - Log file analysis

2. **Systematic Investigation**
   - Step-by-step diagnostic process
   - Tools and commands to use

3. **Root Cause Identification**
   - Potential causes ranked by likelihood
   - Testing methodology

## Solution Strategy
- Immediate workarounds
- Permanent fixes
- Prevention measures

## Verification Steps
How to confirm the issue is resolved

## Documentation
Update procedures or documentation to prevent recurrence`
      }
    };

    this.outputFormats = {
      structured: {
        name: 'Structured Response',
        format: `Please structure your response with clear headings, bullet points, and organized sections for easy readability.`
      },
      stepByStep: {
        name: 'Step-by-Step Guide',
        format: `Provide your response as a numbered, step-by-step guide with clear instructions and examples for each step.`
      },
      checklist: {
        name: 'Checklist Format',
        format: `Present your response as a checklist with actionable items that can be checked off as completed.`
      },
      comparison: {
        name: 'Comparison Table',
        format: `Use tables and comparison formats to clearly show differences, pros/cons, and relative merits.`
      },
      codeExample: {
        name: 'Code-Focused Response',
        format: `Include practical code examples, snippets, and implementation details with explanations.`
      }
    };
  }

  shouldApply(prompt, options = {}) {
    if (options.skipTemplateEnhancement) return false;
    return options.template || this.detectTemplate(prompt) || options.forceTemplate;
  }

  detectTemplate(prompt) {
    // Check for explicit template triggers
    for (const [templateKey, template] of Object.entries(this.templates)) {
      if (template.trigger.test(prompt)) {
        return templateKey;
      }
    }

    // Check for implicit patterns
    if (this.isQuestionPattern(prompt)) return 'tutorial';
    if (this.isComparisonPattern(prompt)) return 'comparison';
    if (this.isProblemPattern(prompt)) return 'troubleshooting';

    return null;
  }

  isQuestionPattern(prompt) {
    return /^(how|what|why|when|where)\s/i.test(prompt) && prompt.includes('?');
  }

  isComparisonPattern(prompt) {
    return /(better|best|choose|select|recommend).*between/i.test(prompt);
  }

  isProblemPattern(prompt) {
    return /(not working|broken|error|fail|issue|problem)/i.test(prompt);
  }

  async enhance(prompt, options = {}) {
    const changes = [];
    let enhanced = prompt;

    // Determine template to apply
    const templateKey = options.template || this.detectTemplate(prompt);
    
    if (!templateKey) {
      return {
        enhanced,
        description: 'No specific template needed',
        changes: []
      };
    }

    const template = this.templates[templateKey];
    if (!template) {
      return {
        enhanced,
        description: `Unknown template: ${templateKey}`,
        changes: []
      };
    }

    // Apply template
    enhanced = this.applyTemplate(prompt, template, options);
    changes.push(`Applied ${template.name}`);

    // Add output format guidance
    const outputFormat = options.outputFormat || this.detectOutputFormat(templateKey);
    if (outputFormat && this.outputFormats[outputFormat]) {
      enhanced = this.addOutputFormatGuidance(enhanced, this.outputFormats[outputFormat]);
      changes.push(`Added ${this.outputFormats[outputFormat].name} formatting`);
    }

    // Add custom template sections if provided
    if (options.customSections) {
      enhanced = this.addCustomSections(enhanced, options.customSections);
      changes.push('Added custom template sections');
    }

    return {
      enhanced,
      description: `Applied ${template.name} with structured formatting`,
      changes
    };
  }

  applyTemplate(prompt, template, options = {}) {
    let enhanced = template.template.replace('{original}', prompt);

    // Apply template customizations
    if (options.templateCustomizations) {
      for (const [placeholder, value] of Object.entries(options.templateCustomizations)) {
        enhanced = enhanced.replace(new RegExp(`{${placeholder}}`, 'g'), value);
      }
    }

    return enhanced;
  }

  detectOutputFormat(templateKey) {
    const formatMap = {
      tutorial: 'stepByStep',
      debugging: 'structured',
      troubleshooting: 'stepByStep',
      comparison: 'comparison',
      codeReview: 'structured',
      apiDoc: 'structured',
      projectPlan: 'checklist'
    };

    return formatMap[templateKey] || 'structured';
  }

  addOutputFormatGuidance(prompt, outputFormat) {
    return `${prompt}\n\n**Output Format Requirements:**\n${outputFormat.format}`;
  }

  addCustomSections(prompt, customSections) {
    const sectionsText = customSections.map(section => {
      if (typeof section === 'string') {
        return `\n## ${section}\n[Please address this section]`;
      } else if (section.title && section.description) {
        return `\n## ${section.title}\n${section.description}`;
      }
      return '';
    }).join('');

    return `${prompt}${sectionsText}`;
  }

  // Template management methods
  getAvailableTemplates() {
    return Object.entries(this.templates).map(([key, template]) => ({
      key,
      name: template.name,
      description: template.trigger.toString(),
      trigger: template.trigger
    }));
  }

  getTemplateByKey(key) {
    return this.templates[key] || null;
  }

  addCustomTemplate(key, template) {
    if (!template.name || !template.template) {
      throw new Error('Template must have name and template properties');
    }

    this.templates[key] = {
      name: template.name,
      trigger: template.trigger || /.*/,
      template: template.template,
      custom: true
    };
  }

  removeCustomTemplate(key) {
    if (this.templates[key] && this.templates[key].custom) {
      delete this.templates[key];
      return true;
    }
    return false;
  }

  getOutputFormats() {
    return Object.entries(this.outputFormats).map(([key, format]) => ({
      key,
      name: format.name,
      description: format.format
    }));
  }

  previewTemplate(templateKey, samplePrompt) {
    const template = this.templates[templateKey];
    if (!template) {
      throw new Error(`Template '${templateKey}' not found`);
    }

    return template.template.replace('{original}', samplePrompt || '[Your prompt here]');
  }
}

module.exports = TemplateEnhancer;