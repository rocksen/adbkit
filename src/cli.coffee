fs = require 'fs'

program = require 'commander'
Promise = require 'bluebird'
forge = require 'node-forge'

pkg = require '../package'
Adb = require './adb'
Auth = require './adb/auth'

Promise.longStackTraces()

program
  .version pkg.version

program
  .command 'pubkey-convert <file>'
  .option '-f, --format <format>', 'format (pem or openssh)', String, 'pem'
  .description 'Converts an ADB-generated public key into PEM format.'
  .action (file, options) ->
    Auth.parsePublicKey fs.readFileSync file
      .then (key) ->
        switch options.format.toLowerCase()
          when 'pem'
            console.log forge.pki.publicKeyToPem(key).trim()
          when 'openssh'
            console.log forge.ssh.publicKeyToOpenSSH(key, 'adbkey').trim()
          else
            console.error "Unsupported format '#{options.format}'"
            process.exit 1

program
  .command 'pubkey-fingerprint <file>'
  .description 'Outputs the fingerprint of an ADB-generated public key.'
  .action (file) ->
    Auth.parsePublicKey fs.readFileSync file
      .then (key) ->
        console.log '%s %s', key.fingerprint, key.comment

program
  .command 'usb-device-to-tcp <serial>'
  .option '-p, --port <port>', 'port number', String, 6174
  .description 'Provides an USB device over TCP using a translating proxy.'
  .action (serial, options) ->
    adb = Adb.createClient()
    server = adb.createTcpUsbBridge(serial, auth: -> Promise.resolve())
      .on 'listening', ->
        console.info 'Connect with `adb connect localhost:%d`', options.port
    server.listen options.port

program.parse process.argv
