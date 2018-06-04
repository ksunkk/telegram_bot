#!/usr/bin/env ruby
require 'bundler'
require 'daemons'
Daemons.run('/var/www/telegram-bot/current/telegram_bot')
