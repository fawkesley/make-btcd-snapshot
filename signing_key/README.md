# Restore GPG with this key

```
export GNUPGHOME=$(mktemp -d)

gpg --import public.asc
gpg --import secret.asc
```
