output "test_ami" {
   value = data.aws_ami.latest-amazon-linux-image
 }

output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}
