# autoraid-instance-store
Create a RAID0 array of AWS instance-store volumes

## Usage

```sudo raid_ephemeral.sh start``` will attempt to query any [AWS Instance Metadata](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html) available and determine if any instance store volumes exist. If any are round, the volumes will be automatically unmounted, and added to a RAID0 array mounted at /mnt.


Modelled after https://gist.github.com/joemiller/6049831
