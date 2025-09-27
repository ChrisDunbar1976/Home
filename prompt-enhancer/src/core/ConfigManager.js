const fs = require('fs-extra');
const path = require('path');
const os = require('os');

class ConfigManager {
  constructor() {
    this.configDir = path.join(os.homedir(), '.prompt-enhancer');
    this.configFile = path.join(this.configDir, 'config.json');
    this.defaultConfig = {
      // Enhancement settings
      enableTextExpansion: true,
      enableContextInjection: true,
      enableRoleBasedEnhancement: true,
      enableTemplateBasedEnhancement: true,
      enableAIOptimization: true,
      
      // Default preferences
      defaultRole: null,
      defaultTemplate: null,
      defaultContext: null,
      defaultOutputFormat: 'text',
      
      // Performance settings
      optimizeTokens: true,
      maxTokens: 4000,
      
      // Interface settings
      verboseOutput: false,
      colorOutput: true,
      autoSave: false,
      autoSaveDir: path.join(os.homedir(), '.prompt-enhancer', 'saved-prompts'),
      
      // Template settings
      customTemplatesDir: path.join(os.homedir(), '.prompt-enhancer', 'templates'),
      
      // Role settings
      customRolesDir: path.join(os.homedir(), '.prompt-enhancer', 'roles'),
      
      // Context settings
      includeEnvironmentalContext: true,
      includeTemporal: false,
      
      // AI optimization settings
      clarityThreshold: 70,
      enableAntiPatternFixes: true,
      enableLLMTechniques: true,
      
      // Output settings
      outputFormats: {
        text: { enabled: true },
        json: { enabled: true },
        markdown: { enabled: true }
      },
      
      // Logging
      logLevel: 'info',
      logFile: path.join(os.homedir(), '.prompt-enhancer', 'logs', 'app.log'),
      
      // Advanced settings
      experimental: {
        enabled: false,
        features: []
      }
    };
  }

  async initializeConfig() {
    try {
      // Ensure config directory exists
      await fs.ensureDir(this.configDir);
      await fs.ensureDir(path.dirname(this.defaultConfig.logFile));
      await fs.ensureDir(this.defaultConfig.autoSaveDir);
      await fs.ensureDir(this.defaultConfig.customTemplatesDir);
      await fs.ensureDir(this.defaultConfig.customRolesDir);

      // Create config file if it doesn't exist
      if (!(await fs.pathExists(this.configFile))) {
        await this.saveConfig(this.defaultConfig);
        console.log(`Configuration initialized at: ${this.configFile}`);
      } else {
        // Merge existing config with new default settings
        const existingConfig = await this.loadConfig();
        const mergedConfig = this.mergeConfigs(this.defaultConfig, existingConfig);
        await this.saveConfig(mergedConfig);
        console.log('Configuration updated with new settings');
      }

      return true;
    } catch (error) {
      throw new Error(`Failed to initialize configuration: ${error.message}`);
    }
  }

  async getConfig(configPath = null) {
    try {
      if (configPath) {
        // Load specific config file
        if (!(await fs.pathExists(configPath))) {
          throw new Error(`Configuration file not found: ${configPath}`);
        }
        return await fs.readJSON(configPath);
      }

      // Load default config
      if (!(await fs.pathExists(this.configFile))) {
        await this.initializeConfig();
      }

      return await this.loadConfig();
    } catch (error) {
      console.warn(`Failed to load configuration: ${error.message}`);
      console.warn('Using default configuration');
      return this.defaultConfig;
    }
  }

  async loadConfig() {
    try {
      const config = await fs.readJSON(this.configFile);
      return this.mergeConfigs(this.defaultConfig, config);
    } catch (error) {
      throw new Error(`Failed to load configuration: ${error.message}`);
    }
  }

  async saveConfig(config) {
    try {
      await fs.ensureDir(path.dirname(this.configFile));
      await fs.writeJSON(this.configFile, config, { spaces: 2 });
    } catch (error) {
      throw new Error(`Failed to save configuration: ${error.message}`);
    }
  }

