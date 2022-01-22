#!/bin/bash

echo  "displays settings of all connected displays"

system_profiler SPDisplaysDataType | awk '/Resolution/{print $2, $3, $4}'




