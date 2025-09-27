const assert = require('assert');
const PromptEnhancer = require('../src/core/PromptEnhancer');
const TextExpander = require('../src/core/enhancers/TextExpander');
const ContextInjector = require('../src/core/enhancers/ContextInjector');
const RoleEnhancer = require('../src/core/enhancers/RoleEnhancer');
const TemplateEnhancer = require('../src/core/enhancers/TemplateEnhancer');
const AIOptimizer = require('../src/core/enhancers/AIOptimizer');
const ConfigManager = require('../src/core/ConfigManager');

async function runTests() {
  console.log('🧪 Running Prompt Enhancer Tests...\n');

  try {
    // Test 1: Basic PromptEnhancer initialization
    console.log('✅ Test 1: PromptEnhancer initialization');
    const enhancer = new PromptEnhancer();
    assert(enhancer instanceof PromptEnhancer, 'PromptEnhancer should be instantiated');
    assert(Array.isArray(enhancer.enhancers), 'Enhancers should be an array');
    assert(enhancer.enhancers.length > 0, 'Should have enhancers loaded');

    // Test 2: Text Expansion
    console.log('✅ Test 2: Text Expansion');
    const textExpander = new TextExpander();
    const expandResult = await textExpander.enhance('help me', {});
    assert(expandResult.enhanced.length > 7, 'Enhanced text should be longer');
    assert(expandResult.changes.length > 0, 'Should have changes recorded');

    // Test 3: Context Injection
    console.log('✅ Test 3: Context Injection');
    const contextInjector = new ContextInjector();
    const contextResult = await contextInjector.enhance('code review this', { forceContext: true });
    assert(contextResult.enhanced.includes('context') || contextResult.enhanced !== 'code review this', 
           'Should inject context');

    // Test 4: Role Enhancement
    console.log('✅ Test 4: Role Enhancement');
    const roleEnhancer = new RoleEnhancer();
    const roleResult = await roleEnhancer.enhance('debug this issue', { role: 'developer' });
    assert(roleResult.enhanced.includes('developer') || roleResult.enhanced.includes('software'), 
           'Should apply role enhancement');

    // Test 5: Template Enhancement
    console.log('✅ Test 5: Template Enhancement');
    const templateEnhancer = new TemplateEnhancer();
    const templateResult = await templateEnhancer.enhance('debug this problem', {});
    assert(templateResult.enhanced.length > 'debug this problem'.length, 
           'Template should expand the prompt');

    // Test 6: AI Optimization
    console.log('✅ Test 6: AI Optimization');
    const aiOptimizer = new AIOptimizer();
    const optimizeResult = await aiOptimizer.enhance('help me fix this', {});
    assert(optimizeResult.enhanced !== 'help me fix this', 'Should optimize vague language');
    assert(optimizeResult.changes.length > 0, 'Should have optimization changes');

    // Test 7: Full Enhancement Pipeline
    console.log('✅ Test 7: Full Enhancement Pipeline');
    const fullResult = await enhancer.enhance('help me');
    assert(fullResult.original === 'help me', 'Should preserve original');
    assert(fullResult.enhanced.length > 7, 'Should enhance the prompt');
    assert(fullResult.metadata, 'Should include metadata');
    assert(Array.isArray(fullResult.metadata.enhancementsApplied), 'Should track enhancements');

    // Test 8: Configuration Management
    console.log('✅ Test 8: Configuration Management');
    const configManager = new ConfigManager();
    const defaultConfig = configManager.getDefaultConfig();
    assert(typeof defaultConfig === 'object', 'Should return config object');
    assert(typeof defaultConfig.enableTextExpansion === 'boolean', 'Should have boolean settings');

    // Test 9: Enhancement with Custom Options
    console.log('✅ Test 9: Custom Enhancement Options');
    const customResult = await enhancer.enhance('create a function', {
      role: 'developer',
      template: 'codeReview',
      context: 'backend'
    });
    assert(customResult.enhanced.length > 'create a function'.length, 'Should apply custom enhancements');

    // Test 10: Analysis Function
    console.log('✅ Test 10: Prompt Analysis');
    const analyzer = new AIOptimizer();
    const analysis = analyzer.analyzePrompt('help me fix this broken code please');
    assert(typeof analysis === 'object', 'Should return analysis object');
    assert(typeof analysis.clarityScore === 'number', 'Should have clarity score');
    assert(Array.isArray(analysis.hasAntiPatterns), 'Should identify anti-patterns');

    console.log('\n🎉 All tests passed successfully!');
    console.log('\n📊 Test Summary:');
    console.log('- PromptEnhancer initialization: ✅');
    console.log('- Text Expansion: ✅');
    console.log('- Context Injection: ✅');
    console.log('- Role Enhancement: ✅');
    console.log('- Template Enhancement: ✅');
    console.log('- AI Optimization: ✅');
    console.log('- Full Enhancement Pipeline: ✅');
    console.log('- Configuration Management: ✅');
    console.log('- Custom Enhancement Options: ✅');
    console.log('- Prompt Analysis: ✅');

    return true;

  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
    console.error('Stack trace:', error.stack);
    process.exit(1);
  }
}

// Performance test
async function performanceTest() {
  console.log('\n⚡ Running Performance Tests...');
  
  const enhancer = new PromptEnhancer();
  const testPrompts = [
    'help',
    'create a function',
    'analyze this data',
    'debug the error',
    'design a system architecture'
  ];

  const startTime = Date.now();
  
  for (const prompt of testPrompts) {
    await enhancer.enhance(prompt);
  }
  
  const endTime = Date.now();
  const avgTime = (endTime - startTime) / testPrompts.length;
  
  console.log(`✅ Performance Test Complete`);
  console.log(`- Total time: ${endTime - startTime}ms`);
  console.log(`- Average time per prompt: ${avgTime.toFixed(2)}ms`);
  console.log(`- Processed ${testPrompts.length} prompts`);
  
  if (avgTime < 100) {
    console.log('🚀 Performance: Excellent');
  } else if (avgTime < 500) {
    console.log('👍 Performance: Good');
  } else {
    console.log('⚠️ Performance: Could be improved');
  }
}

// Integration test
async function integrationTest() {
  console.log('\n🔗 Running Integration Tests...');
  
  const enhancer = new PromptEnhancer();
  
  // Test with all enhancements disabled
  const disabledResult = await enhancer.enhance('test prompt', {
    skipTextExpansion: true,
    skipContextInjection: true,
    skipRoleEnhancement: true,
    skipTemplateEnhancement: true,
    skipAIOptimization: true
  });
  
  assert(disabledResult.enhanced === 'test prompt', 'Should skip all enhancements when disabled');
  
  // Test with selective enhancements
  const selectiveResult = await enhancer.enhance('debug issue', {
    skipTextExpansion: true,
    role: 'troubleshooter'
  });
  
  assert(selectiveResult.metadata.enhancementsApplied.some(e => e.type.includes('Role')), 
         'Should apply only enabled enhancements');
  
  console.log('✅ Integration tests passed');
}

// Run all tests
async function main() {
  await runTests();
  await performanceTest();
  await integrationTest();
  
  console.log('\n🏁 All test suites completed successfully!');
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = {
  runTests,
  performanceTest,
  integrationTest
};