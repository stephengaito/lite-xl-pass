# Lite-XL-Pass Password Generation

The Lite-XL-Pass tool uses the system's [`pwgen`
tool](https://manpages.debian.org/bookworm/pwgen/pwgen.1.en.html).

When using the `Generate password` context menu item, there are two `key:
value` parameters which are passed to the `pwgen` tool. These `key: value`
parameters can be manually added to the pass entry as follows:

1. `pwLength`

    The `pwLength` key:value specifies the length of the new password to
    be generated by the `pwgen` tool. This value should be a positive
    integer.

    The **default** `pwLength` is 22.

2. `pwOtions`

    The `pwOptions` key:value supplies the `pwgen` *options* which will be
    passed to the `pwgen` tool.

    The **default** `pwOptions` is `-s` (which generated "secure"
    passwords).

With the above defaults, the typical `pwgen` call is:

```
pwgen -s 22 1
```

which will generate a random password of length 20 using any alpha-numeric
character (both upper and lower cases) BUT no symbols. To add symbols, add
`-y` to the `pwOptions`.

## Password strength vs length

Wikipedia has a nice section of the relative strengths of "random"
passwords given the chosen character set: [Password strength -
Wikipedia](https://en.wikipedia.org/wiki/Password_strength#Random_passwords)

It has been suggested (by the chatter on the web) that an entropy of 128
bits is "generally" sufficiently difficult to hack.

For a password consisting of alpha-numeric characters (which **includes**
upper and lower characters), this is roughly a length of 22 characters.

## Resources

- [Strength of Passwords](https://pages.nist.gov/800-63-4/sp800-63b/passwords/)
- [NIST Special Publication 800-63-4](https://pages.nist.gov/800-63-4/sp800-63.html)
- [Are Your Passwords in the Green?](https://www.hivesystems.com/blog/are-your-passwords-in-the-green)