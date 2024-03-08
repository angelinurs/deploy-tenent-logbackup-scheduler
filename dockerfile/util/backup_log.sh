#!/bin/sh

# FILE_NAME=$1
# KEY=naru

# # option 1.
# encrypt
# openssl enc -e -aes-256-cbc -pbkdf2 -a -k $KEY $FILE_NAME -out ./$FILE_NAME.enc
echo "openssl enc -e -aes-256-cbc -pbkdf2 -a -k $KEY -in $FILE_NAME -out $FILE_NAME.enc"
openssl enc -e -aes-256-cbc -pbkdf2 -a -k $KEY -in $FILE_NAME -out $FILE_NAME.enc

# compress
gzip $FILE_NAME.enc

rm -f $FILE_NAME.enc

# # option 2.
# # decompress
# gzip -d ./$FILE_NAME.enc.gz

# # decrypt
# openssl enc -d -aes-256-cbc -pbkdf2 -a -k $KEY -in ./$FILE_NAME.enc -out ./$FILE_NAME
