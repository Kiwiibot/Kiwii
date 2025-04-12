# Kiwii tags

Tags can be controlled via a templating system, here are all the tags:

#### `{avatar:user}`

Gets the avatar url of the [`user`].

### `{avatarhash:user}`

Gets the avatar hash of the [`user`].

### `{args}`

Returns the args that were passed to this tag as a space joined string.

### `{argsfrom:index}`

Returns the args that were passed to this tag as a space joined string, starting from the specified `index`.

### `{argsindex:string}`

Returns the index of the arg that was passed to this tag.

### `{argsto:index}`

Returns the args that were passed to this tag as a space joined string, ending at the specified `index`.

### `{argsrange:from|to}`

Returns the args that were passed to this tag as a space joined string, starting from `from` and ending at `to`.

### `{arg:index}`

Returns the argument at the specified `index`.

### `{tryarg:index}`

Returns the argument at the specified `index`, if it doesn't exist, returns an empty string.

### `{argscount}/{argslen}/{argslength}`

Returns the amount of args that were passed to this tag.

### `{channels}`

Returns the number of channels the server has.

### `{created:type}`

Returns the creation date of the specified `type`, can be `server`, `guild`, or `server`.

### `{channelid}`

Returns the ID of the channel this tag was invoked in.

### `{channel}`

Returns the name of the channel this tag was invoked in.

### `{choose:arg1|arg2|...argN}`

Chooses a random argument from the ones passed to this tag.

### `{ceil:number}`

Returns the ceiling of the specified `number`.

### `{cos:number}`

Returns the cosine of the specified `number`.

### `{dm}`

Whether or not this tag was invoked in a DM. Useful to combine with [`{if}`](#if).

### `{download:url}`

Fetch the contents of the specified `url` and returns it.

### `{e}`

Returns the constant `e`.

### `{floor:number}`

Returns the floor of the specified `number`.

### `{haspermission/hasperm:permission}`

Whether or not the user that invoked this tag has the specified `permission`. Useful to combine with [`{if}`](#if).

### `{hasrole:role}`

Whether or not the user that invoked this tag has the specified `role`. Useful to combine with [`{if}`](#if).

### `{id/userid:user}`
Returns the ID of the specified [`user`].

### `{if:condition|true|false}`

TO IMPLEMENT

### `{ignore:content}`

Do not parse the specified `content`.

### `{js:code}`

Evaluates the specified `code` as JavaScript.
Only a few variables are available in the scope of the code:
 - `message` - The raw api message object.

### `{length}`

Returns the length of the args that were passed to this tag.

### `{lower:content}`

Returns the specified `content` in lowercase.

### `{replace:search|replace}`

Replaces all instances of `search` with `replace` in the args that were passed to this tag.

### `{replaceregex:search|replace}`

Replaces all instances of `search` with `replace` in the args that were passed to this tag, using regex.

[`user`]: #user

<sup><a id="user" href="">\*</a> - `user` can be a nickname, an ID, or a username, defaults to the user that invoked this tag.</sup>
