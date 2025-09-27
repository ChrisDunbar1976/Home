class RoleEnhancer {
  static description = 'Enhances prompts by adding specific roles, personas, and expertise contexts';

  constructor(config = {}) {
    this.config = config;
    this.roles = {
      // Technical roles
      developer: {
        name: 'Expert Software Developer',
        persona: 'You are an experienced software developer with deep knowledge of programming languages, frameworks, and best practices.',
        expertise: ['clean code', 'design patterns', 'testing', 'debugging', 'performance optimization'],
        communication: 'technical and precise',
        keywords: ['code', 'program', 'develop', 'implement', 'build', 'create software']
      },
      architect: {
        name: 'Software Architect',
        persona: 'You are a senior software architect with expertise in system design, scalability, and technical strategy.',
        expertise: ['system design', 'scalability', 'microservices', 'distributed systems', 'technology selection'],
        communication: 'strategic and comprehensive',
        keywords: ['architecture', 'design', 'system', 'scalability', 'infrastructure']
      },
      devops: {
        name: 'DevOps Engineer',
        persona: 'You are a DevOps engineer specializing in CI/CD, automation, and infrastructure management.',
        expertise: ['automation', 'containerization', 'cloud platforms', 'monitoring', 'deployment'],
        communication: 'operational and practical',
        keywords: ['deploy', 'infrastructure', 'automation', 'docker', 'kubernetes', 'ci/cd']
      },
      security: {
        name: 'Security Expert',
        persona: 'You are a cybersecurity specialist with deep knowledge of security best practices and threat mitigation.',
        expertise: ['vulnerability assessment', 'encryption', 'authentication', 'compliance', 'threat modeling'],
        communication: 'security-focused and thorough',
        keywords: ['security', 'secure', 'vulnerability', 'encrypt', 'auth', 'attack', 'protect']
      },
      
      // Business roles
      analyst: {
        name: 'Business Analyst',
        persona: 'You are a business analyst who bridges the gap between business needs and technical solutions.',
        expertise: ['requirements gathering', 'stakeholder management', 'process optimization', 'documentation'],
        communication: 'business-oriented and clear',
        keywords: ['business', 'requirements', 'process', 'stakeholder', 'analysis', 'optimize']
      },
      consultant: {
        name: 'Technology Consultant',
        persona: 'You are a technology consultant who provides strategic advice and solutions to complex business problems.',
        expertise: ['strategic planning', 'technology assessment', 'digital transformation', 'ROI analysis'],
        communication: 'consultative and strategic',
        keywords: ['strategy', 'consulting', 'advice', 'recommendation', 'transformation']
      },
      
      // Creative roles
      designer: {
        name: 'UX/UI Designer',
        persona: 'You are a user experience and interface designer focused on creating intuitive and beautiful digital experiences.',
        expertise: ['user research', 'interaction design', 'visual design', 'prototyping', 'accessibility'],
        communication: 'design-focused and user-centric',
        keywords: ['design', 'ui', 'ux', 'interface', 'user', 'visual', 'prototype']
      },
      writer: {
        name: 'Technical Writer',
        persona: 'You are a technical writer who specializes in creating clear, comprehensive documentation and content.',
        expertise: ['documentation', 'content strategy', 'information architecture', 'editing'],
        communication: 'clear and structured',
        keywords: ['write', 'document', 'content', 'guide', 'manual', 'explanation']
      },
      
      // Educational roles
      mentor: {
        name: 'Technical Mentor',
        persona: 'You are an experienced mentor who guides others in their technical learning journey.',
        expertise: ['teaching', 'knowledge transfer', 'skill development', 'career guidance'],
        communication: 'supportive and educational',
        keywords: ['teach', 'learn', 'mentor', 'guide', 'help', 'explain', 'tutorial']
      },
      trainer: {
        name: 'Technology Trainer',
        persona: 'You are a professional trainer who develops and delivers technical training programs.',
        expertise: ['curriculum development', 'instructional design', 'hands-on training', 'assessment'],
        communication: 'instructional and engaging',
        keywords: ['train', 'course', 'workshop', 'education', 'skill', 'certification']
      },
      
      // Specialized roles
      researcher: {
        name: 'Technology Researcher',
        persona: 'You are a technology researcher who investigates emerging trends and evaluates new technologies.',
        expertise: ['technology evaluation', 'research methodology', 'trend analysis', 'comparative analysis'],
        communication: 'analytical and evidence-based',
        keywords: ['research', 'investigate', 'analyze', 'study', 'evaluate', 'compare']
      },
      troubleshooter: {
        name: 'Technical Troubleshooter',
        persona: 'You are a systematic problem solver who excels at diagnosing and resolving technical issues.',
        expertise: ['problem diagnosis', 'root cause analysis', 'debugging', 'systematic troubleshooting'],
        communication: 'methodical and solution-oriented',
        keywords: ['fix', 'debug', 'troubleshoot', 'problem', 'issue', 'error', 'solve']
      }
    };

    this.rolePatterns = {
      expertise: /expert|professional|specialist|advanced/i,
      beginner: /beginner|new|start|learn|basic/i,
      team: /team|group|collaborate|meeting/i,
      leadership: /lead|manage|direct|strategy/i,
      creative: /creative|innovative|brainstorm|idea/i
    };
  }

  shouldApply(prompt, options = {}) {
    if (options.skipRoleEnhancement) return false;
    return options.role || this.detectImplicitRole(prompt) || options.forceRole;
  }

  detectImplicitRole(prompt) {
    const promptLower = prompt.toLowerCase();
    
    // Check for explicit role mentions
    for (const [roleKey, role] of Object.entries(this.roles)) {
      if (role.keywords.some(keyword => promptLower.includes(keyword))) {
        return roleKey;
      }
    }

    // Check for role patterns
    if (this.rolePatterns.beginner.test(prompt)) return 'mentor';
    if (this.rolePatterns.leadership.test(prompt)) return 'consultant';
    if (this.rolePatterns.creative.test(prompt)) return 'designer';
    if (this.rolePatterns.team.test(prompt)) return 'analyst';

    return null;
  }

  async enhance(prompt, options = {}) {
    const changes = [];
    let enhanced = prompt;

    // Determine the role to apply
    const targetRole = options.role || this.detectImplicitRole(prompt);
    
    if (!targetRole) {
      return {
        enhanced,
        description: 'No specific role enhancement needed',
        changes: []
      };
    }

    const role = this.roles[targetRole];
    if (!role) {
      return {
        enhanced,
        description: `Unknown role: ${targetRole}`,
        changes: []
      };
    }

    // Apply role enhancement
    const roleContext = this.buildRoleContext(role, options);
    enhanced = this.applyRoleToPrompt(prompt, roleContext, options);
    changes.push(`Applied ${role.name} role enhancement`);

    // Add expertise context if needed
    if (options.includeExpertise !== false) {
      const expertiseContext = this.buildExpertiseContext(role);
      enhanced = this.addExpertiseGuidance(enhanced, expertiseContext);
      changes.push('Added expertise-specific guidance');
    }

    // Adjust communication style
    if (options.adjustCommunication !== false) {
      const communicationGuidance = this.buildCommunicationGuidance(role, options);
      enhanced = this.addCommunicationStyle(enhanced, communicationGuidance);
      changes.push('Adjusted communication style for role');
    }

    return {
      enhanced,
      description: `Enhanced prompt with ${role.name} persona and expertise`,
      changes
    };
  }

  buildRoleContext(role, options = {}) {
    const context = {
      persona: role.persona,
      name: role.name,
      expertise: role.expertise,
      communication: role.communication
    };

    // Add custom role attributes if provided
    if (options.customAttributes) {
      context.customAttributes = options.customAttributes;
    }

    return context;
  }

  applyRoleToPrompt(prompt, roleContext, options = {}) {
    const roleIntroduction = this.formatRoleIntroduction(roleContext, options);
    
    // Different placement strategies
    const placement = options.rolePlacement || 'prefix';
    
    switch (placement) {
      case 'prefix':
        return `${roleIntroduction}\n\n${prompt}`;
      case 'suffix':
        return `${prompt}\n\n${roleIntroduction}`;
      case 'wrap':
        return `${roleIntroduction}\n\nTask: ${prompt}\n\nPlease respond according to your role and expertise.`;
      default:
        return `${roleIntroduction}\n\n${prompt}`;
    }
  }

  formatRoleIntroduction(roleContext, options = {}) {
    const style = options.introductionStyle || 'professional';
    
    switch (style) {
      case 'brief':
        return `Role: ${roleContext.name}`;
      
      case 'detailed':
        return `Role: ${roleContext.name}\n` +
               `Persona: ${roleContext.persona}\n` +
               `Key Expertise: ${roleContext.expertise.join(', ')}\n` +
               `Communication Style: ${roleContext.communication}`;
      
      case 'conversational':
        return `Please take on the role of ${roleContext.name.toLowerCase()}. ${roleContext.persona}`;
      
      case 'professional':
      default:
        return `You are acting as a ${roleContext.name}. ${roleContext.persona}`;
    }
  }

  buildExpertiseContext(role) {
    return {
      areas: role.expertise,
      focus: `Focus on ${role.expertise.slice(0, 3).join(', ')} aspects`
    };
  }

  addExpertiseGuidance(prompt, expertiseContext) {
    const guidance = `\n\nExpertise Focus: ${expertiseContext.focus}`;
    return prompt + guidance;
  }

  buildCommunicationGuidance(role, options = {}) {
    const baseStyle = role.communication;
    const targetAudience = options.audience || 'professional';
    
    const styles = {
      'technical and precise': 'Use precise technical language and provide specific details',
      'strategic and comprehensive': 'Think strategically and provide comprehensive analysis',
      'operational and practical': 'Focus on practical implementation and operational considerations',
      'security-focused and thorough': 'Prioritize security considerations and be thorough in risk assessment',
      'business-oriented and clear': 'Use business language and ensure clarity for stakeholders',
      'consultative and strategic': 'Provide strategic recommendations and consultative insights',
      'design-focused and user-centric': 'Consider user experience and design principles',
      'clear and structured': 'Organize information clearly and use structured formatting',
      'supportive and educational': 'Be supportive and focus on learning outcomes',
      'instructional and engaging': 'Make content engaging and easy to follow',
      'analytical and evidence-based': 'Support conclusions with evidence and data',
      'methodical and solution-oriented': 'Use systematic approaches and focus on solutions'
    };

    return styles[baseStyle] || 'Communicate clearly and professionally';
  }

  addCommunicationStyle(prompt, communicationGuidance) {
    return `${prompt}\n\nCommunication Style: ${communicationGuidance}`;
  }

  // Utility methods
  getAvailableRoles() {
    return Object.keys(this.roles).map(key => ({
      key,
      name: this.roles[key].name,
      description: this.roles[key].persona,
      expertise: this.roles[key].expertise
    }));
  }

  getRoleByKeywords(keywords) {
    const keywordArray = Array.isArray(keywords) ? keywords : [keywords];
    
    for (const [roleKey, role] of Object.entries(this.roles)) {
      const hasMatch = keywordArray.some(keyword => 
        role.keywords.some(roleKeyword => 
          roleKeyword.toLowerCase().includes(keyword.toLowerCase())
        )
      );
      
      if (hasMatch) {
        return { key: roleKey, ...role };
      }
    }
    
    return null;
  }
}

module.exports = RoleEnhancer;