#!/usr/bin/env node

const { Command } = require('commander');
const chalk = require('chalk');
const inquirer = require('inquirer');
const fs = require('fs-extra');
const path = require('path');

const PromptEnhancer = require('../core/PromptEnhancer');
const ConfigManager = require('../core/ConfigManager');

class CLI {
  constructor() {
    this.program = new Command();
    this.configManager = new ConfigManager();
    this.enhancer = null;
    
    this.setupCommands();
  }

  setupCommands() {
    this.program
      .name('prompt-enhancer')
      .description('A comprehensive prompt enhancement tool for better AI interactions')
      .version('1.0.0');

    // Main enhancement command
    this.program
      .command('enhance')
      .description('Enhance a prompt with all available enhancement techniques')
      .option('-p, --prompt <prompt>', 'The prompt to enhance')
      .option('-f, --file <file>', 'Read prompt from file')
      .option('-o, --output <file>', 'Save enhanced prompt to file')
      .option('-i, --interactive', 'Use interactive mode')
      .option('-c, --config <config>', 'Use specific configuration file')
      .option('--role <role>', 'Apply specific role enhancement')
      .option('--template <template>', 'Apply specific template')
      .option('--context <context>', 'Add specific context type')
      .option('--no-expansion', 'Skip text expansion')
      .option('--no-context-injection', 'Skip context injection')
      .option('--no-role-enhancement', 'Skip role-based enhancement')
      .option('--no-template-enhancement', 'Skip template-based enhancement')
      .option('--no-ai-optimization', 'Skip AI optimization')
      .option('--format <format>', 'Output format (text, json, markdown)')
      .option('--verbose', 'Show detailed enhancement information')
      .action(this.handleEnhance.bind(this));

    // Interactive mode command
    this.program
      .command('interactive')
      .alias('i')
      .description('Launch interactive prompt enhancement session')
      .action(this.handleInteractive.bind(this));

    // Analysis command
    this.program
      .command('analyze')
      .description('Analyze a prompt and suggest improvements')
      .option('-p, --prompt <prompt>', 'The prompt to analyze')
      .option('-f, --file <file>', 'Read prompt from file')
      .action(this.handleAnalyze.bind(this));

    // Template management commands
    const templateCmd = this.program
      .command('template')
      .description('Manage prompt templates');

    templateCmd
      .command('list')
      .description('List available templates')
      .action(this.handleTemplateList.bind(this));

    templateCmd
      .command('show <name>')
      .description('Show template details')
      .action(this.handleTemplateShow.bind(this));

    templateCmd
      .command('preview <name>')
      .description('Preview template with sample prompt')
      .option('-p, --prompt <prompt>', 'Sample prompt for preview')
      .action(this.handleTemplatePreview.bind(this));

    // Role management commands
    const roleCmd = this.program
      .command('role')
      .description('Manage enhancement roles');

    roleCmd
      .command('list')
      .description('List available roles')
      .action(this.handleRoleList.bind(this));

    roleCmd
      .command('show <role>')
      .description('Show role details')
      .action(this.handleRoleShow.bind(this));

    // Configuration commands
    const configCmd = this.program
      .command('config')
      .description('Manage configuration');

    configCmd
      .command('init')
      .description('Initialize configuration file')
      .action(this.handleConfigInit.bind(this));

    configCmd
      .command('show')
      .description('Show current configuration')
      .action(this.handleConfigShow.bind(this));

    configCmd
      .command('set <key> <value>')
      .description('Set configuration value')
      .action(this.handleConfigSet.bind(this));

    configCmd
      .command('get <key>')
      .description('Get configuration value')
      .action(this.handleConfigGet.bind(this));

    // Batch processing command
    this.program
      .command('batch')
      .description('Process multiple prompts from a file')
      .option('-f, --file <file>', 'Input file with prompts (JSON or text)')
      .option('-o, --output <file>', 'Output file for enhanced prompts')
      .option('-c, --config <config>', 'Configuration file')
      .action(this.handleBatch.bind(this));

    // Export command
    this.program
      .command('export')
      .description('Export enhancement results')
      .option('-f, --format <format>', 'Export format (json, csv, markdown)')
      .option('-o, --output <file>', 'Output file')
      .action(this.handleExport.bind(this));
  }

  async initializeEnhancer(options = {}) {
    const config = await this.configManager.getConfig(options.config);
    this.enhancer = new PromptEnhancer(config);
    return this.enhancer;
  }

