Target ->

singlecall data, value

Timelock ->

Target.address.call.value.callData

Multisig ->

tx.target = Timelock.address
tx.signature = sig for params
tx.calldata = 0x00000000 (input paremeters)