import pulumi
from pulumi_aws import ec2

PROJECT_PREFIX = "ssm-demo"
AZ_1 = "us-east-1a"
AZ_2 = "us-east-1b"

VPC_CIDR = "10.0.0.0/16"
PUBLIC_SUBNET_CIDRS = ["10.0.1.0/24", "10.0.2.0/24"]
PRIVATE_APP_CIDRS = ["10.0.3.0/24", "10.0.4.0/24"]
PRIVATE_DB_CIDRS = ["10.0.5.0/24", "10.0.6.0/24"]
AVAILABILITY_ZONES = [AZ_1, AZ_2]

# VPC
vpc = ec2.Vpc(f"{PROJECT_PREFIX}-vpc",
    cidr_block=VPC_CIDR,
    enable_dns_support=True,
    enable_dns_hostnames=True,
    tags={"Name": f"{PROJECT_PREFIX}-vpc"}
)

# IGW
igw = ec2.InternetGateway(f"{PROJECT_PREFIX}-igw",
    vpc_id=vpc.id,
    tags={"Name": f"{PROJECT_PREFIX}-igw"}
)

# Subnets
public_subnets = []
private_app_subnets = []
private_db_subnets = []

for i in range(2):
    public = ec2.Subnet(f"{PROJECT_PREFIX}-public-subnet-{i+1}",
        vpc_id=vpc.id,
        cidr_block=PUBLIC_SUBNET_CIDRS[i],
        availability_zone=AVAILABILITY_ZONES[i],
        map_public_ip_on_launch=True,
        tags={"Name": f"{PROJECT_PREFIX}-public-subnet-{i+1}"}
    )
    private_app = ec2.Subnet(f"{PROJECT_PREFIX}-private-app-subnet-{i+1}",
        vpc_id=vpc.id,
        cidr_block=PRIVATE_APP_CIDRS[i],
        availability_zone=AVAILABILITY_ZONES[i],
        tags={"Name": f"{PROJECT_PREFIX}-private-app-subnet-{i+1}"}
    )
    private_db = ec2.Subnet(f"{PROJECT_PREFIX}-private-db-subnet-{i+1}",
        vpc_id=vpc.id,
        cidr_block=PRIVATE_DB_CIDRS[i],
        availability_zone=AVAILABILITY_ZONES[i],
        tags={"Name": f"{PROJECT_PREFIX}-private-db-subnet-{i+1}"}
    )

    public_subnets.append(public)
    private_app_subnets.append(private_app)
    private_db_subnets.append(private_db)

# Public Route Table
public_rt = ec2.RouteTable(f"{PROJECT_PREFIX}-public-rt",
    vpc_id=vpc.id,
    routes=[{"cidr_block": "0.0.0.0/0", "gateway_id": igw.id}],
    tags={"Name": f"{PROJECT_PREFIX}-public-rt"}
)

for i, subnet in enumerate(public_subnets):
    ec2.RouteTableAssociation(f"{PROJECT_PREFIX}-public-rt-assoc-{i+1}",
        subnet_id=subnet.id,
        route_table_id=public_rt.id
    )

# NAT Gateway
eip = ec2.Eip(f"{PROJECT_PREFIX}-nat-eip", vpc=True)

nat_gateway = ec2.NatGateway(f"{PROJECT_PREFIX}-nat-gw",
    allocation_id=eip.id,
    subnet_id=public_subnets[0].id,
    tags={"Name": f"{PROJECT_PREFIX}-nat"}
)

# Private Route Table
private_rt = ec2.RouteTable(f"{PROJECT_PREFIX}-private-rt",
    vpc_id=vpc.id,
    routes=[{"cidr_block": "0.0.0.0/0", "nat_gateway_id": nat_gateway.id}],
    tags={"Name": f"{PROJECT_PREFIX}-private-rt"}
)

for i, subnet in enumerate(private_app_subnets + private_db_subnets):
    ec2.RouteTableAssociation(f"{PROJECT_PREFIX}-private-rt-assoc-{i+1}",
        subnet_id=subnet.id,
        route_table_id=private_rt.id
    )

# Export if needed in other files
__all__ = [
    "vpc", "public_subnets", "private_app_subnets", "private_db_subnets"
]