  async handleEnhance(options) {
    try {
      await this.initializeEnhancer(options);

      let prompt = '';
      
      // Get prompt from various sources
      if (options.prompt) {
        prompt = options.prompt;
      } else if (options.file) {
        prompt = await this.readPromptFromFile(options.file);
      } else if (options.interactive) {
        prompt = await this.getPromptInteractively();
      } else {
        console.error(chalk.red('Error: Please provide a prompt using -p, -f, or -i options'));
        process.exit(1);
      }

      // Prepare enhancement options
      const enhanceOptions = this.buildEnhancementOptions(options);

      // Enhance the prompt
      console.log(chalk.blue('Enhancing prompt...'));
      const result = await this.enhancer.enhance(prompt, enhanceOptions);

      // Output results
      await this.outputResults(result, options);

    } catch (error) {
      console.error(chalk.red(`Enhancement failed: ${error.message}`));
      process.exit(1);
    }
  }

  async handleInteractive() {
    console.log(chalk.green('🚀 Welcome to Interactive Prompt Enhancer!'));
    console.log(chalk.gray('Enter your prompts and see them enhanced in real-time.\n'));

    await this.initializeEnhancer();

    while (true) {
      const { action } = await inquirer.prompt([
        {
          type: 'list',
          name: 'action',
          message: 'What would you like to do?',
          choices: [
            'Enhance a prompt',
            'Analyze a prompt',
            'Configure settings',
            'View templates',
            'View roles',
            'Exit'
          ]
        }
      ]);

      switch (action) {
        case 'Enhance a prompt':
          await this.interactiveEnhance();
          break;
        case 'Analyze a prompt':
          await this.interactiveAnalyze();
          break;
        case 'Configure settings':
          await this.interactiveConfigure();
          break;
        case 'View templates':
          await this.interactiveViewTemplates();
          break;
        case 'View roles':
          await this.interactiveViewRoles();
          break;
        case 'Exit':
          console.log(chalk.green('Thanks for using Prompt Enhancer! 👋'));
          process.exit(0);
      }

      console.log(); // Add spacing
    }
  }

  async interactiveEnhance() {
    const { prompt } = await inquirer.prompt([
      {
        type: 'editor',
        name: 'prompt',
        message: 'Enter your prompt (this will open your default editor):'
      }
    ]);

    if (!prompt.trim()) {
      console.log(chalk.yellow('No prompt entered.'));
      return;
    }

    const { enhancementOptions } = await inquirer.prompt([
      {
        type: 'checkbox',
        name: 'enhancementOptions',
        message: 'Select enhancement options:',
        choices: [
          { name: 'Text Expansion', value: 'expansion', checked: true },
          { name: 'Context Injection', value: 'context', checked: true },
          { name: 'Role Enhancement', value: 'role', checked: true },
          { name: 'Template Enhancement', value: 'template', checked: true },
          { name: 'AI Optimization', value: 'ai', checked: true }
        ]
      }
    ]);

    const options = {
      skipTextExpansion: !enhancementOptions.includes('expansion'),
      skipContextInjection: !enhancementOptions.includes('context'),
      skipRoleEnhancement: !enhancementOptions.includes('role'),
      skipTemplateEnhancement: !enhancementOptions.includes('template'),
      skipAIOptimization: !enhancementOptions.includes('ai')
    };

    try {
      console.log(chalk.blue('\nEnhancing prompt...'));
      const result = await this.enhancer.enhance(prompt, options);
      this.displayEnhancementResults(result);
    } catch (error) {
      console.error(chalk.red(`Enhancement failed: ${error.message}`));
    }
  }

  async handleAnalyze(options) {
    try {
      await this.initializeEnhancer();

      let prompt = '';
      if (options.prompt) {
        prompt = options.prompt;
      } else if (options.file) {
        prompt = await this.readPromptFromFile(options.file);
      } else {
        console.error(chalk.red('Error: Please provide a prompt using -p or -f options'));
        process.exit(1);
      }

      const analysis = this.enhancer.enhancers
        .find(E => E.name === 'AIOptimizer')
        ?.prototype.analyzePrompt(prompt);

      if (analysis) {
        this.displayAnalysis(prompt, analysis);
      } else {
        console.log(chalk.yellow('Analysis not available'));
      }

    } catch (error) {
      console.error(chalk.red(`Analysis failed: ${error.message}`));
      process.exit(1);
    }
  }

  async handleTemplateList() {
    await this.initializeEnhancer();
    const TemplateEnhancer = require('../core/enhancers/TemplateEnhancer');
    const templateEnhancer = new TemplateEnhancer();
    const templates = templateEnhancer.getAvailableTemplates();

    console.log(chalk.green('\nAvailable Templates:'));
    console.log(chalk.gray('===================\n'));

    templates.forEach(template => {
      console.log(chalk.cyan(`${template.key}:`));
      console.log(`  Name: ${template.name}`);
      console.log(`  Trigger: ${template.trigger}`);
      console.log('');
    });
  }

