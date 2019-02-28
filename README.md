# Example AWS provisioning with Terraform and Ansible
This is excercise to demonstrate kicking off an ansible provisioner from a terraform plan.

Generate ssh keys. Leave the password blank.

```shell
$ cd terraform_ansible_example
$ ssh-keygen -f mykey  
```
Run the terraform plan
```
$ terraform plan
$ terraform apply
```

# TODO
It would be nice to populate an inventory file where groups mapped to the instance tags.

