const PromptEnhancer = require('./core/PromptEnhancer');
const ConfigManager = require('./core/ConfigManager');
const CLI = require('./cli/cli');

// Core enhancers
const TextExpander = require('./core/enhancers/TextExpander');
const ContextInjector = require('./core/enhancers/ContextInjector');
const RoleEnhancer = require('./core/enhancers/RoleEnhancer');
const TemplateEnhancer = require('./core/enhancers/TemplateEnhancer');
const AIOptimizer = require('./core/enhancers/AIOptimizer');

module.exports = {
  PromptEnhancer,
  ConfigManager,
  CLI,
  enhancers: {
    TextExpander,
    ContextInjector,
    RoleEnhancer,
    TemplateEnhancer,
    AIOptimizer
  }
};

// If this file is run directly, start the CLI
if (require.main === module) {
  const cli = new CLI();
  cli.run();
}