  async setConfig(key, value) {
    try {
      const config = await this.getConfig();
      
      // Handle nested keys (e.g., 'experimental.enabled')
      const keys = key.split('.');
      let current = config;
      
      for (let i = 0; i < keys.length - 1; i++) {
        if (!current[keys[i]]) {
          current[keys[i]] = {};
        }
        current = current[keys[i]];
      }
      
      // Convert string values to appropriate types
      const lastKey = keys[keys.length - 1];
      current[lastKey] = this.parseValue(value);
      
      await this.saveConfig(config);
      return config;
    } catch (error) {
      throw new Error(`Failed to set configuration: ${error.message}`);
    }
  }

  async getConfigValue(key) {
    try {
      const config = await this.getConfig();
      const keys = key.split('.');
      let value = config;
      
      for (const k of keys) {
        if (value[k] === undefined) {
          throw new Error(`Configuration key '${key}' not found`);
        }
        value = value[k];
      }
      
      return value;
    } catch (error) {
      throw new Error(`Failed to get configuration value: ${error.message}`);
    }
  }

  async resetConfig() {
    try {
      await this.saveConfig(this.defaultConfig);
      return this.defaultConfig;
    } catch (error) {
      throw new Error(`Failed to reset configuration: ${error.message}`);
    }
  }

  async backupConfig() {
    try {
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const backupFile = path.join(this.configDir, `config.backup.${timestamp}.json`);
      
      if (await fs.pathExists(this.configFile)) {
        await fs.copy(this.configFile, backupFile);
        return backupFile;
      }
      
      throw new Error('No configuration file to backup');
    } catch (error) {
      throw new Error(`Failed to backup configuration: ${error.message}`);
    }
  }

  async restoreConfig(backupFile) {
    try {
      if (!(await fs.pathExists(backupFile))) {
        throw new Error(`Backup file not found: ${backupFile}`);
      }
      
      // Validate backup file
      const backupConfig = await fs.readJSON(backupFile);
      const mergedConfig = this.mergeConfigs(this.defaultConfig, backupConfig);
      
      await this.saveConfig(mergedConfig);
      return mergedConfig;
    } catch (error) {
      throw new Error(`Failed to restore configuration: ${error.message}`);
    }
  }

  async listBackups() {
    try {
      const files = await fs.readdir(this.configDir);
      const backupFiles = files
        .filter(file => file.startsWith('config.backup.') && file.endsWith('.json'))
        .map(file => ({
          file,
          path: path.join(this.configDir, file),
          timestamp: file.replace('config.backup.', '').replace('.json', '')
        }))
        .sort((a, b) => b.timestamp.localeCompare(a.timestamp));
      
      return backupFiles;
    } catch (error) {
      throw new Error(`Failed to list backups: ${error.message}`);
    }
  }

  async validateConfig(config = null) {
    try {
      const configToValidate = config || await this.getConfig();
      const errors = [];
      
      // Validate required fields
      const requiredFields = [
        'enableTextExpansion',
        'enableContextInjection',
        'enableRoleBasedEnhancement',
        'enableTemplateBasedEnhancement',
        'enableAIOptimization'
      ];
      
      for (const field of requiredFields) {
        if (typeof configToValidate[field] !== 'boolean') {
          errors.push(`${field} must be a boolean value`);
        }
      }
      
      // Validate paths
      const pathFields = [
        'autoSaveDir',
        'customTemplatesDir',
        'customRolesDir'
      ];
      
      for (const field of pathFields) {
        if (configToValidate[field] && typeof configToValidate[field] !== 'string') {
          errors.push(`${field} must be a valid path string`);
        }
      }
      
      // Validate numeric values
      if (configToValidate.maxTokens && 
          (typeof configToValidate.maxTokens !== 'number' || configToValidate.maxTokens < 100)) {
        errors.push('maxTokens must be a number >= 100');
      }
      
      if (configToValidate.clarityThreshold && 
          (typeof configToValidate.clarityThreshold !== 'number' || 
           configToValidate.clarityThreshold < 0 || 
           configToValidate.clarityThreshold > 100)) {
        errors.push('clarityThreshold must be a number between 0 and 100');
      }
      
      // Validate output formats
      if (configToValidate.defaultOutputFormat && 
          !['text', 'json', 'markdown'].includes(configToValidate.defaultOutputFormat)) {
        errors.push('defaultOutputFormat must be one of: text, json, markdown');
      }
      
      return {
        valid: errors.length === 0,
        errors
      };
    } catch (error) {
      return {
        valid: false,
        errors: [`Configuration validation failed: ${error.message}`]
      };
    }
  }