  async handleTemplateShow(name) {
    await this.initializeEnhancer();
    const TemplateEnhancer = require('../core/enhancers/TemplateEnhancer');
    const templateEnhancer = new TemplateEnhancer();
    const template = templateEnhancer.getTemplateByKey(name);

    if (!template) {
      console.error(chalk.red(`Template '${name}' not found`));
      process.exit(1);
    }

    console.log(chalk.green(`\nTemplate: ${template.name}`));
    console.log(chalk.gray('='.repeat(template.name.length + 10)));
    console.log(`\nTrigger Pattern: ${template.trigger}`);
    console.log(`\nTemplate Content:`);
    console.log(chalk.gray(template.template));
  }

  async handleTemplatePreview(name, options) {
    await this.initializeEnhancer();
    const TemplateEnhancer = require('../core/enhancers/TemplateEnhancer');
    const templateEnhancer = new TemplateEnhancer();
    
    const samplePrompt = options.prompt || 'Help me with this task';
    
    try {
      const preview = templateEnhancer.previewTemplate(name, samplePrompt);
      console.log(chalk.green(`\nTemplate Preview: ${name}`));
      console.log(chalk.gray('='.repeat(name.length + 18)));
      console.log(preview);
    } catch (error) {
      console.error(chalk.red(`Preview failed: ${error.message}`));
      process.exit(1);
    }
  }

  async handleRoleList() {
    await this.initializeEnhancer();
    const RoleEnhancer = require('../core/enhancers/RoleEnhancer');
    const roleEnhancer = new RoleEnhancer();
    const roles = roleEnhancer.getAvailableRoles();

    console.log(chalk.green('\nAvailable Roles:'));
    console.log(chalk.gray('================\n'));

    roles.forEach(role => {
      console.log(chalk.cyan(`${role.key}:`));
      console.log(`  Name: ${role.name}`);
      console.log(`  Description: ${role.description}`);
      console.log(`  Expertise: ${role.expertise.join(', ')}`);
      console.log('');
    });
  }

  async handleRoleShow(roleName) {
    await this.initializeEnhancer();
    const RoleEnhancer = require('../core/enhancers/RoleEnhancer');
    const roleEnhancer = new RoleEnhancer();
    const roles = roleEnhancer.getAvailableRoles();
    const role = roles.find(r => r.key === roleName);

    if (!role) {
      console.error(chalk.red(`Role '${roleName}' not found`));
      process.exit(1);
    }

    console.log(chalk.green(`\nRole: ${role.name}`));
    console.log(chalk.gray('='.repeat(role.name.length + 6)));
    console.log(`\nDescription: ${role.description}`);
    console.log(`\nExpertise Areas:`);
    role.expertise.forEach(area => {
      console.log(`  • ${area}`);
    });
  }

  async handleConfigInit() {
    try {
      await this.configManager.initializeConfig();
      console.log(chalk.green('Configuration initialized successfully!'));
    } catch (error) {
      console.error(chalk.red(`Configuration initialization failed: ${error.message}`));
      process.exit(1);
    }
  }

  async handleConfigShow() {
    try {
      const config = await this.configManager.getConfig();
      console.log(chalk.green('\nCurrent Configuration:'));
      console.log(chalk.gray('=====================\n'));
      console.log(JSON.stringify(config, null, 2));
    } catch (error) {
      console.error(chalk.red(`Failed to show configuration: ${error.message}`));
      process.exit(1);
    }
  }

  async handleConfigSet(key, value) {
    try {
      await this.configManager.setConfig(key, value);
      console.log(chalk.green(`Configuration updated: ${key} = ${value}`));
    } catch (error) {
      console.error(chalk.red(`Failed to set configuration: ${error.message}`));
      process.exit(1);
    }
  }

  async handleConfigGet(key) {
    try {
      const value = await this.configManager.getConfigValue(key);
      console.log(`${key}: ${value}`);
    } catch (error) {
      console.error(chalk.red(`Failed to get configuration: ${error.message}`));
      process.exit(1);
    }
  }

  async handleBatch(options) {
    // Implementation for batch processing
    console.log(chalk.blue('Batch processing not yet implemented'));
  }

  async handleExport(options) {
    // Implementation for export functionality
    console.log(chalk.blue('Export functionality not yet implemented'));
  }

  // Utility methods

  async readPromptFromFile(filepath) {
    try {
      return await fs.readFile(filepath, 'utf8');
    } catch (error) {
      throw new Error(`Failed to read file ${filepath}: ${error.message}`);
    }
  }

  async getPromptInteractively() {
    const { prompt } = await inquirer.prompt([
      {
        type: 'editor',
        name: 'prompt',
        message: 'Enter your prompt (this will open your default editor):'
      }
    ]);
    return prompt;
  }

