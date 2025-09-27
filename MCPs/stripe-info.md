# Stripe MCP Server Integration

## Overview
Stripe offers an official MCP server that enables AI agents like Claude to interact with Stripe's payment processing API and knowledge base through natural language commands.

## Key Capabilities
- **Payment Processing**: Create payment intents, manage subscriptions, handle invoicing
- **Customer Management**: Create, update, and retrieve customer data
- **Product Operations**: Manage products, prices, and catalogs
- **Documentation Search**: Access Stripe's extensive documentation and support articles
- **Account Management**: View account details and settings

## Integration Options

### 1. Remote Server (Hosted by Stripe)
- **URL**: `https://mcp.stripe.com`
- Uses OAuth Dynamic Client Registration
- No local setup required
- Automatically managed by Stripe

### 2. Local Server
- **Package**: `@stripe/mcp`
- **Command**: `npx -y @stripe/mcp --tools=all`
- Requires Stripe API key
- More control over configuration

## Claude Code Configuration

Add to your `.claude.json` file:

```json
{
  "mcpServers": {
    "stripe": {
      "command": "npx",
      "args": ["-y", "@stripe/mcp", "--tools=all"],
      "env": {
        "STRIPE_SECRET_KEY": "sk_test_..."
      }
    }
  }
}
```

## Authentication Requirements
- **OAuth**: Consent form for client authorization (remote server)
- **Bearer Token**: Using Stripe API key (local server)
- **Recommended**: Use restricted API keys for enhanced security

## Available Tools
The server provides tools for various Stripe resources:
- Account management
- Customer operations
- Invoicing
- Payments processing
- Subscriptions management
- Product and price management
- Documentation and knowledge base search

## Security Features
- **Restricted API Key Support**: Use keys with limited permissions
- **Human Confirmation**: Enable prompts for destructive operations
- **Prompt Injection Protection**: Built-in safeguards
- **Read-only Default**: Operations are read-only by default (configurable)

## Setup Process
1. **Create Stripe Account**: Sign up at https://stripe.com
2. **Generate API Keys**: Get test/live keys from Stripe Dashboard
3. **Configure Claude Code**: Add MCP server to configuration
4. **Authenticate**: Via OAuth or bearer token
5. **Test Connection**: Verify integration works

## Example Use Cases
- "Create a new customer with email john@example.com and name John Doe"
- "Generate JavaScript code to create a payment intent for $100"
- "Show me all customers from the last 30 days"
- "Create a subscription for customer cus_123 with price price_456"
- "Search documentation for webhook implementation"

## Prerequisites
- Stripe account (free to create)
- Stripe API keys (test keys available immediately)
- Claude Code with MCP support

## Additional Resources
- **Official Documentation**: https://docs.stripe.com/mcp
- **Package Repository**: @stripe/mcp on npm
- **Support Contact**: mcp@stripe.com
- **Stripe Dashboard**: https://dashboard.stripe.com

## Benefits
- **Natural Language Interface**: No need to write API calls manually
- **Comprehensive Access**: Full Stripe API functionality
- **Documentation Integration**: Search and access Stripe docs directly
- **Development Efficiency**: Faster payment integration development
- **Error Handling**: Built-in validation and error messages

## Notes
- Test mode available for development without real transactions
- Webhook endpoints can be configured for event handling
- Multiple environments supported (test/live)
- Rate limiting handled automatically
- Stripe CLI integration possible for local development