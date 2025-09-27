class AIOptimizer {
  static description = 'Applies AI-specific optimization patterns that work better with Large Language Models';

  constructor(config = {}) {
    this.config = config;
    
    // Patterns that improve AI performance
    this.optimizationPatterns = {
      clarity: {
        name: 'Clarity Enhancement',
        description: 'Makes instructions clearer and more specific',
        rules: [
          'Use specific action verbs instead of vague language',
          'Replace ambiguous terms with precise descriptions',
          'Add concrete examples where helpful',
          'Structure complex requests into clear steps'
        ]
      },
      
      context: {
        name: 'Context Optimization',
        description: 'Provides necessary context for better responses',
        rules: [
          'Include relevant background information',
          'Specify the target audience or use case',
          'Mention any constraints or requirements',
          'Clarify the expected output format'
        ]
      },
      
      specificity: {
        name: 'Specificity Enhancement',
        description: 'Makes requests more specific and actionable',
        rules: [
          'Define scope and boundaries clearly',
          'Specify quality criteria and standards',
          'Include measurable outcomes where possible',
          'Provide concrete examples of desired output'
        ]
      },
      
      structure: {
        name: 'Structural Optimization',
        description: 'Organizes prompts for better AI comprehension',
        rules: [
          'Use clear headings and sections',
          'Present information in logical order',
          'Separate different types of instructions',
          'Use consistent formatting and terminology'
        ]
      }
    };

    // Specific techniques that work well with LLMs
    this.llmTechniques = {
      chainOfThought: {
        trigger: /complex|analyze|reason|think|solve/i,
        instruction: "Let's think step by step:",
        description: 'Encourages systematic reasoning'
      },
      
      fewShotLearning: {
        trigger: /example|format|style|pattern/i,
        instruction: "Here are some examples to guide your response:",
        description: 'Provides examples for pattern recognition'
      },
      
      rolePlay: {
        trigger: /expert|professional|specialist/i,
        instruction: "Approach this as an expert would:",
        description: 'Activates domain-specific knowledge'
      },
      
      constraintSetting: {
        trigger: /limit|restrict|avoid|must|should/i,
        instruction: "Please adhere to these specific constraints:",
        description: 'Sets clear boundaries and requirements'
      },
      
      outputStructuring: {
        trigger: /list|format|organize|structure/i,
        instruction: "Structure your response as follows:",
        description: 'Guides response organization'
      }
    };

    // Common AI prompt anti-patterns to fix
    this.antiPatterns = {
      vagueness: {
        pattern: /help|fix|improve|better|good/i,
        fix: 'Replace vague terms with specific action requests'
      },
      
      multipleQuestions: {
        pattern: /\?.*\?.*\?/,
        fix: 'Break multiple questions into separate, focused requests'
      },
      
      assumptionHeavy: {
        pattern: /obviously|clearly|of course|everyone knows/i,
        fix: 'Remove assumptions and provide necessary context'
      },
      
      commandChaining: {
        pattern: /and then|also|additionally.*and/i,
        fix: 'Structure multiple requests as ordered steps'
      },
      
      negativeFraming: {
        pattern: /don't|avoid|not|never.*don't/i,
        fix: 'Frame instructions positively when possible'
      }
    };

    // Performance optimization strategies
    this.performanceOptimizations = {
      tokenEfficiency: {
        name: 'Token Optimization',
        strategies: [
          'Remove redundant words and phrases',
          'Use concise but clear language',
          'Combine related instructions',
          'Eliminate unnecessary qualifiers'
        ]
      },
      
      contextRelevance: {
        name: 'Context Relevance',
        strategies: [
          'Include only directly relevant context',
          'Priority-order information by importance',
          'Remove tangential details',
          'Focus on actionable information'
        ]
      },
      
      responseGuidance: {
        name: 'Response Guidance',
        strategies: [
          'Specify desired response length',
          'Indicate preferred format or structure',
          'Set quality expectations',
          'Provide success criteria'
        ]
      }
    };
  }

  shouldApply(prompt, options = {}) {
    if (options.skipAIOptimization) return false;
    
    // Always apply if forced or if prompt has optimization opportunities
    return options.forceAIOptimization || 
           this.hasOptimizationOpportunities(prompt) ||
           prompt.length > 20; // Most prompts can benefit from some optimization
  }

  hasOptimizationOpportunities(prompt) {
    // Check for anti-patterns
    for (const antiPattern of Object.values(this.antiPatterns)) {
      if (antiPattern.pattern.test(prompt)) {
        return true;
      }
    }
    
    // Check for optimization triggers
    for (const technique of Object.values(this.llmTechniques)) {
      if (technique.trigger.test(prompt)) {
        return true;
      }
    }
    
    return false;
  }

  async enhance(prompt, options = {}) {
    const changes = [];
    let enhanced = prompt;

    // Step 1: Fix anti-patterns
    const antiPatternResult = this.fixAntiPatterns(enhanced);
    if (antiPatternResult.changed) {
      enhanced = antiPatternResult.enhanced;
      changes.push(...antiPatternResult.changes);
    }

    // Step 2: Apply LLM-specific techniques
    const techniqueResult = this.applyLLMTechniques(enhanced, options);
    if (techniqueResult.changed) {
      enhanced = techniqueResult.enhanced;
      changes.push(...techniqueResult.changes);
    }

    // Step 3: Optimize for clarity and structure
    const clarityResult = this.optimizeClarity(enhanced, options);
    if (clarityResult.changed) {
      enhanced = clarityResult.enhanced;
      changes.push(...clarityResult.changes);
    }

    // Step 4: Add performance optimizations
    const performanceResult = this.applyPerformanceOptimizations(enhanced, options);
    if (performanceResult.changed) {
      enhanced = performanceResult.enhanced;
      changes.push(...performanceResult.changes);
    }

    // Step 5: Add AI-specific guidance
    const guidanceResult = this.addAIGuidance(enhanced, options);
    if (guidanceResult.changed) {
      enhanced = guidanceResult.enhanced;
      changes.push('Added AI-specific guidance');
    }

    return {
      enhanced,
      description: 'Applied AI optimization patterns for better LLM performance',
      changes
    };
  }

  fixAntiPatterns(prompt) {
    let enhanced = prompt;
    const changes = [];

    // Fix vague language
    if (this.antiPatterns.vagueness.pattern.test(prompt)) {
      enhanced = this.fixVagueLanguage(enhanced);
      changes.push('Fixed vague language');
    }

    // Handle multiple questions
    if (this.antiPatterns.multipleQuestions.pattern.test(prompt)) {
      enhanced = this.structureMultipleQuestions(enhanced);
      changes.push('Structured multiple questions');
    }

    // Remove assumptions
    if (this.antiPatterns.assumptionHeavy.pattern.test(prompt)) {
      enhanced = this.removeAssumptions(enhanced);
      changes.push('Removed assumptive language');
    }

    // Structure command chains
    if (this.antiPatterns.commandChaining.pattern.test(prompt)) {
      enhanced = this.structureCommands(enhanced);
      changes.push('Structured command chains');
    }

    return {
      enhanced,
      changed: changes.length > 0,
      changes
    };
  }

  fixVagueLanguage(prompt) {
    const vagueToSpecific = {
      'help me': 'please provide detailed guidance on',
      'fix this': 'identify and resolve the specific issue with',
      'make it better': 'improve by optimizing',
      'this is good': 'this meets the requirements because',
      'improve this': 'enhance by focusing on'
    };

    let enhanced = prompt;
    for (const [vague, specific] of Object.entries(vagueToSpecific)) {
      enhanced = enhanced.replace(new RegExp(vague, 'gi'), specific);
    }

    return enhanced;
  }

  structureMultipleQuestions(prompt) {
    // If multiple questions detected, suggest structuring
    const questionCount = (prompt.match(/\?/g) || []).length;
    
    if (questionCount > 1) {
      return `Please address the following questions in order:\n\n${prompt}\n\nPlease structure your response with clear sections for each question.`;
    }
    
    return prompt;
  }

  removeAssumptions(prompt) {
    const assumptiveWords = ['obviously', 'clearly', 'of course', 'everyone knows'];
    let enhanced = prompt;
    
    assumptiveWords.forEach(word => {
      const regex = new RegExp(`\\b${word}\\b,?\\s*`, 'gi');
      enhanced = enhanced.replace(regex, '');
    });
    
    return enhanced;
  }

  structureCommands(prompt) {
    // If multiple commands detected, suggest numbering
    if (/and then|also.*and|additionally.*and/i.test(prompt)) {
      return `${prompt}\n\nPlease approach this systematically, addressing each requirement in sequence.`;
    }
    return prompt;
  }

  applyLLMTechniques(prompt, options = {}) {
    let enhanced = prompt;
    const changes = [];

    // Apply relevant LLM techniques based on triggers
    for (const [techniqueKey, technique] of Object.entries(this.llmTechniques)) {
      if (technique.trigger.test(prompt)) {
        const result = this.applySpecificTechnique(enhanced, technique, options);
        if (result.changed) {
          enhanced = result.enhanced;
          changes.push(`Applied ${technique.description}`);
        }
      }
    }

    return {
      enhanced,
      changed: changes.length > 0,
      changes
    };
  }

  applySpecificTechnique(prompt, technique, options = {}) {
    switch (technique.instruction) {
      case "Let's think step by step:":
        return this.applyChainOfThought(prompt);
      
      case "Here are some examples to guide your response:":
        return this.applyFewShotLearning(prompt, options);
      
      case "Approach this as an expert would:":
        return this.applyRolePlay(prompt);
      
      case "Please adhere to these specific constraints:":
        return this.applyConstraintSetting(prompt, options);
      
      case "Structure your response as follows:":
        return this.applyOutputStructuring(prompt, options);
      
      default:
        return { enhanced: prompt, changed: false };
    }
  }

  applyChainOfThought(prompt) {
    if (!/step by step|think through|reason/i.test(prompt)) {
      return {
        enhanced: `${prompt}\n\nPlease think through this step by step and show your reasoning process.`,
        changed: true
      };
    }
    return { enhanced: prompt, changed: false };
  }

  applyFewShotLearning(prompt, options = {}) {
    if (options.examples) {
      const exampleText = options.examples.map((example, index) => 
        `Example ${index + 1}: ${example}`
      ).join('\n');
      
      return {
        enhanced: `${prompt}\n\nHere are some examples to guide your response:\n${exampleText}`,
        changed: true
      };
    }
    return { enhanced: prompt, changed: false };
  }

  applyRolePlay(prompt) {
    if (!/role|expert|professional|specialist/i.test(prompt)) {
      return {
        enhanced: `Please approach this with relevant professional expertise:\n\n${prompt}`,
        changed: true
      };
    }
    return { enhanced: prompt, changed: false };
  }

  applyConstraintSetting(prompt, options = {}) {
    const constraints = options.constraints || [];
    if (constraints.length > 0) {
      const constraintText = constraints.map(c => `- ${c}`).join('\n');
      return {
        enhanced: `${prompt}\n\nPlease adhere to these constraints:\n${constraintText}`,
        changed: true
      };
    }
    return { enhanced: prompt, changed: false };
  }

  applyOutputStructuring(prompt, options = {}) {
    const structure = options.outputStructure;
    if (structure) {
      return {
        enhanced: `${prompt}\n\nPlease structure your response as follows:\n${structure}`,
        changed: true
      };
    }
    return { enhanced: prompt, changed: false };
  }

  optimizeClarity(prompt, options = {}) {
    let enhanced = prompt;
    const changes = [];

    // Add specificity if needed
    if (this.needsMoreSpecificity(prompt)) {
      enhanced = this.addSpecificity(enhanced);
      changes.push('Enhanced specificity');
    }

    // Improve structure if needed
    if (this.needsBetterStructure(prompt)) {
      enhanced = this.improveStructure(enhanced);
      changes.push('Improved structural clarity');
    }

    return {
      enhanced,
      changed: changes.length > 0,
      changes
    };
  }

  needsMoreSpecificity(prompt) {
    const vagueIndicators = ['something', 'anything', 'stuff', 'things', 'it', 'this', 'that'];
    return vagueIndicators.some(indicator => 
      prompt.toLowerCase().includes(indicator)
    );
  }

  addSpecificity(prompt) {
    return `${prompt}\n\nPlease be specific and provide concrete details in your response.`;
  }

  needsBetterStructure(prompt) {
    return prompt.length > 200 && !prompt.includes('\n') && !prompt.match(/\d+\./);
  }

  improveStructure(prompt) {
    return `${prompt}\n\nPlease organize your response with clear sections and logical flow.`;
  }

  applyPerformanceOptimizations(prompt, options = {}) {
    let enhanced = prompt;
    const changes = [];

    // Token efficiency
    if (options.optimizeTokens !== false) {
      const tokenResult = this.optimizeTokenUsage(enhanced);
      if (tokenResult.changed) {
        enhanced = tokenResult.enhanced;
        changes.push('Optimized token usage');
      }
    }

    // Context relevance
    const contextResult = this.optimizeContextRelevance(enhanced, options);
    if (contextResult.changed) {
      enhanced = contextResult.enhanced;
      changes.push('Optimized context relevance');
    }

    return {
      enhanced,
      changed: changes.length > 0,
      changes
    };
  }

  optimizeTokenUsage(prompt) {
    let enhanced = prompt;
    let changed = false;

    // Remove redundant words
    const redundantPhrases = [
      'please note that',
      'it should be noted that',
      'it is important to',
      'you should know that',
      'I would like to',
      'I need you to'
    ];

    redundantPhrases.forEach(phrase => {
      const original = enhanced;
      enhanced = enhanced.replace(new RegExp(phrase, 'gi'), '');
      if (enhanced !== original) changed = true;
    });

    // Consolidate repeated instructions
    if (enhanced.includes('please') && enhanced.match(/please/gi).length > 2) {
      enhanced = enhanced.replace(/please\s+/gi, '').replace(/^/, 'Please ');
      changed = true;
    }

    return { enhanced, changed };
  }

  optimizeContextRelevance(prompt, options = {}) {
    // This would require more sophisticated analysis
    // For now, just ensure context is clearly marked
    if (options.context && !prompt.includes('Context:')) {
      return {
        enhanced: `Context: ${options.context}\n\n${prompt}`,
        changed: true
      };
    }
    
    return { enhanced: prompt, changed: false };
  }

  addAIGuidance(prompt, options = {}) {
    const guidance = [];
    
    // Add response quality guidance
    if (options.quality !== false) {
      guidance.push('Provide a comprehensive and well-reasoned response');
    }
    
    // Add format guidance if not already specified
    if (!prompt.match(/format|structure/) && options.format !== false) {
      guidance.push('Use clear formatting with headings and bullet points where appropriate');
    }
    
    if (guidance.length === 0) {
      return { enhanced: prompt, changed: false };
    }
    
    const guidanceText = guidance.join('. ') + '.';
    return {
      enhanced: `${prompt}\n\nResponse guidance: ${guidanceText}`,
      changed: true
    };
  }

  // Utility methods
  analyzePrompt(prompt) {
    const analysis = {
      length: prompt.length,
      tokenEstimate: Math.ceil(prompt.length / 4), // Rough estimate
      hasAntiPatterns: [],
      suggestedTechniques: [],
      clarityScore: this.calculateClarityScore(prompt),
      optimizationOpportunities: []
    };

    // Check for anti-patterns
    for (const [key, antiPattern] of Object.entries(this.antiPatterns)) {
      if (antiPattern.pattern.test(prompt)) {
        analysis.hasAntiPatterns.push(key);
      }
    }

    // Check for applicable techniques
    for (const [key, technique] of Object.entries(this.llmTechniques)) {
      if (technique.trigger.test(prompt)) {
        analysis.suggestedTechniques.push(key);
      }
    }

    return analysis;
  }

  calculateClarityScore(prompt) {
    let score = 100;
    
    // Deduct for vague language
    if (this.antiPatterns.vagueness.pattern.test(prompt)) score -= 20;
    
    // Deduct for multiple questions
    const questionCount = (prompt.match(/\?/g) || []).length;
    if (questionCount > 1) score -= questionCount * 10;
    
    // Deduct for assumptions
    if (this.antiPatterns.assumptionHeavy.pattern.test(prompt)) score -= 15;
    
    // Add for specific language
    if (prompt.match(/specific|exactly|precisely|detailed/i)) score += 10;
    
    return Math.max(0, Math.min(100, score));
  }
}

module.exports = AIOptimizer;