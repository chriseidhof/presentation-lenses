> module Lenses where

Often in Haskell, you deal with nested datatypes. As a running example, we will
look at the `User` datatype, which has a nested field `address` of type
`Address`.

> data User = User { name :: String, address :: Address, password :: String }
>  deriving Show
> data Address = Address { street :: String, city :: String}
>  deriving Show

Here is an example `User` value

>
> chris :: User
> chris = User "Chris" (Address "Vader Rijndreef" "Utrecht") "test"

If we want to access the city of a `User`, we can write a function for that,
composing the getters for the record label fields:

> getUserCity :: User -> String
> getUserCity = city . address

And to change the user's city, we can also write a function:

> setUserCity :: User -> String -> User
> setUserCity user newCity = user { address = (address user) { city = newCity } }

However, the setters are not really composable. To look into a data structure,
we need to write these functions each time. Let's try to do better.

First, we can make the setters more composable by wrapping them into their own
functions:

> setCity :: Address -> String -> Address
> setCity oldAddress newCity = oldAddress { city = newCity }

> setAddress :: User -> Address -> User
> setAddress oldUser newAddress = oldUser { address = newAddress }

Now we can write a new version of `setUserCity` using our more composable helper
functions:

> setUserCity' :: User -> String -> User
> setUserCity' user = setAddress user . setCity (address user)

However, this is still not really nice. We need to pass in the `user` in both
`setAddress` and `setCity`.

Now, let's try to wrap the getter and setter in a datatype, and see if we can
compose that:


> data Lens a b = Lens {get :: a -> b, set :: a -> b -> a}
> 
> city_ :: Lens Address String
> city_ = Lens city setCity

> address_ :: Lens User Address
> address_ = Lens address setAddress

Now we would like a way to compose `city_` and `address_`, for example:

> userCity :: Lens User String
> userCity = address_ `compose` city_

> compose :: Lens a b -> Lens b c -> Lens a c
> compose l1 l2 = Lens (get l2 . get l1) (\x y -> set l1 x (set l2 (get l1 x) y))

Now, let's try to see if this works:


> utrecht :: String
> utrecht = get userCity chris

`"Utrecht"`

> chrisInBerlin :: User
> chrisInBerlin = set userCity chris "Berlin"

`User {name = "Chris", address = Address {street = "Vader Rijndreef", city = "Berlin"}}`

This pattern is very useful when you write stateful code. For example, when
writing a game you might have a type State that has nested types which in place
have more nested types.
