class PromptEnhancer {
  constructor(config = {}) {
    this.config = {
      enableTextExpansion: true,
      enableContextInjection: true,
      enableRoleBasedEnhancement: true,
      enableTemplateBasedEnhancement: true,
      enableAIOptimization: true,
      ...config
    };
    
    this.enhancers = [];
    this.initializeEnhancers();
  }

  initializeEnhancers() {
    if (this.config.enableTextExpansion) {
      this.enhancers.push(require('./enhancers/TextExpander'));
    }
    if (this.config.enableContextInjection) {
      this.enhancers.push(require('./enhancers/ContextInjector'));
    }
    if (this.config.enableRoleBasedEnhancement) {
      this.enhancers.push(require('./enhancers/RoleEnhancer'));
    }
    if (this.config.enableTemplateBasedEnhancement) {
      this.enhancers.push(require('./enhancers/TemplateEnhancer'));
    }
    if (this.config.enableAIOptimization) {
      this.enhancers.push(require('./enhancers/AIOptimizer'));
    }
  }

  async enhance(prompt, options = {}) {
    let enhancedPrompt = prompt;
    const metadata = {
      originalLength: prompt.length,
      enhancementsApplied: [],
      processingTime: 0
    };

    const startTime = Date.now();

    try {
      for (const EnhancerClass of this.enhancers) {
        const enhancer = new EnhancerClass(this.config);
        
        if (enhancer.shouldApply && !enhancer.shouldApply(enhancedPrompt, options)) {
          continue;
        }

        const result = await enhancer.enhance(enhancedPrompt, options);
        
        if (result.enhanced && result.enhanced !== enhancedPrompt) {
          enhancedPrompt = result.enhanced;
          metadata.enhancementsApplied.push({
            type: enhancer.constructor.name,
            description: result.description || 'Applied enhancement',
            changes: result.changes || []
          });
        }
      }

      metadata.processingTime = Date.now() - startTime;
      metadata.finalLength = enhancedPrompt.length;
      metadata.expansionRatio = metadata.finalLength / metadata.originalLength;

      return {
        original: prompt,
        enhanced: enhancedPrompt,
        metadata
      };

    } catch (error) {
      throw new Error(`Prompt enhancement failed: ${error.message}`);
    }
  }

  getAvailableEnhancers() {
    return this.enhancers.map(EnhancerClass => ({
      name: EnhancerClass.name,
      description: EnhancerClass.description || 'No description available'
    }));
  }

  updateConfig(newConfig) {
    this.config = { ...this.config, ...newConfig };
    this.enhancers = [];
    this.initializeEnhancers();
  }
}

module.exports = PromptEnhancer;