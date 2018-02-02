# Kirby-Assignments

## New field types

### pageslist

### assignable


## Requirements

Tested with Kirby 2.4.0 and PHP 7.2.
The [json-rpc plugin](https://github.com/photz/kirby-amazing-jsonrpc) must be installed.

## Setup

### Adding user fields

If you don't have one already, you need to create a `/app/site/blueprints/users/default.yml` which defines at least the following two fields:

```yaml
fields:
  assignments:
    label: Assignments
    type:  pageslist
    readonly: true
  pages_read:
    label: Pages the user read
    type: hidden
    readonly: true
```

### Adding a blueprint for topics

```yaml
title: Topic
pages:
	- infobit
files: true
icon: cubes
fields:
  uuid:
    label: UUID
    type: hidden
    readonly: true
    help: The value in this field is generated automatically and serves to identify a page even when its uri changes.
  assignable:
    label: Assignable
    type: assignable
    readonly: true
```


### Adding a blueprint for Infobits

```yaml
title: Infobit
pages: false
files: true
icon: cube
fields:
  uuid:
    label: UUID
    type: hidden
    readonly: true
    help: The value in this field is generated automatically and serves to identify a page even when its uri changes.
  type:
  	label: Type
  	options:
  		- instruct: Instruct
  		- inform: Inform
  		- inspire: Inspire
  title:
    label: Title
    type:  text
  content:
    label: Content
    type:  textarea
```



