class ContextInjector {
  static description = 'Injects relevant context, background information, and environmental details into prompts';

  constructor(config = {}) {
    this.config = config;
    this.contextTypes = {
      temporal: {
        current: () => new Date().toLocaleString(),
        date: () => new Date().toLocaleDateString(),
        time: () => new Date().toLocaleTimeString(),
        year: () => new Date().getFullYear(),
        timezone: () => Intl.DateTimeFormat().resolvedOptions().timeZone
      },
      environmental: {
        platform: () => process.platform,
        nodeVersion: () => process.version,
        workingDirectory: () => process.cwd(),
        environment: () => process.env.NODE_ENV || 'development'
      },
      domain: {
        web: ['HTML5', 'CSS3', 'JavaScript ES6+', 'responsive design', 'accessibility', 'SEO'],
        backend: ['REST APIs', 'databases', 'authentication', 'security', 'performance', 'scalability'],
        frontend: ['user experience', 'component architecture', 'state management', 'performance optimization'],
        mobile: ['responsive design', 'touch interfaces', 'mobile performance', 'app store guidelines'],
        database: ['data modeling', 'query optimization', 'indexing', 'transactions', 'normalization'],
        devops: ['CI/CD', 'containerization', 'monitoring', 'logging', 'deployment strategies'],
        security: ['authentication', 'authorization', 'encryption', 'OWASP guidelines', 'vulnerability assessment'],
        ai: ['machine learning', 'natural language processing', 'data preprocessing', 'model evaluation']
      }
    };

    this.contextRules = [
      {
        trigger: /code|program|software|develop/i,
        contexts: ['environmental', 'domain:backend', 'domain:web'],
        priority: 'high'
      },
      {
        trigger: /design|ui|ux|interface/i,
        contexts: ['domain:frontend', 'domain:web'],
        priority: 'medium'
      },
      {
        trigger: /database|sql|data/i,
        contexts: ['domain:database', 'environmental'],
        priority: 'high'
      },
      {
        trigger: /deploy|server|infrastructure/i,
        contexts: ['domain:devops', 'environmental'],
        priority: 'high'
      },
      {
        trigger: /security|auth|encrypt/i,
        contexts: ['domain:security'],
        priority: 'critical'
      },
      {
        trigger: /mobile|app|responsive/i,
        contexts: ['domain:mobile', 'domain:frontend'],
        priority: 'medium'
      },
      {
        trigger: /ai|machine learning|ml|neural/i,
        contexts: ['domain:ai', 'environmental'],
        priority: 'medium'
      }
    ];
  }

  shouldApply(prompt, options = {}) {
    if (options.skipContextInjection) return false;
    return this.needsContext(prompt) || options.forceContext;
  }

  needsContext(prompt) {
    return this.contextRules.some(rule => rule.trigger.test(prompt));
  }

  async enhance(prompt, options = {}) {
    const changes = [];
    let enhanced = prompt;

    // Determine relevant contexts
    const relevantContexts = this.identifyRelevantContexts(prompt, options);
    
    if (relevantContexts.length === 0) {
      return { enhanced, description: 'No additional context needed', changes: [] };
    }

    // Inject temporal context if requested or detected
    if (options.includeTemporal || this.needsTemporalContext(prompt)) {
      const temporalContext = this.buildTemporalContext(options.temporalType);
      if (temporalContext) {
        enhanced = this.injectContext(enhanced, temporalContext, 'temporal');
        changes.push('Added temporal context');
      }
    }

    // Inject environmental context
    if (relevantContexts.includes('environmental')) {
      const envContext = this.buildEnvironmentalContext();
      enhanced = this.injectContext(enhanced, envContext, 'environmental');
      changes.push('Added environmental context');
    }

    // Inject domain-specific contexts
    const domainContexts = relevantContexts.filter(ctx => ctx.startsWith('domain:'));
    for (const domainContext of domainContexts) {
      const domain = domainContext.split(':')[1];
      const contextInfo = this.buildDomainContext(domain);
      enhanced = this.injectContext(enhanced, contextInfo, `domain-${domain}`);
      changes.push(`Added ${domain} domain context`);
    }

    // Inject custom context if provided
    if (options.customContext) {
      enhanced = this.injectContext(enhanced, options.customContext, 'custom');
      changes.push('Added custom context');
    }

    return {
      enhanced,
      description: 'Injected relevant contextual information',
      changes
    };
  }

  identifyRelevantContexts(prompt, options = {}) {
    const contexts = new Set();

    // Apply context rules
    for (const rule of this.contextRules) {
      if (rule.trigger.test(prompt)) {
        rule.contexts.forEach(ctx => contexts.add(ctx));
      }
    }

    // Add explicit contexts from options
    if (options.contexts) {
      options.contexts.forEach(ctx => contexts.add(ctx));
    }

    return Array.from(contexts);
  }

  needsTemporalContext(prompt) {
    const temporalKeywords = ['now', 'today', 'current', 'latest', 'recent', 'when', 'time'];
    return temporalKeywords.some(keyword => 
      prompt.toLowerCase().includes(keyword)
    );
  }

  buildTemporalContext(type = 'current') {
    const contextBuilder = this.contextTypes.temporal[type];
    if (!contextBuilder) return null;

    try {
      return `Current context: ${contextBuilder()}`;
    } catch (error) {
      return null;
    }
  }

  buildEnvironmentalContext() {
    const env = this.contextTypes.environmental;
    return `Environment: ${env.platform()} | Node ${env.nodeVersion()} | ${env.environment()} mode`;
  }

  buildDomainContext(domain) {
    const domainInfo = this.contextTypes.domain[domain];
    if (!domainInfo) return null;

    return `Consider ${domain} best practices including: ${domainInfo.slice(0, 3).join(', ')}`;
  }

  injectContext(prompt, context, type) {
    const contextLabel = this.getContextLabel(type);
    
    // Check if prompt already has context section
    if (prompt.includes('Context:') || prompt.includes('Additional context:')) {
      return `${prompt}\n${contextLabel}: ${context}`;
    }

    // Inject context at the beginning for critical contexts, end for others
    const criticalTypes = ['security', 'environmental'];
    const isCritical = criticalTypes.some(critical => type.includes(critical));

    if (isCritical) {
      return `${contextLabel}: ${context}\n\n${prompt}`;
    }

    return `${prompt}\n\n${contextLabel}: ${context}`;
  }

  getContextLabel(type) {
    const labels = {
      temporal: 'Timing Context',
      environmental: 'Environment Context',
      custom: 'Additional Context',
      'domain-web': 'Web Development Context',
      'domain-backend': 'Backend Development Context',
      'domain-frontend': 'Frontend Development Context',
      'domain-mobile': 'Mobile Development Context',
      'domain-database': 'Database Context',
      'domain-devops': 'DevOps Context',
      'domain-security': 'Security Context',
      'domain-ai': 'AI/ML Context'
    };

    return labels[type] || 'Context';
  }

  // Utility method to get available context types
  getAvailableContextTypes() {
    return {
      temporal: Object.keys(this.contextTypes.temporal),
      environmental: Object.keys(this.contextTypes.environmental),
      domain: Object.keys(this.contextTypes.domain)
    };
  }
}

module.exports = ContextInjector;