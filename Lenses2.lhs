> {-# LANGUAGE TemplateHaskell, TypeOperators #-}

Now let's see how to do the same thing using the fclabels package:

> module Lenses where

> import Data.Label
> import Prelude hiding ((.), id)
> import Control.Applicative
> import Control.Category

We again have our example user:

> chris :: User
> chris = User "Chris" (Address "Vader Rijndreef" "Utrecht") "test"

Our datatypes look a bit different now, all the fields are prefixed with an
underscore:

> data User = User { _name :: String, _address :: Address, _password :: String }
>  deriving Show
> data Address = Address { _street :: String, _city :: String}
>  deriving Show

And we generate the labels using one line of Template Haskell:

> $(mkLabels [''User, ''Address])

This will generate the following functions:

    name :: User :-> String
    address :: User :-> Address
    password :: User :-> String

    street :: Address :-> String
    city :: Address :-> String

And we can compose them like this:

> userCity :: User :-> String
> userCity = city . address

(Note that the `.` function is not the compose from Prelude, but from
`Data.Category`, which is an abstraction of function composition.

Now we can write the same examples again:

> utrecht :: String
> utrecht = get userCity chris

> chrisInBerlin :: User
> chrisInBerlin = set userCity "Berlin" chris

This is pretty cool, but can we do more? At this point, we can look very deeply
into a data structure by composing the lenses with the `.` operator, but could
we combine them as well?

As you might have guessed, we can. This makes for some interesting programs. For
example, suppose the User datatype is designed to be part of a webservice. When
somebody accesses our API, we want to return a flat data structure, without the
password:

> data FlatUser = FlatUser { flatName :: String, flatStreet :: String, flatCity :: String}
>  deriving Show

We can use Applicative to write a function that converts between `User` and
`FlatUser` values:

> toFlatUser :: User :-> FlatUser
> toFlatUser = Lens $ FlatUser <$> flatName `for` name 
>                              <*> flatStreet `for` (street .  address)
>                              <*> flatCity `for` (city .  address)

For example,

> flatChris :: FlatUser
> flatChris = get toFlatUser chris

Suppose the user now updates this value

> flatChrisInBerlin :: FlatUser
> flatChrisInBerlin = flatChris { flatStreet = "Cantianstrasse", flatCity = "Berlin" }

We can update our original value to reflect the changes in the `FlatUser`:

> chrisInBerlin' :: User
> chrisInBerlin' = set toFlatUser flatChrisInBerlin chris

This is a great way of building your API. Your "Flat" datatype is what you
present publicly, and internally you can refactor and be very flexible about
your datatypes.

I've used this with success for generating code. For example, instead of
generating JSON automatically from the `User` datatype, I first create a Lens to
a type `PublicUser`, and then use generic programming to automatically generate
JSON or XML. When updated JSON or XML comes in, I create another `PublicUser`
value from that and update the original user.
