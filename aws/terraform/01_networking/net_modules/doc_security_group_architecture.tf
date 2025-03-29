/*
SECURITY GROUP ARCHITECTURE RECOMMENDATION

BEST PRACTICE: SEPARATE SECURITY GROUP CREATION FROM RULE DEFINITION

Current approach:
- Security groups and their rules are defined in the networking module
- Rules are hardcoded for specific applications (application, ALB, DB, Redis)

Recommended approach:
- Networking module should create empty security groups or with minimal default rules
- Application-specific rules should be defined in application modules

BENEFITS OF SEPARATION:

1. Separation of Concerns
   - Networking module focuses on network infrastructure
   - Application modules define their specific security requirements
   - Better adherence to infrastructure-as-code best practices

2. Improved Flexibility
   - Application teams can modify their security rules without changing network code
   - Easier to implement custom rules for specific environments
   - Can implement stricter rules in production vs development

3. Principle of Least Privilege
   - Each application only opens ports it actually needs
   - Easier to audit and enforce security policies
   - Reduces attack surface by default

4. Scalability for Multi-Team Environments
   - Different teams can manage their application security independently
   - Reduces bottlenecks in infrastructure changes
   - Supports infrastructure changes without coordination across teams

IMPLEMENTATION APPROACH:

1. In Networking Module:
   - Create security groups with minimal default rules
   - Export security group IDs as outputs
   - Possibly keep ALB and basic network rules here

2. In Application Modules:
   - Import security group IDs from network module
   - Define application-specific ingress/egress rules
   - Use aws_security_group_rule resources to add rules to existing groups

3. Common Rules Module (Optional):
   - Create a separate module for common security patterns
   - Reuse across applications for consistency

EXAMPLE STRUCTURE:

networking/
  ├── outputs: sg_application_id, sg_database_id
  └── main: create empty security groups with basic egress

application/
  ├── inputs: sg_application_id, sg_alb_id
  └── main: add port 80, 443 from ALB, port 22 for SSH

database/
  ├── inputs: sg_database_id, sg_application_id
  └── main: add port 3306 from application SG

This approach balances centralized management with application-specific customization.
*/
