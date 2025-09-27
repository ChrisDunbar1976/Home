class TextExpander {
  static description = 'Expands brief prompts into detailed, structured ones with context and specificity';

  constructor(config = {}) {
    this.config = config;
    this.expansionPatterns = {
      questions: {
        trigger: /^(what|how|why|when|where|who)\s/i,
        template: 'Please provide a comprehensive explanation about: {original}. Include relevant details, examples, and context where appropriate.'
      },
      commands: {
        trigger: /^(create|build|make|generate|write|design)\s/i,
        template: 'I need you to {original}. Please ensure the output is well-structured, follows best practices, and includes appropriate documentation or explanations.'
      },
      analysis: {
        trigger: /^(analyze|review|examine|evaluate|assess)\s/i,
        template: 'Please conduct a thorough analysis of: {original}. Provide detailed insights, identify key points, and offer actionable recommendations.'
      },
      comparison: {
        trigger: /^(compare|contrast|difference)\s/i,
        template: 'Please provide a detailed comparison: {original}. Include similarities, differences, pros and cons, and conclude with recommendations if applicable.'
      },
      explanation: {
        trigger: /^(explain|describe|tell me about)\s/i,
        template: 'Please provide a clear and detailed explanation of: {original}. Break down complex concepts, provide examples, and ensure the explanation is accessible to the intended audience.'
      }
    };

    this.contextExpansions = {
      technical: ['Include technical specifications', 'Consider performance implications', 'Address security considerations', 'Mention best practices'],
      creative: ['Think creatively and innovatively', 'Consider multiple approaches', 'Focus on user experience', 'Ensure originality'],
      business: ['Consider business impact', 'Include cost-benefit analysis', 'Think about scalability', 'Address stakeholder concerns'],
      educational: ['Use clear, simple language', 'Provide step-by-step guidance', 'Include examples and illustrations', 'Check for comprehension']
    };
  }

  shouldApply(prompt, options = {}) {
    if (options.skipTextExpansion) return false;
    return prompt.length < 100 || this.isVaguePrompt(prompt);
  }

  isVaguePrompt(prompt) {
    const vagueWords = ['help', 'fix', 'improve', 'better', 'good', 'nice', 'please', 'thanks'];
    const words = prompt.toLowerCase().split(/\s+/);
    return vagueWords.some(vague => words.includes(vague)) && prompt.length < 50;
  }

  async enhance(prompt, options = {}) {
    const changes = [];
    let enhanced = prompt;

    // Apply pattern-based expansion
    const patternResult = this.applyPatternExpansion(prompt);
    if (patternResult.applied) {
      enhanced = patternResult.enhanced;
      changes.push(`Applied ${patternResult.pattern} pattern expansion`);
    }

    // Add context-specific guidance
    const contextResult = this.addContextualGuidance(enhanced, options.context);
    if (contextResult.applied) {
      enhanced = contextResult.enhanced;
      changes.push('Added contextual guidance');
    }

    // Improve specificity
    const specificityResult = this.improveSpecificity(enhanced, options);
    if (specificityResult.applied) {
      enhanced = specificityResult.enhanced;
      changes.push('Improved specificity and clarity');
    }

    return {
      enhanced,
      description: 'Expanded brief prompt with additional context and structure',
      changes
    };
  }

  applyPatternExpansion(prompt) {
    for (const [patternName, pattern] of Object.entries(this.expansionPatterns)) {
      if (pattern.trigger.test(prompt)) {
        const enhanced = pattern.template.replace('{original}', prompt);
        return {
          applied: true,
          enhanced,
          pattern: patternName
        };
      }
    }
    return { applied: false };
  }

  addContextualGuidance(prompt, context) {
    if (!context || !this.contextExpansions[context]) {
      return { applied: false };
    }

    const guidance = this.contextExpansions[context];
    const guidanceText = guidance.map(g => `- ${g}`).join('\n');
    
    const enhanced = `${prompt}\n\nAdditional considerations:\n${guidanceText}`;
    
    return {
      applied: true,
      enhanced
    };
  }

  improveSpecificity(prompt, options = {}) {
    const improvements = [];
    let enhanced = prompt;

    // Add output format specification if not present
    if (!prompt.match(/format|structure|output/i) && !options.format) {
      improvements.push('Please format your response clearly and systematically.');
    }

    // Add detail level specification
    if (!prompt.match(/detail|comprehensive|thorough|brief/i)) {
      improvements.push('Provide an appropriate level of detail for the context.');
    }

    // Add target audience specification if technical content detected
    if (this.hasTechnicalContent(prompt) && !prompt.match(/audience|level|experience/i)) {
      improvements.push('Consider the technical expertise level of your audience.');
    }

    if (improvements.length > 0) {
      enhanced = `${prompt}\n\nGuidance: ${improvements.join(' ')}`;
      return {
        applied: true,
        enhanced
      };
    }

    return { applied: false };
  }

  hasTechnicalContent(prompt) {
    const technicalKeywords = [
      'code', 'programming', 'software', 'algorithm', 'database', 'API', 'framework',
      'library', 'function', 'method', 'class', 'variable', 'server', 'client',
      'deployment', 'architecture', 'design pattern', 'debugging', 'testing'
    ];
    
    const lowercasePrompt = prompt.toLowerCase();
    return technicalKeywords.some(keyword => lowercasePrompt.includes(keyword));
  }
}

module.exports = TextExpander;