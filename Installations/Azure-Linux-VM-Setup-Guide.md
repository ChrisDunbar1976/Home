# Azure Linux VM Setup Guide

Created: 2025-09-30
Purpose: Documentation of Azure Linux VM creation process for Docker learning

## VM Configuration Used

### Project Details
- **Subscription**: Azure subscription 1
- **Resource Group**: dev-vm-rg (existing)

### Instance Details
- **Virtual Machine Name**: dev-vm-linux01
- **Region**: [Same as existing resources]
- **Availability Options**: No infrastructure redundancy required
- **Security Type**: Standard
- **Image**: Ubuntu 24.04 LTS - x64 Gen2 (free services eligible)
- **VM Architecture**: x64
- **Run with Azure Spot discount**: No

### Size
- **Selected**: Standard_B2s (2 vCPUs, 4 GiB memory)
- **Reasoning**: Sweet spot for Docker learning - enough resources for multiple containers and builds without excessive cost

### Administrator Account
- **Authentication Type**: SSH public key (recommended)
- **Username**: azureuser (default)

### Inbound Port Rules
- **Selected**: None
- **Reasoning**: More secure, can add ports later when needed for specific applications

### Disks
- **OS Disk Type**: Premium SSD (locally-redundant storage)
- **OS Disk Size**: Default (30GB)
- **Encryption**: Platform-managed key
- **Delete with VM**: Checked

### Networking
- **Virtual Network**: Default/existing
- **Subnet**: Default
- **Public IP**: Create new
- **NIC Network Security Group**: Basic
- **Public Inbound Ports**: None
- **Load Balancing**: None

### Management
- **Identity**: None
- **Auto-shutdown**: Enabled (recommended - set to 10 PM local time to save credits)
- **Backup**: Disabled (not needed for learning)
- **Boot Diagnostics**: Enabled
- **Guest OS Updates**: Enabled

### Monitoring
- **Enable basic metrics**: Enabled (free)
- **Boot diagnostics**: Enabled
- **OS guest diagnostics**: Disabled (saves costs)
- **Managed identity**: None

### Advanced
- **Extensions**: None
- **Custom Data/Cloud-init**: Empty
- **User Data**: Empty
- **Host**: Default
- **VM Generation**: Gen 2
- **Security Type**: Standard

### Tags Applied
```
Cost Centre: Accounting
Environment: Development
Owner: Chris
Project: RhubarbPress
Purpose: Docker-Learning
```

## Decision Rationale

### Why Ubuntu 24.04 LTS
- Latest LTS version (released April 2024)
- 5 years of support (until 2029)
- Excellent Docker compatibility
- Free services eligible for Azure trial

### Why Standard_B2s
- 4GB RAM handles multiple containers well
- 2 vCPUs sufficient for Docker builds
- Burstable performance for CPU spikes
- Cost-effective for learning (~$15-20/month)

### Why Premium SSD
- Better Docker image build performance
- Faster container startup times
- More reliable than Standard HDD
- Worth the small cost premium

### Why No Inbound Ports Initially
- Security best practice
- Can add ports later as needed
- Access via Azure Portal SSH for setup

## Cost Considerations
- **VM Type**: Standard_B2s (~$15-20/month)
- **Storage**: Premium SSD (slight premium over Standard SSD)
- **Auto-shutdown**: Enabled to prevent overnight charges
- **Free Trial**: Should fit comfortably within $200 credit for learning

## Security Configuration
- No inbound ports initially configured (secure by default)
- SSH access via Azure Portal browser SSH
- Premium SSD for better performance and reliability
- Platform-managed encryption enabled
- Basic Network Security Group for simple management

## Connection Options Available
- **Azure Portal SSH**: VM → Connect → SSH (browser-based)
- **Local SSH Client**: `ssh azureuser@[vm-public-ip]` (if ports opened)

## Comparison with Windows VM
- **dev-vm-01**: Windows VM for general development
- **dev-vm-linux01**: Linux VM specifically for Docker learning
- Both in same resource group for easier management
- Consistent tagging strategy applied

## Next Steps (Manual)
1. Connect to VM via preferred SSH method
2. Install Docker Engine on Ubuntu 24.04
3. Configure Docker for user access
4. Test Docker installation
5. Begin Docker learning exercises

## Notes
- VM follows descriptive naming pattern for clarity
- Resource group shared with existing Windows VM
- Tags consistent with existing Azure SQL database
- Configuration optimized for learning within free trial limits