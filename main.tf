# The IaaS provider.
provider "aws" {
    region = "us-east-1"
}

# Get all the availability zones available to this aws account
data "aws_availability_zones" "all" {}

# Create a variable that defines the port for the http server
variable "server_port" {
  description = "HTTP Server Port"
  default = 80
}

# SSH private key path
variable "PATH_TO_PRIVATE_KEY" {
  default = "mykey"
}

# SSH public key path
variable "PATH_TO_PUBLIC_KEY" {
  default = "mykey.pub"
}

# SSH Username
variable "INSTANCE_USERNAME" {
  default = "ubuntu"
}

# Create a variable that defines the port for the http server
variable "ssh_port" {
  description = "SSH Port"
  default = 22
}

# The SSH key pair resource
resource "aws_key_pair" "mykey" {
  key_name = "mykey"
  public_key = "${file("${var.PATH_TO_PUBLIC_KEY}")}"
}

# Create a security group and allow public access to the http port and ssh
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  # Web access from anywhere
  ingress {
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  # SSH from anywhere
  ingress {
    from_port = "${var.ssh_port}"
    to_port = "${var.ssh_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  # Allow all outbound traffic  
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance to act as our webserver
resource "aws_instance" "example" {
  ami = "ami-2d39803a"
  instance_type = "t2.micro"
  # the security group
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]
  key_name = "${aws_key_pair.mykey.key_name}"
  tags {
    Name = "terraform-example"
  }

  provisioner "file" {
    source = "wait_for_instance.sh"
    destination = "/tmp/wait_for_instance.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/wait_for_instance.sh",
      "sudo /tmp/wait_for_instance.sh"
    ]
  }

  # This is where we configure the instance with ansible-playbook
  provisioner "local-exec" {
      command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --private-key mykey -u '${var.INSTANCE_USERNAME}' -i '${aws_instance.example.public_ip},' site.yml"
  }

  # Use the private key we defined, don't use ssh-agent
  connection {
    user = "${var.INSTANCE_USERNAME}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
    agent = "false"
  }

}
