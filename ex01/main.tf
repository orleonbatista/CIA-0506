module "slackoapp" {
    # module source
    source = "./modules/slacko-app"
    # Amazon VPC ID
    vpc_id = "YOUR_VPC_ID"
    # Amazon subnet ip range
    subnet_cidr = "YOUR_SUBNET_CIDR"
    # SSH Key to access machines
    ssh_key = "YOUR_SSH_KEY"
    # Slackoapp machine name
    app_name = "YOUR_APP_NAME"
    # Resource tags
    app_tags ={
        env = "DEPLOY_ENV"
        project = "PROJECT_NAME"
        customer = "CUSTOMER_NAME"
    }
    # App Instance type
    app_instance = "t2.micro"
    # DB Instance type
    db_instance = "t2.micro"
}

output "slacko-ip" {
    value = module.slackoapp.slacko-app
}