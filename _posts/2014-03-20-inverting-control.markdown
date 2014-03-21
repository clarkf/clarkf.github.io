---
layout: post
title:  "Inverting Control"
date:   2014-03-20 18:03:50
categories: PHP IoC
---

Dependency Injection, Inversion of Controll, and Separation of Concerns
have been discussed quite a bit lately in the PHP community.  Laravel
seems to have introduced some of the concepts of DI and IoC in a
beginner-friendly way, and a lot of people seem to have questions about
it.  I noticed [a question on /r/php][reddit-ioc] earlier about what
these things do, and why we use them, and I thought a little more
community input might be helpful.

<!-- more -->

Basically, all three things boil down to the last: Separation of
Concerns.  SoC is a pretty big and important concept within object
oriented program, because it promotes clean, reusable classes that are
only [responsible for one thing][single-responsibility]. But, really,
ask yourself: why should my class know (or even care about) where it
gets its dependencies from?

## Word to the wise

DI and IoC aren't necessary! If you want to be a better programmer,
they're useful tools for keeping things decoupled and organized, but for
smaller projects, you simply don't need any of this stuff.

I encourage anyone to learn about and investigate new concepts, but if
you're trying to build a simple webapp (like a blog), don't even worry
about it.

## The abstract

[Inversion of Control][ioc] is a principal that says that a class's
dependencies should be determined at run-time.  [Dependency Injection][di] is
a more specific variety of Inversion of Control that says that the
class's dependencies should be passed into it at runtime, instead of the
class seeking its own dependencies.

In PHP, this has manifested in the use of the use of the [reflection
utilities][php-reflection] built into PHP5+, and inspecting the type
hints in the constructor.  Based on this, a Dependency Injection (or
IoC) container can build new instances of classes, and recursively build
all classes it depends on.

Some containers take it even a step further and allow you to bind
abstract classes or interfaces to concrete implementations.

## An Example

Let's put the web aspect of this aside, and say that we're writing
instructions for a robot that bakes cookies.  We're working on a
controller (of sorts), that handles the procurement of eggs
(`EggProcurementController`).

To procure eggs, the robot needs to know whether we have eggs, and where
they're being stored: The `FoodInventory` class takes care of keeping
track of the quantities and locations, but how will our class get in
touch with the `FoodInventory`?  Dependency Injection! First, let's
start by writing our constructor:

```php
<?php
/**
 * Construct a new EggProcurementController
 *
 * @param Acme\FoodInventory $inventory
 */
public function __construct(\Acme\FoodInventory $inventory)
{
    $this->inventory = $inventory;
}
```

Now, we've made it public that in order for this class to function, it
must have access to a `FoodInventory` instance.

Then, we can tidily perform our business logic:

```php
<?php
/**
 * Procure some amount of eggs
 *
 * @param int $quantity The number of eggs to procure
 *
 * @return Acme\Egg[] An array of eggs
 */
public function procure($quantity = 2)
{
    // Silly pseudo-code follows...
    if (!$this->inventory->has(FoodInventory::EGG, $quantity)) {
        throw new InvalidArgumentException(
            "Unable to locate $quantity eggs!"
        );
    }

    $this->moveTo($this->inventory->locationOf(FoodInventory::EGG));
    $eggs = $this->acquire(FoodInventory::EGG, $quantity);
    $this->moveBack();
    return $eggs;
}
```
_(See the file in its entirety in [this gist][gist-src])_

Alright! So our controller now explicitly depends upon a `FoodInventory`
instance, now we just need to wire those up, instantiating by passing
the instance:

```php
<?php
$inventory = new FoodInventory(/* ... */);
$controller = new EggProcurementController($inventory);
$controller->procure(50);
```

__But wait!__ This is supposed to be about Dependency Injection!  How
does Dependency Injection come into this?  The answer: Magic.

Most DI containers will do this automagically for you!  All you need, is
to inform them that you wish to instantiate an
`EggProcurementController` 

```php
<?php
$controller = $container->make(
  "Acme\CookieRobot\Controllers\EggProcurementController"
);
$controller->procure(50); // voila!
```
_(using Laravel's IoC API, consult your container's documentation for
specifics)_

## What an awful example

Yeah, I know, it was a bad example, but I think it helped show that the
dependency is handled completely outside the relationship. This becomes
very helpful when you've got an application with dozens of moving parts,
and juggling constructors is just too painful.

What makes something like this almost necessary for apps of any scale is
testing.  If you want to test something (like our `EggProcurementController`),
you can easily drop in mocked replacements so you can test one thing at
a time.

[ioc]: http://en.wikipedia.org/wiki/Inversion_of_Control
[di]: http://en.wikipedia.org/wiki/Dependency_Injection
[reddit-ioc]: http://www.reddit.com/r/PHP/comments/20xxnr/full_working_example_of_a_di_container_in_action/
[single-responsibility]: http://en.wikipedia.org/wiki/Single_responsibility_principle
[php-reflection]: http://php.net/reflection
[gist-src]: https://gist.github.com/clarkf/9678425
