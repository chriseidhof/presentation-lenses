!SLIDE bullets
# Lenses (and fclabels) #

* Chris Eidhof
* Berlin HUG - Oct 25

!SLIDE
# Outline #

* Why do we need lenses? 
* How do we create lenses?
* How to use fclabels (a library for lenses)

!SLIDE execute

    @@@haskell
    :l Lenses

!SLIDE

    data User = User { name :: String, 
                     , address :: Address
                     , password :: String }

    data Address = Address { street :: String
                           , city :: String }

    chris :: User
    chris = User "Chris" 
                 (Address "Vader Rijndreef" 
                          "Utrecht")
                 "test"

!SLIDE execute


## Nested getters

     getUserCity :: User -> String
     getUserCity = city . address

## Example

      @@@haskell
      getUserCity chris

!SLIDE execute

## Nested setters

      setUserCity :: User -> String -> User
      setUserCity user newCity = user { 
        address = (address user) { 
          city = newCity 
        }
      }

## Example

      @@@haskell
      setUserCity chris "Berlin"

!SLIDE

## Problem: the above technique is not composable and tedious

!SLIDE

## First try

     setCity :: Address -> String -> Address
     setCity oldAddress newCity = oldAddress 
       { city = newCity }
     
     setAddress :: User -> Address -> User
     setAddress oldUser newAddress = oldUser 
       { address = newAddress }

## Now `setUserCity` becomes

      setUserCity' :: User -> String -> User
      setUserCity' user = setAddress user 
              . setCity (address user)

!SLIDE

## Still not composable. ##

!SLIDE

## The `Lens` datatype ##

     data Lens a b = Lens 
       { get :: a -> b
       , set :: a -> b -> a}

     city_ :: Lens Address String
     city_ = Lens city setCity
     
     address_ :: Lens User Address
     address_ = Lens address setAddress

!SLIDE execute

## Composing `Lens` ##

     userCity :: Lens User String
     userCity = compose address_ city_

## Example ##

     @@@haskell
     get userCity chris

## Example 2 ##

     @@@haskell
     set userCity chris "Berlin"


!SLIDE

## Composing lenses

    compose :: Lens a b 
            -> Lens b c 
            -> Lens a c
    compose l1 l2 = Lens (get l2 . get l1) 
     (\x -> set l1 x . (set l2 $ get l1 x))

!SLIDE 

## Very useful when writing stateful code, e.g. game state. ##

!SLIDE execute

## First Class Labels (`fclabels`)

    module Lenses where
    
    import Data.Label
    import Prelude hiding ((.), id)
    import Control.Applicative
    import Control.Category

## Code

    @@@haskell
    :l Lenses2

!SLIDE

## Datatypes (with added _)

    data User = User { _name :: String
                     , _address :: Address
                     , _password :: String }

    data Address = Address 
       { _street :: String
       , _city :: String }

!SLIDE
## Template Haskell

    $(mkLabels [''User, ''Address])

## This generates:

    name     :: User :-> String
    address  :: User :-> Address
    password :: User :-> String

    street :: Address :-> String
    city   :: Address :-> String

!SLIDE execute

## Usage

    userCity :: User :-> String
    userCity = city . address

### Note that `(.)` is from `Category`, not `Prelude`

## Example (getting)

    @@@haskell
    get userCity chris

## Example (setting)

    @@@haskell
    set userCity "Berlin" chris

!SLIDE

## This is pretty cool, but can we do better?

!SLIDE

## Yes we can!

* Now we only have "vertical" composition: deeper into a data structure.
* Let's try horizontal composition
 
!SLIDE

## Flattened User data structure

     data FlatUser = FlatUser 
       { flatName :: String
       , flatStreet :: String
       , flatCity :: String }

!SLIDE execute

## Conversion between `User` and `FlatUser`

    toFlatUser :: User :-> FlatUser
    toFlatUser = Lens $ FlatUser 
       <$> flatName `for` name 
       <*> flatStreet `for` (street . address)
       <*> flatCity `for` (city . address)

## Example

    @@@haskell
    get toFlatUser chris


!SLIDE execute

## Updated `FlatUser` value:

    flatChrisInBerlin :: FlatUser
    flatChrisInBerlin = flatChris 
      { flatStreet = "Cantianstrasse"
      , flatCity = "Berlin" }

## Example

    @@@haskell
    set toFlatUser flatChrisInBerlin chris

!SLIDE

## Use this for your APIs: `FlatUser` is the exposed type, internally you can change your representation.

     
!SLIDE bullets


* <a href="http://hackage.haskell.org/package/fclabels">fclabels</a> (hackage)

* <a href="mailto:chris@eidhof.nl">chris@eidhof.nl</a>
* <a href="http://www.twitter.com/chriseidhof">@chriseidhof</a>
* <a href="http://chris.eidhof.nl">chris.eidhof.nl</a> (blog)
