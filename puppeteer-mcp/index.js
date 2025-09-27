#!/usr/bin/env node

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} = require('@modelcontextprotocol/sdk/types.js');
const puppeteer = require('puppeteer');

class PuppeteerMCPServer {
  constructor() {
    this.server = new Server(
      {
        name: 'puppeteer-mcp',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.browser = null;
    this.page = null;
    this.setupToolHandlers();
  }

  setupToolHandlers() {
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'navigate',
            description: 'Navigate to a URL',
            inputSchema: {
              type: 'object',
              properties: {
                url: {
                  type: 'string',
                  description: 'The URL to navigate to',
                },
              },
              required: ['url'],
            },
          },
          {
            name: 'screenshot',
            description: 'Take a screenshot of the current page',
            inputSchema: {
              type: 'object',
              properties: {
                path: {
                  type: 'string',
                  description: 'Path to save the screenshot',
                },
                fullPage: {
                  type: 'boolean',
                  description: 'Whether to take a full page screenshot',
                  default: false,
                },
              },
            },
          },
          {
            name: 'get_content',
            description: 'Get the text content of the current page',
            inputSchema: {
              type: 'object',
              properties: {
                selector: {
                  type: 'string',
                  description: 'CSS selector to get content from (optional)',
                },
              },
            },
          },
          {
            name: 'click',
            description: 'Click on an element',
            inputSchema: {
              type: 'object',
              properties: {
                selector: {
                  type: 'string',
                  description: 'CSS selector of the element to click',
                },
              },
              required: ['selector'],
            },
          },
          {
            name: 'type',
            description: 'Type text into an input field',
            inputSchema: {
              type: 'object',
              properties: {
                selector: {
                  type: 'string',
                  description: 'CSS selector of the input element',
                },
                text: {
                  type: 'string',
                  description: 'Text to type',
                },
              },
              required: ['selector', 'text'],
            },
          },
          {
            name: 'wait_for_selector',
            description: 'Wait for a selector to appear on the page',
            inputSchema: {
              type: 'object',
              properties: {
                selector: {
                  type: 'string',
                  description: 'CSS selector to wait for',
                },
                timeout: {
                  type: 'number',
                  description: 'Timeout in milliseconds',
                  default: 30000,
                },
              },
              required: ['selector'],
            },
          },
          {
            name: 'evaluate',
            description: 'Execute JavaScript in the page context',
            inputSchema: {
              type: 'object',
              properties: {
                script: {
                  type: 'string',
                  description: 'JavaScript code to execute',
                },
              },
              required: ['script'],
            },
          },
          {
            name: 'get_page_info',
            description: 'Get basic information about the current page',
            inputSchema: {
              type: 'object',
              properties: {},
            },
          },
        ],
      };
    });

    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        await this.ensureBrowserAndPage();

        switch (name) {
          case 'navigate':
            await this.page.goto(args.url, { waitUntil: 'networkidle2' });
            return {
              content: [
                {
                  type: 'text',
                  text: `Successfully navigated to ${args.url}`,
                },
              ],
            };

          case 'screenshot':
            const screenshotOptions = {
              fullPage: args.fullPage || false,
            };
            if (args.path) {
              screenshotOptions.path = args.path;
            }
            const screenshot = await this.page.screenshot(screenshotOptions);
            
            if (args.path) {
              return {
                content: [
                  {
                    type: 'text',
                    text: `Screenshot saved to ${args.path}`,
                  },
                ],
              };
            } else {
              return {
                content: [
                  {
                    type: 'image',
                    data: screenshot.toString('base64'),
                    mimeType: 'image/png',
                  },
                ],
              };
            }

          case 'get_content':
            let content;
            if (args.selector) {
              content = await this.page.$eval(args.selector, el => el.textContent);
            } else {
              content = await this.page.content();
            }
            return {
              content: [
                {
                  type: 'text',
                  text: content,
                },
              ],
            };

          case 'click':
            await this.page.click(args.selector);
            return {
              content: [
                {
                  type: 'text',
                  text: `Clicked on element: ${args.selector}`,
                },
              ],
            };

          case 'type':
            await this.page.type(args.selector, args.text);
            return {
              content: [
                {
                  type: 'text',
                  text: `Typed "${args.text}" into element: ${args.selector}`,
                },
              ],
            };

          case 'wait_for_selector':
            await this.page.waitForSelector(args.selector, {
              timeout: args.timeout || 30000,
            });
            return {
              content: [
                {
                  type: 'text',
                  text: `Element ${args.selector} appeared on page`,
                },
              ],
            };

          case 'evaluate':
            const result = await this.page.evaluate(args.script);
            return {
              content: [
                {
                  type: 'text',
                  text: JSON.stringify(result, null, 2),
                },
              ],
            };

          case 'get_page_info':
            const title = await this.page.title();
            const url = this.page.url();
            const viewport = this.page.viewport();
            
            return {
              content: [
                {
                  type: 'text',
                  text: JSON.stringify({
                    title,
                    url,
                    viewport,
                  }, null, 2),
                },
              ],
            };

          default:
            throw new Error(`Unknown tool: ${name}`);
        }
      } catch (error) {
        return {
          content: [
            {
              type: 'text',
              text: `Error: ${error.message}`,
            },
          ],
          isError: true,
        };
      }
    });
  }

  async ensureBrowserAndPage() {
    if (!this.browser) {
      this.browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
      });
    }

    if (!this.page) {
      this.page = await this.browser.newPage();
      await this.page.setViewport({ width: 1280, height: 800 });
    }
  }

  async cleanup() {
    if (this.page) {
      await this.page.close();
      this.page = null;
    }
    if (this.browser) {
      await this.browser.close();
      this.browser = null;
    }
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);

    // Cleanup on exit
    process.on('SIGINT', async () => {
      await this.cleanup();
      process.exit(0);
    });

    process.on('SIGTERM', async () => {
      await this.cleanup();
      process.exit(0);
    });
  }
}

// Start the server
if (require.main === module) {
  const server = new PuppeteerMCPServer();
  server.run().catch(console.error);
}

module.exports = PuppeteerMCPServer;