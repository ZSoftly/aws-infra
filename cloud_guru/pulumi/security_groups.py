from pulumi_aws import ec2
from network import vpc

PROJECT_PREFIX = "ssm-demo"
ALLOWED_SSH_CIDR = "0.0.0.0/0"

# ALB SG
alb_sg = ec2.SecurityGroup(f"{PROJECT_PREFIX}-alb-sg",
    description="Security group for ALB",
    vpc_id=vpc.id,
    ingress=[
        {"protocol": "tcp", "from_port": 80, "to_port": 80, "cidr_blocks": ["0.0.0.0/0"]},
        {"protocol": "tcp", "from_port": 443, "to_port": 443, "cidr_blocks": ["0.0.0.0/0"]},
    ],
    egress=[{"protocol": "-1", "from_port": 0, "to_port": 0, "cidr_blocks": ["0.0.0.0/0"]}],
    tags={"Name": f"{PROJECT_PREFIX}-alb-sg"}
)

# WordPress SG
wp_sg = ec2.SecurityGroup(f"{PROJECT_PREFIX}-wordpress-sg",
    description="Security group for WordPress",
    vpc_id=vpc.id,
    ingress=[
        {"protocol": "tcp", "from_port": 80, "to_port": 80, "security_groups": [alb_sg.id]},
        {"protocol": "tcp", "from_port": 443, "to_port": 443, "security_groups": [alb_sg.id]},
        {"protocol": "tcp", "from_port": 22, "to_port": 22, "cidr_blocks": [ALLOWED_SSH_CIDR]},
    ],
    egress=[{"protocol": "-1", "from_port": 0, "to_port": 0, "cidr_blocks": ["0.0.0.0/0"]}],
    tags={"Name": f"{PROJECT_PREFIX}-wordpress-sg"}
)

# DB SG
db_sg = ec2.SecurityGroup(f"{PROJECT_PREFIX}-db-sg",
    description="Security group for DB",
    vpc_id=vpc.id,
    ingress=[
        {"protocol": "tcp", "from_port": 3306, "to_port": 3306, "security_groups": [wp_sg.id]},
    ],
    egress=[{"protocol": "-1", "from_port": 0, "to_port": 0, "cidr_blocks": ["0.0.0.0/0"]}],
    tags={"Name": f"{PROJECT_PREFIX}-db-sg"}
)

# Redis SG
redis_sg = ec2.SecurityGroup(f"{PROJECT_PREFIX}-redis-sg",
    description="Security group for Redis",
    vpc_id=vpc.id,
    ingress=[
        {"protocol": "tcp", "from_port": 6379, "to_port": 6379, "security_groups": [wp_sg.id]},
    ],
    egress=[{"protocol": "-1", "from_port": 0, "to_port": 0, "cidr_blocks": ["0.0.0.0/0"]}],
    tags={"Name": f"{PROJECT_PREFIX}-redis-sg"}
)

# Export if needed
__all__ = ["alb_sg", "wp_sg", "db_sg", "redis_sg"]
