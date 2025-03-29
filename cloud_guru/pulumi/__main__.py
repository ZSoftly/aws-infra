import pulumi
import network
import security_groups

# VPC
pulumi.export("vpc_id", network.vpc.id)

# Public Subnets
for i, subnet in enumerate(network.public_subnets):
    pulumi.export(f"public_subnet_{i+1}_id", subnet.id)

# Private App Subnets
for i, subnet in enumerate(network.private_app_subnets):
    pulumi.export(f"private_app_subnet_{i+1}_id", subnet.id)

# Private DB Subnets
for i, subnet in enumerate(network.private_db_subnets):
    pulumi.export(f"private_db_subnet_{i+1}_id", subnet.id)

# Security Groups
pulumi.export("alb_sg_id", security_groups.alb_sg.id)
pulumi.export("wordpress_sg_id", security_groups.wp_sg.id)
pulumi.export("db_sg_id", security_groups.db_sg.id)
pulumi.export("redis_sg_id", security_groups.redis_sg.id)