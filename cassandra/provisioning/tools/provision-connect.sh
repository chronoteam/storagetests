#!/usr/bin/env bash

ssh -A -o "StrictHostKeyChecking no" ubuntu@$(cat tmp/provision-ip)
