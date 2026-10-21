#!/usr/bin/env bash
# Make a watch key and its hash. Put KEY on the watch, HASH in WRIST_KEY_HASH.
node -e "const c=require('crypto');const k='wa_'+c.randomBytes(24).toString('base64url');console.log('KEY  '+k);console.log('HASH '+c.createHash('sha256').update(k).digest('hex'))"