  async migrateConfig() {
    try {
      const config = await this.loadConfig();
      const currentVersion = config.version || '1.0.0';
      const targetVersion = this.defaultConfig.version || '1.0.0';
      
      if (currentVersion === targetVersion) {
        return { migrated: false, message: 'Configuration is up to date' };
      }
      
      // Perform migration logic here
      const migratedConfig = this.mergeConfigs(this.defaultConfig, config);
      migratedConfig.version = targetVersion;
      
      await this.saveConfig(migratedConfig);
      
      return {
        migrated: true,
        message: `Configuration migrated from ${currentVersion} to ${targetVersion}`
      };
    } catch (error) {
      throw new Error(`Configuration migration failed: ${error.message}`);
    }
  }

  // Utility methods

  mergeConfigs(defaultConfig, userConfig) {
    const merged = { ...defaultConfig };
    
    for (const [key, value] of Object.entries(userConfig)) {
      if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
        merged[key] = this.mergeConfigs(merged[key] || {}, value);
      } else {
        merged[key] = value;
      }
    }
    
    return merged;
  }

  parseValue(value) {
    // Convert string representations to appropriate types
    if (typeof value !== 'string') {
      return value;
    }
    
    // Boolean values
    if (value.toLowerCase() === 'true') return true;
    if (value.toLowerCase() === 'false') return false;
    
    // Numeric values
    if (!isNaN(value) && !isNaN(parseFloat(value))) {
      return parseFloat(value);
    }
    
    // JSON values
    if (value.startsWith('{') || value.startsWith('[')) {
      try {
        return JSON.parse(value);
      } catch {
        // Return as string if JSON parsing fails
      }
    }
    
    return value;
  }

  getConfigPath() {
    return this.configFile;
  }

  getConfigDir() {
    return this.configDir;
  }

  getDefaultConfig() {
    return { ...this.defaultConfig };
  }

  // Environment-specific configuration
  async getEnvironmentConfig() {
    const env = process.env.NODE_ENV || 'development';
    const envConfigFile = path.join(this.configDir, `config.${env}.json`);
    
    if (await fs.pathExists(envConfigFile)) {
      try {
        const envConfig = await fs.readJSON(envConfigFile);
        const baseConfig = await this.getConfig();
        return this.mergeConfigs(baseConfig, envConfig);
      } catch (error) {
        console.warn(`Failed to load environment config: ${error.message}`);
      }
    }
    
    return await this.getConfig();
  }

  async setEnvironmentConfig(env, config) {
    const envConfigFile = path.join(this.configDir, `config.${env}.json`);
    await fs.writeJSON(envConfigFile, config, { spaces: 2 });
    return envConfigFile;
  }

  // Profile management
  async createProfile(profileName, config) {
    const profileFile = path.join(this.configDir, 'profiles', `${profileName}.json`);
    await fs.ensureDir(path.dirname(profileFile));
    await fs.writeJSON(profileFile, config, { spaces: 2 });
    return profileFile;
  }

  async loadProfile(profileName) {
    const profileFile = path.join(this.configDir, 'profiles', `${profileName}.json`);
    
    if (!(await fs.pathExists(profileFile))) {
      throw new Error(`Profile '${profileName}' not found`);
    }
    
    const profileConfig = await fs.readJSON(profileFile);
    const baseConfig = this.defaultConfig;
    return this.mergeConfigs(baseConfig, profileConfig);
  }

  async listProfiles() {
    const profilesDir = path.join(this.configDir, 'profiles');
    
    if (!(await fs.pathExists(profilesDir))) {
      return [];
    }
    
    const files = await fs.readdir(profilesDir);
    return files
      .filter(file => file.endsWith('.json'))
      .map(file => file.replace('.json', ''));
  }

  async deleteProfile(profileName) {
    const profileFile = path.join(this.configDir, 'profiles', `${profileName}.json`);
    
    if (await fs.pathExists(profileFile)) {
      await fs.remove(profileFile);
      return true;
    }
    
    return false;
  }
}

module.exports = ConfigManager;