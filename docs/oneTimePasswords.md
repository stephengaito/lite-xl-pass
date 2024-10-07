# Lite-XL-Pass One Time Passwords

The Lite-XL-Pass tool uses the system's [`oathtool`
tool](https://manpages.debian.org/bookworm/oathtool/oathtool.1.en.html).

We have used the source code of the `pass-otp` as well as the [Key Uri
Format · google/google-authenticator
Wiki](https://github.com/google/google-authenticator/wiki/Key-Uri-Format)
as documentation of the **format** of the password entry's `otpauth`
key:value.

However the Lite-XL-Pass code **only** supplies **TOTP** one time
passwords and **only** uses the otpauth `secret`, `digits`, `period`, and
`algorithm` parameters. That is the above parameters as found in the text
after the `?` in the otpauth uri.
