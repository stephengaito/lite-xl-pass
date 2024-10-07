# Lite-XL-Pass using gpg and pass on the command line

Internally, Lite-XL-Pass uses the system's `gpg` and `pass` commands.

In some cases these two tools can and possibly should be used "by hand" on
the command line.

The Lite-XL-Pass file browser (TreeView on the left hand side) includes
two `Copy path` and `Copy absolute path` context menu commands. These
place the given item's (relative or absolute) path into the XWindow's
"clipboard" (using `xsel`). This copied path can then be used to directly
manipulate the password entry from the command line.

## Using gpg

Normally, the use of the Lite-XL-Pass tool itself is easiest from **most**
password entries. However some "password entries" are simply external
files which have been encrypted directly using `gpg` and so are easiest to
decrypt using `gpg` as well.

To do this copy the absolute path into the clipboard and the type the
following command:

```
gpg -d <copiedAbsolutePath>
```

This will decrypt the file's contents the stdout.

To save the decrypted file somewhere else, type:

```
gpg -d <copiedAbsolutePath> > <newPath>
```

See: [GnuPG - Support](https://www.gnupg.org/documentation/)

## Using pass

To use the `pass` command on the command line, copy the relative path into
the clipboard and then type:

```
pass <aPassCommand> <somePassOptions> <copiedRelativePath>
```

See: [Pass: The Standard Unix Password
Manager](https://www.passwordstore.org/)