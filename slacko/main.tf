data "aws_ami" "slacko-app" {
    most_recent = true
    owners = ["amazon"]
 
    filter {
        name = "name"
        values = ["Amazon*"]
    }

    filter {
        name = "architecture"
        values = ["x86_64"]
    }

}

data "aws_subnet" "subnet_public" {
   cidr_block = "10.0.102.0/24"
}

# Gerando a chave
# ssh-keygen -C slacko -f slacko
resource "aws_key_pair" "slacko-sshkey" {
    key_name = "slacko-app-key"
    public_key = "ssh-rsa  AAAAB3NzaC1yc2EAAAADAQABAAABgQCycwdt2Kk48/ayzIJxmWC/4Egzk8Rvly+d4RM7y2TQdHF+yUM0MO9VVbDYl19MOeUeOdTF/soPIoggdqoG3gStn8H68L4o8ieUzPNkXZTfRkKHQTKuOSmxqn63W3iAJ7AmNxVdfg1hUevsPgVidfAuXQ5hMjvAHVjDlMMRlyDJdHzMDi+Q44yCMii1vweYVvx5kXQt9Hl/ulLDqZ3SyQ9wP/J4ExqHTU2oqSYBZH33wsm8+Qe9si7Uo9OOE2V/zK9h5zAmlQq1v24P5J4lk5TUqdUK+xc3QYrF0Pel3n8/uJO0W4c3k60LX74GbyGznqtiuudUzogrXcCtj0Zbe3NN5tRLus9kR+Q7XK3ghv0+DX9Q4VgNJZ8kFZmDYtNm/oB16t1ZsRxQ0wPR+8fFD2paQVtpfvK6yYgUemZiAUSLDs7X2ZUA001pDphaRQxsxRKDIKWxtOqvbns5P9AAr/JPO4D8+qWXycPmWEfgRbL5IKtZmzXcXmav4CCbDWq925c= slacko"

}

resource "aws_instance" "slacko-app" {
    ami = data.aws_ami.slacko-app.id
    instance_type = "t2.micro"
    subnet_id = data.aws_subnet.subnet_public.id
    associate_public_ip_address = true

    tags = {
        Name = "slacko-app"
    }

    key_name = aws_key_pair.slacko-sshkey.id

    # arquivo de bootstrap  
    user_data = file("ec2.sh")
}

resource "aws_instance" "mongodb" {
    ami = data.aws_ami.slacko-app.id
    instance_type = "t2.micro"
    subnet_id = data.aws_subnet.subnet_public.id

    tags = {
        Name = "mongodb"

    }
    key_name = aws_key_pair.slacko-sshkey.id
    user_data = file("mongodb.sh")
}

resource "aws_security_group" "allow-slacko" {
    name = "allow_ssh_http"
    description = "Allow ssh and http port"
    vpc_id = "vpc-0a09d0946a8n2032f"

    ingress =[
    {
        description = "Allow SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = []
        self = null
        prefix_list_ids = [] 
        security_groups = []
    },
    {
        description = "Allow Http"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = []
        self = null
        prefix_list_ids = [] 
        security_groups = []
    }
]

    egress = [
    {
        description = "Allow all"
        from_port = 0
        to_port = 0
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = []
        self = null
        prefix_list_ids = [] 
        security_groups = []
    }
]

 tags = {
  Name = "allow_ssh_http"
 }
}

resource "aws_security_group" "allow-mongodb" {
    name = "allow_mongodb"
    description = "Allow MongoDB"
    vpc_id = "vpc-0a09d0946a8n2032f"

    ingress = [
    {
        description = "Allow MongoDB"
        from_port = 27017
        to_port = 27017
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = []
        self = null
        prefix_list_ids = [] 
        security_groups = []
    }
]
    egress = [
    {
        description = "Allow all"
        from_port = 0
        to_port = 0
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = []
        self = null
        prefix_list_ids = [] 
        security_groups = []
    }
]

    tags = {
        Name = "allow_mongodb"
  }
}

resource "aws_network_interface_sg_attachment" "mongodb-sg" {
   security_group_id = aws_security_group.allow-mongodb.id
   network_interface_id = aws_instance.mongodb.primary_network_interface_id
}

resource "aws_network_interface_sg_attachment" "slacko-sg" {
   security_group_id = aws_security_group.allow-slacko.id
   network_interface_id = aws_instance.slacko-app.primary_network_interface_id
}

resource "aws_route53_zone" "slack_zone" {
  name = "cia0506.com.br"
  vpc {
    vpc_id = "vpc-0a09d0946a8n2032f"
  }
}

resource "aws_route53_record" "mongodb" {
    zone_id = aws_route53_zone.slack_zone.id
    name = "mongodb.cia0506.com.br"
    type = "A"
    ttl = "300"
    records = [aws_instance.mongodb.private_ip]
}

