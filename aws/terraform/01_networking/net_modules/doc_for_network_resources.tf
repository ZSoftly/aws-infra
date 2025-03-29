/*
RECOMMENDATION FOR AWS NETWORKING RESOURCES: USE FOR_EACH

For AWS networking resources, FOR_EACH is strongly recommended over COUNT for the following reasons:

1. Subnet Stability
   - Networking is the foundation of your infrastructure
   - Changes to subnet ordering with COUNT can cause widespread disruption
   - FOR_EACH allows you to add/remove subnets without affecting others
   - Example: Adding a new subnet type won't require recreating existing subnets

2. Numeric Resource Naming Compatible with FOR_EACH
   - The current implementation uses FOR_EACH with numeric keys:
     for_each = { for idx, cidr in var.public_subnet_cidrs : idx => { ... }}
   - This preserves numeric naming (pub-sn-1, pub-sn-2) while gaining FOR_EACH benefits
   - Best of both worlds: stable identifiers with sequential numbering

3. AWS Networking Best Practices
   - AWS VPC resources have many interdependencies
   - Route tables, security groups, and endpoints all reference subnets
   - Subnet recreation can trigger cascading updates/outages
   - FOR_EACH minimizes risk when modifying network architecture

4. Changing Network Requirements
   - As applications grow, network requirements evolve
   - You might need to add subnets for new services or tiers
   - FOR_EACH makes incrementally updating your network safer

5. Resource Naming and Documentation
   - Your structured naming convention works perfectly with FOR_EACH
   - The current implementation creates clean, consistent resource names
   - Example: "${prefix}-${env}-pub-sn-1-${region}" maintains readability

CONCLUSION:
The current implementation using FOR_EACH with numeric identifiers is ideal for AWS networking 
resources. It combines the stability benefits of FOR_EACH with the clean sequential naming 
that makes resource identification easy in the AWS console.
*/
