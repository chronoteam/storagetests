#!/usr/bin/env bash

scp -r provision/upload ubuntu@$(cat tmp/provision-ip):/tmp