  buildEnhancementOptions(options) {
    return {
      skipTextExpansion: options.expansion === false,
      skipContextInjection: options.contextInjection === false,
      skipRoleEnhancement: options.roleEnhancement === false,
      skipTemplateEnhancement: options.templateEnhancement === false,
      skipAIOptimization: options.aiOptimization === false,
      role: options.role,
      template: options.template,
      context: options.context
    };
  }

  async outputResults(result, options) {
    const format = options.format || 'text';

    switch (format.toLowerCase()) {
      case 'json':
        console.log(JSON.stringify(result, null, 2));
        break;
      case 'markdown':
        this.outputMarkdown(result);
        break;
      case 'text':
      default:
        this.displayEnhancementResults(result, options.verbose);
        break;
    }

    // Save to file if requested
    if (options.output) {
      await this.saveToFile(result, options.output, format);
    }
  }

  displayEnhancementResults(result, verbose = false) {
    console.log(chalk.green('\n✨ Enhancement Complete!'));
    console.log(chalk.gray('='.repeat(50)));

    if (verbose) {
      console.log(chalk.cyan('\nOriginal Prompt:'));
      console.log(chalk.gray(result.original));
      console.log(chalk.cyan('\nEnhanced Prompt:'));
    }

    console.log(result.enhanced);

    if (verbose && result.metadata) {
      console.log(chalk.cyan('\nEnhancement Details:'));
      console.log(`Original Length: ${result.metadata.originalLength} characters`);
      console.log(`Enhanced Length: ${result.metadata.finalLength} characters`);
      console.log(`Expansion Ratio: ${result.metadata.expansionRatio?.toFixed(2)}x`);
      console.log(`Processing Time: ${result.metadata.processingTime}ms`);
      
      if (result.metadata.enhancementsApplied.length > 0) {
        console.log(chalk.cyan('\nEnhancements Applied:'));
        result.metadata.enhancementsApplied.forEach(enhancement => {
          console.log(`  • ${enhancement.type}: ${enhancement.description}`);
        });
      }
    }
  }

  displayAnalysis(prompt, analysis) {
    console.log(chalk.green('\n📊 Prompt Analysis'));
    console.log(chalk.gray('='.repeat(50)));
    console.log(`Length: ${analysis.length} characters`);
    console.log(`Estimated Tokens: ${analysis.tokenEstimate}`);
    console.log(`Clarity Score: ${analysis.clarityScore}/100`);

    if (analysis.hasAntiPatterns.length > 0) {
      console.log(chalk.red('\n⚠️  Anti-patterns detected:'));
      analysis.hasAntiPatterns.forEach(pattern => {
        console.log(`  • ${pattern}`);
      });
    }

    if (analysis.suggestedTechniques.length > 0) {
      console.log(chalk.blue('\n💡 Suggested techniques:'));
      analysis.suggestedTechniques.forEach(technique => {
        console.log(`  • ${technique}`);
      });
    }
  }

  outputMarkdown(result) {
    console.log('# Enhanced Prompt\n');
    console.log('## Original');
    console.log('```');
    console.log(result.original);
    console.log('```\n');
    console.log('## Enhanced');
    console.log('```');
    console.log(result.enhanced);
    console.log('```\n');
    
    if (result.metadata?.enhancementsApplied) {
      console.log('## Enhancements Applied');
      result.metadata.enhancementsApplied.forEach(enhancement => {
        console.log(`- **${enhancement.type}**: ${enhancement.description}`);
      });
    }
  }

  async saveToFile(result, filepath, format) {
    try {
      let content;
      switch (format.toLowerCase()) {
        case 'json':
          content = JSON.stringify(result, null, 2);
          break;
        case 'markdown':
          content = this.formatAsMarkdown(result);
          break;
        case 'text':
        default:
          content = result.enhanced;
          break;
      }

      await fs.writeFile(filepath, content, 'utf8');
      console.log(chalk.green(`\nResults saved to: ${filepath}`));
    } catch (error) {
      console.error(chalk.red(`Failed to save file: ${error.message}`));
    }
  }

  formatAsMarkdown(result) {
    let markdown = '# Enhanced Prompt\n\n';
    markdown += '## Original\n```\n' + result.original + '\n```\n\n';
    markdown += '## Enhanced\n```\n' + result.enhanced + '\n```\n\n';
    
    if (result.metadata?.enhancementsApplied) {
      markdown += '## Enhancements Applied\n';
      result.metadata.enhancementsApplied.forEach(enhancement => {
        markdown += `- **${enhancement.type}**: ${enhancement.description}\n`;
      });
    }
    
    return markdown;
  }

  run() {
    this.program.parse();
  }
}

// Create and run CLI if this file is executed directly
if (require.main === module) {
  const cli = new CLI();
  cli.run();
}

module.exports = CLI;