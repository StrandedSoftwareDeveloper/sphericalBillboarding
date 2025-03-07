#!/bin/bash

#zig-out/bin/simpleRenderer & zigProgramPID=$!

while true; do
    echo "Waiting for update..."
    inotifywait -e modify zig-out/bin/simpleRenderer
    echo "Time to run the thing!"
    kill $zigProgramPID
    sleep 0.01
    cp zig-out/bin/simpleRenderer zig-out/bin/simpleRenderer2
    zig-out/bin/simpleRenderer2 & zigProgramPID=$!
done