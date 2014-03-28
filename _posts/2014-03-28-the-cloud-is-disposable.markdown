---
layout: post
title:  "The Cloud is Disposable"
date:   2014-03-28 10:59:50
---

The most important lesson I've learned about cloud-based infrastructure
is that virtual machines are intended to be disposable.  I've seen
scenarios where people will try to build a single virtual machine and
run it as long as they can.  But why?

<!-- more -->

Even the best virtualization software sometimes has issues.  What do you
do when your precious VM dies?  You kill it, and replace it with
another. But what about all of the user-data that's been stored on the
image?  Well, you're probably doing it wrong.

<br />
<div class='alert alert-warning'>
  <strong>Forgive me,</strong> but this is going to get relatively AWS-centric
  from here on out.  Most of the concepts here should be applicable other cloud
  hosts, but not guaranteed.  YMMV.
</div>
<br />


I like to treat the attached instance store as ephemeral storage (yes,
I've blatantly taken that term from Heroku).  Anything that is written
to the rootfs must be disposable.  This is fine for things like cache
files, temporary image files, etc, but not great for stuff you want to
persist.

<img src="/images/aws-instance.png" alt="Conceptual Diagram" style="max-width: 100%" />

*Keep your instances small, and good at one thing.*


I'm going to assume that you're not running your database on the same
instance.  It's great if you have a low-traffic site, but it makes this
whole process a chore.  AWS [offers managed relational databases][rds]
that isn't too shabby.  It allows you to make your database available in
multiple regions, and offers automated backups and restoration. It does
not, however, offer some of the more avant-garde data storage options.

For persisted file storage, you have a few routes within AWS: <abbr
title="Simple Storage Service">S3</abbr> or <abbr title="Elastic Block
Store">EBS</abbr>. S3 is pretty neat, since it's become
[dirt cheap][s3-price-reduction], and pushes some of the load off of your
server and onto AWS (NB: [S3 is *not* a CDN][s3-not-cdn]). It does require some
application-level logic though, which may or may not be part of the project
roadmap.  With EBS, you can provision a virtual drive of sorts, and mount
it on a running instance.  If you need to swap out an instance for a new one,
it's as simple as taking your EBS volume with you.

### A Practical Guide to Disposing Instances

So you've got a killer app, and you want to deploy it to AWS.  Awesome.
Grab your free-tier eligible account, and spin up an EC2 instance. The
class of the instance isn't super important, since this particular
instance won't see the light of day.

First, install all of your dependencies, then clone your repository onto
the local server (you are using VCS, right? ;)). Ensure that the app is
running and accessible from the outside world. If you're feeling particularly
wild, create some sort of bootstrapping script that pulls in your latest
changes, and launches the server (if applicable), and get it running on boot.

<div class='fig-right'>
  <img src="/images/aws-1.png" />
</div>

Now, create a snapshot of the instance (it's a good idea to opt for a
restart, to ensure total data parity), then convert that snapshot to an
AMI.  Congratulations, you've created an abstract image of your
application! Use and abuse this image as the foundation for anything
that needs to run in the application environment.

<div class='clearfix'></div>

<div class='fig-left'>
  <img src="/images/aws-2.png" />
</div>

Now, it's time to make it live.  Create a new instance based on your
custom AMI, and get it booted.  You've now got a disposable instance of
your application.  You can swap over your Elastic IP and get this
instance live.  As the users start populating your application with data
and files, your data stores will fill up, and not your application
instance.  But what happens if this instance starts acting funny?

<div class='clearfix'></div>
<br />

<div class='fig-right'>
  <img src="/images/aws-3.png" />
</div>

Simply spin up a new instance, and remap your <abbr title="Elastic
IP">EIP</abbr> to the new instance.  You can now poke and prod at the
old instance for diagnostic information about why it's acting funny,
while providing a good experience on the live server.  This same
work-flow can be used for deployment:  When you want to launch a new
version of the app with zero-downtime, just spin up a new instance,
ensure it's running the latest version, and swap the IP.

As time marches on, you'll find that spinning up an instance requires
more things: updating system packages (better keep Apache up to date!),
and vendored dependencies takes time, and adds to the boot time of your
new instance.  Time to create a new AMI! Spin up your base AMI, and
perform all of the boilerplate commands, then generate a new snapshot
and AMI.  You can delete the old ones, but since AWS's storage system
(at least for snapshots) are incremental, it should be negligible.

<div class='clearfix'></div>

### Why all the trouble?

I think this practice is relatively important to the lifecycle of an
application.  Deploying to the live server is a pretty bad idea (unless
you like downtime), and betting the farm on a single instance surviving
for months (or years) is relatively silly. Being agile (not necessarily big-A Agile)
means that you need to respond to demand;  if your site becomes an
overnight success, how easily can you scale?

Keeping things distinct and simple is crucial to cloud infrastructure.
Sure, it may cost more up front, but everything that I've outlined
should fall under the free usage tier (at least to some extent).  AWS
created the free usage tier for this purpose, so use it!

[rds]: https://aws.amazon.com/rds
[s3-price-reduction]: http://aws.typepad.com/aws/2014/03/aws-price-reduction-42-ec2-s3-rds-elasticache-and-elastic-mapreduce.html
[s3-not-cdn]: http://jdorfman.posthaven.com/medium-bitcoin-660x493-dot-jpg-cdn-vs-s3
