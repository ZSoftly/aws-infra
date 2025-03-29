# AWS Network Scripts Sequence Diagram

```mermaid
sequenceDiagram
    participant U as User
    participant C as Create Script
    participant AWS as AWS Services
    participant F as Resource File
    participant D as Delete Script

    Note over U,AWS: Creation Flow
    U->>C: Execute create-network.sh
    
    C->>AWS: Check AWS CLI & Config
    
    C->>AWS: Create/Check VPC
    AWS-->>C: VPC ID
    
    C->>AWS: Create/Check Internet Gateway
    AWS-->>C: IGW ID
    C->>AWS: Attach IGW to VPC
    
    par Create Subnets
        C->>AWS: Create Public Subnets
        AWS-->>C: Public Subnet IDs
        C->>AWS: Enable Auto-assign Public IP
        and
        C->>AWS: Create Private App Subnets
        AWS-->>C: Private App Subnet IDs
        and
        C->>AWS: Create Private DB Subnets
        AWS-->>C: Private DB Subnet IDs
    end
    
    C->>AWS: Create NAT Gateway (in Public Subnet)
    AWS-->>C: NAT Gateway ID
    C->>AWS: Wait for NAT Gateway Available
    
    par Create Route Tables
        C->>AWS: Create Public Route Table
        AWS-->>C: Public RT ID
        C->>AWS: Add IGW Route
        C->>AWS: Associate Public Subnets
        and
        C->>AWS: Create Private Route Table
        AWS-->>C: Private RT ID
        C->>AWS: Add NAT Gateway Route
        C->>AWS: Associate Private Subnets
    end
    
    par Create Security Groups
        C->>AWS: Create ALB SG
        AWS-->>C: ALB SG ID
        and
        C->>AWS: Create WordPress SG
        AWS-->>C: WP SG ID
        and
        C->>AWS: Create DB SG
        AWS-->>C: DB SG ID
        and
        C->>AWS: Create Redis SG
        AWS-->>C: Redis SG ID
    end
    
    C->>F: Save Resource IDs
    
    Note over U,AWS: Deletion Flow
    U->>D: Execute delete-network.sh
    D->>F: Load Resource IDs
    
    D->>AWS: Delete Security Groups (in order)
    Note right of D: Redis → DB → WP → ALB
    
    D->>AWS: Delete NAT Gateway
    D->>AWS: Wait for NAT Gateway Deletion
    D->>AWS: Release Elastic IP
    
    D->>AWS: Delete Route Tables
    Note right of D: First disassociate all subnets
    
    D->>AWS: Delete Subnets
    Note right of D: Private DB → Private App → Public
    
    D->>AWS: Detach Internet Gateway
    D->>AWS: Delete Internet Gateway
    
    D->>AWS: Delete VPC
    
    D->>F: Clear Resource File

```
### The diagram shows:

1. **Creation Flow**:
   - Proper order of resource creation
   - Parallel operations where possible
   - Dependencies between resources
   - Resource ID collection and storage

2. **Deletion Flow**:
   - Reverse order of deletion
   - Dependency-aware cleanup
   - Resource file handling

Key aspects highlighted:
- Parallelizable operations (subnet creation, security groups)
- Wait conditions (NAT Gateway)
- Resource dependencies (IGW → VPC, NAT → Public Subnet)
- File operations (saving/loading IDs)
- Proper deletion order to handle dependencies