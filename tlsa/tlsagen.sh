printf '%s' \
    $(openssl x509 -in example.com.chain -noout -pubkey |
        openssl pkey -pubin -outform DER |
        openssl dgst -sha256 -binary |
        hexdump -ve '/1 "%02x"')
