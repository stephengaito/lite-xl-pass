# Lite-XL Password store

We implement a very simple GUI for [Pass: The Standard Unix Password
Manager](https://www.passwordstore.org/) based upon [Lite
XL](https://lite-xl.com/).

We do this by (minimally) "patching" Lite-XL's source code to re-implement
the basic Lite-XL file editor to "edit" Password-Store entries.

We base the project directories on the user's `.password-store` directory.

Instead of opening the file, we use `pass` to open and/or save an entry.

Eventually we would like to be able to open only parts of a password
entry, as well as implement an TOPT tool.

Finally, we will want to zero as much of the (heap) space as possible when
the tool exits.
