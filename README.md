# puppet-nfs

This is a puppet module designed to install and configure NFS on a [Vagrant](https://www.vagrantup.com/) virtual machine for the purpose of mounting the client filesystem on the host. See [An Alternative to Vagrant Synced Folders | Brian Fisher](https://brianfisher.name/content/alternative-vagrant-synced-folders).

Works on

-   debian 7.8
-   ubuntu 14.04

## Usage

```puppet
nfs::export { '/home/vagrant':
  clients: ['*(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=1000)'],
}
```

In this example, you can then mount the guest `/home/vagrant` using

```bash
sudo mkdir -p /mnt/example.dev/vagrant
sudo mount -o -P /home/vagrant /mnt/example.dev/vagrant
```
