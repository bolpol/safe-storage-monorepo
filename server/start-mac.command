#!/bin/bash
here="`dirname \"$0\"`"
cd $here
open -a "Google Chrome" http://localhost:3000
yarn start